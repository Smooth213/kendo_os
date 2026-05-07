import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart'; // 時間表示用に追加
import '../../shared/widgets/scoreboard.dart';
import '../../shared/widgets/match_header.dart';
import '../../shared/widgets/timer_widget.dart';
import '../providers/viewer_view_state_provider.dart';
import 'package:kendo_os/application/projections/match_projection.dart'; // ★ Projectionの型とUIXを使うために追加

class ViewerMatchScreen extends ConsumerWidget {
  final String matchId;
  const ViewerMatchScreen({super.key, required this.matchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ★ DDD/CQRS: ドメインモデルではなく、安全な Projection の Stream を監視する
    final viewStateAsync = ref.watch(viewerMatchProjectionProvider(matchId));

    return viewStateAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) => Scaffold(body: Center(child: Text('エラーが発生しました: $e'))),
      data: (MatchProjection? projection) {
        if (projection == null) {
          return const Scaffold(body: Center(child: Text('試合データが見つかりません')));
        }
        
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Scaffold(
          backgroundColor: isDark ? Colors.black : Colors.white, 
          appBar: MatchHeader(
            matchId: matchId,
            isInputLocked: true, 
          ),
          body: Column(
            children: [
              // 閲覧専用バナー ＆ リアルタイムステータス表示
              Container(
                width: double.infinity,
                color: Colors.blueGrey.shade700,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.visibility, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text('観客席 (Viewer)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    Text(
                      '${projection.statusText} | 直前: ${projection.lastEventText}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              // ==========================================
              // ★ Phase 4-Step 4: モメンタム（勢い）ゲージの表示
              // ==========================================
              if (projection.status == 'in_progress' || projection.momentum != 0.0)
                Container(
                  height: 6,
                  width: double.infinity,
                  color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
                  child: Row(
                    children: [
                      // 赤の勢いバー
                      Expanded(
                        flex: (50 + (projection.momentum * 50)).clamp(0, 100).toInt(),
                        child: Container(color: Colors.red.shade600),
                      ),
                      // 白の勢いバー
                      Expanded(
                        flex: (50 - (projection.momentum * 50)).clamp(0, 100).toInt(),
                        child: Container(color: isDark ? Colors.white : Colors.grey.shade300),
                      ),
                    ],
                  ),
                ),

              TimerWidget(matchId: matchId, isInputLocked: true),
              
              if (projection.groupName.isNotEmpty) // 団体戦の場合のみボタンを表示
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        if (projection.isKachinuki) {
                          context.push('/viewer-kachinuki/${projection.groupName}');
                        } else {
                          context.push('/viewer-team/${projection.groupName}');
                        }
                      },
                      icon: Icon(projection.isKachinuki ? Icons.timeline : Icons.table_chart_outlined, size: 16),
                      label: const Text('現在のスコア表', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                        side: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                        minimumSize: const Size(0, 36), 
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
              
              // スコアボード本体
              Expanded(
                flex: 3,
                child: MatchScoreboard(
                  matchId: matchId, 
                  myUserId: 'viewer',
                  onNameTap: (side) {}, 
                ),
              ),

              // ==========================================
              // ★ Phase 4-Step 4: タイムライン（履歴）の表示
              // ==========================================
              if (projection.timeline.isNotEmpty)
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade50,
                      border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.black12)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Icon(Icons.history, size: 16, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                              const SizedBox(width: 8),
                              Text('試合の軌跡', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: projection.timeline.length,
                            itemBuilder: (context, index) {
                              // 最新のイベントを一番上に表示する
                              final event = projection.timeline[projection.timeline.length - 1 - index];
                              final isRed = event.side == 'red';
                              final isWhite = event.side == 'white';
                              
                              Color iconColor = Colors.grey;
                              if (isRed) iconColor = Colors.red.shade600;
                              if (isWhite) iconColor = isDark ? Colors.white : Colors.black54;

                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                child: Row(
                                  children: [
                                    Text(DateFormat('HH:mm:ss').format(event.timestamp), style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                                    const SizedBox(width: 12),
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: event.isImportant ? iconColor.withValues(alpha: 0.1) : Colors.transparent,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        event.isImportant ? Icons.star : Icons.circle,
                                        size: event.isImportant ? 16 : 8,
                                        color: iconColor,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      event.actionName,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: event.isImportant ? FontWeight.bold : FontWeight.normal,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}