import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ★ 不要になった go_router のインポートを削除
import 'package:intl/intl.dart'; // 時間表示用に追加
import '../../shared/widgets/scoreboard.dart';
// ★ TimerWidgetのインポートを削除
import '../providers/viewer_view_state_provider.dart';
import 'package:kendo_os/application/projections/match_projection.dart'; // ★ Projectionの型とUIXを使うために追加
import '../../shared/widgets/manual_help_button.dart';

class ViewerMatchScreen extends ConsumerWidget {
  final String matchId;
  const ViewerMatchScreen({super.key, required this.matchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ★ Phase 5-3: 最適化。Scaffold全体をリビルドせず、
    // 選手名など「滅多に変わらない静的な枠組み」だけを最初に取得する。
    final viewStateAsync = ref.watch(viewerMatchProjectionProvider(matchId));

    return viewStateAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) => Scaffold(body: Center(child: Text('エラーが発生しました: $e'))),
      data: (MatchProjection? projection) {
        if (projection == null) return const Scaffold(body: Center(child: Text('試合データが見つかりません')));
        
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Scaffold(
          backgroundColor: isDark ? Colors.black : const Color(0xFFF2F2F7), 
          appBar: AppBar(
            title: const Text('試合状況 (観戦)', style: TextStyle(fontSize: 14)),
            actions: const [
              // ★ 観客が最も不安になる「点数が変わらない」等のFAQへ直行
              ManualHelpButton(manualPath: 'docs/manuals/faq/viewer_faq.md', color: Colors.white),
              SizedBox(width: 8),
            ],
          ),
          body: Column(
            children: [
              // 1. ステータスバー（ここだけリビルドするように分割可能だが、今は一括でOK）
              _buildStatusBar(projection),

              // 2. モメンタムゲージ（ここが最も高頻度で更新されるため、Consumerで切り出す）
              Consumer(builder: (context, ref, child) {
                final momentum = ref.watch(viewerMatchMomentumProvider(matchId)).value ?? 0.0;
                return _buildMomentumGauge(momentum, isDark, projection.status);
              }),

              // 3. タイマー（前回の決定に基づき、Viewerからは非表示にすることを推奨）
              // TimerWidget(matchId: matchId, isInputLocked: true),
              
              // 4. スコアボード（ここも内部で select を使って最適化されているはず）
              Expanded(
                flex: 3,
                child: MatchScoreboard(matchId: matchId, myUserId: 'viewer', onNameTap: (side) {}),
              ),

              // 5. タイムライン（履歴が増えた時だけリビルドされるように Consumer で保護）
              Consumer(builder: (context, ref, child) {
                final timeline = ref.watch(viewerMatchTimelineProvider(matchId)).value ?? [];
                return _buildTimelineSection(timeline, isDark);
              }),
            ],
          ),
        );
      },
    );
  }

  // 各パーツをメソッドに切り出し、可読性を高める（ロジックは変えず、配置のみ整理）
  Widget _buildStatusBar(MatchProjection p) {
    return Container(
      width: double.infinity, color: Colors.blueGrey.shade700,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Row(children: [
          Icon(Icons.visibility, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Text('観客席 (Viewer)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ]),
        Text('${p.statusText} | 直前: ${p.lastEventText}',
          style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _buildMomentumGauge(double momentum, bool isDark, String status) {
    if (status != 'in_progress' && momentum == 0.0) return const SizedBox.shrink();
    return Container(
      height: 6, width: double.infinity,
      color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
      child: Row(children: [
        Expanded(flex: (50 + (momentum * 50)).clamp(0, 100).toInt(), child: Container(color: Colors.red.shade600)),
        Expanded(flex: (50 - (momentum * 50)).clamp(0, 100).toInt(), child: Container(color: isDark ? Colors.white : Colors.grey.shade300)),
      ]),
    );
  }

  Widget _buildTimelineSection(List<TimelineEvent> timeline, bool isDark) {
    if (timeline.isEmpty) return const SizedBox.shrink();
    return Expanded(
      flex: 2,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade50,
          border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.black12)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.all(8.0), child: Row(children: [
            Icon(Icons.history, size: 16, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
            const SizedBox(width: 8),
            Text('試合の軌跡', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
          ])),
          Expanded(child: ListView.builder(
            itemCount: timeline.length,
            itemBuilder: (context, index) {
              final event = timeline[timeline.length - 1 - index];
              final isRed = event.side == 'red';
              Color iconColor = isRed ? Colors.red.shade600 : (isDark ? Colors.white : Colors.black54);
              return _buildTimelineItem(event, iconColor, isDark);
            },
          )),
        ]),
      ),
    );
  }

  Widget _buildTimelineItem(TimelineEvent event, Color iconColor, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(children: [
        Text(DateFormat('HH:mm:ss').format(event.timestamp), style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: event.isImportant ? iconColor.withValues(alpha: 0.1) : Colors.transparent, shape: BoxShape.circle),
          child: Icon(event.isImportant ? Icons.star : Icons.circle, size: event.isImportant ? 16 : 8, color: iconColor),
        ),
        const SizedBox(width: 12),
        Text(event.actionName, style: TextStyle(fontSize: 14, fontWeight: event.isImportant ? FontWeight.bold : FontWeight.normal, color: isDark ? Colors.white : Colors.black87)),
      ]),
    );
  }
}