import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/domain/entities/match_model.dart';
import '../../operate/providers/match_list_provider.dart';
import '../../shared/widgets/infinite_streak_leaderboard.dart';
import 'package:kendo_os/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/domain/entities/score_event.dart';
import '../../shared/widgets/liquid_background.dart';
import '../../operate/providers/settings_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'viewer_home_screen.dart';

class ViewerBunaiksenHomeScreen extends ConsumerWidget {
  final String tournamentId;

  const ViewerBunaiksenHomeScreen({super.key, required this.tournamentId});

  // ★ 究極版：記号化しつつ、区切り文字を「中央揃えのアイコン」で美しく表示するWidgetエンジン
  Widget _buildScoreMarks(MatchModel match, bool isDark, {bool isFinished = true}) {
    final textColor = isFinished ? (isDark ? Colors.grey.shade600 : Colors.grey.shade500) : (isDark ? Colors.white : Colors.black87);
    final iconColor = isFinished ? (isDark ? Colors.grey.shade700 : Colors.grey.shade400) : (isDark ? Colors.grey.shade600 : Colors.grey.shade400);

    if (match.redScore == 0 && match.whiteScore == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Icon(Icons.close, size: 18, color: iconColor),
      );
    }

    final engine = KendoRuleEngine();
    final analysis = engine.analyzeHistory(match.events, match, match.rule);
    
    final rDisplays = analysis.displays[Side.red] ?? [];
    final wDisplays = analysis.displays[Side.white] ?? [];
    
    String rMarksStr = rDisplays.map((d) {
      if (d.mark == 'メ') return d.isFirstMatchPoint ? '㋱' : 'メ';
      if (d.mark == 'コ') return d.isFirstMatchPoint ? '㋙' : 'コ';
      if (d.mark == 'ド') return d.isFirstMatchPoint ? '㋣' : 'ド';
      if (d.mark == 'ツ') return d.isFirstMatchPoint ? '㋡' : 'ツ';
      if (d.mark == '反') return '反';
      if (d.mark == '判定') return '判';
      if (d.mark == '◯') return d.isFirstMatchPoint ? '◎' : '◯';
      return d.mark;
    }).join('');
    
    String wMarksStr = wDisplays.map((d) {
      if (d.mark == 'メ') return d.isFirstMatchPoint ? '㋱' : 'メ';
      if (d.mark == 'コ') return d.isFirstMatchPoint ? '㋙' : 'コ';
      if (d.mark == 'ド') return d.isFirstMatchPoint ? '㋣' : 'ド';
      if (d.mark == 'ツ') return d.isFirstMatchPoint ? '㋡' : 'ツ';
      if (d.mark == '反') return '反';
      if (d.mark == '判定') return '判';
      if (d.mark == '◯') return d.isFirstMatchPoint ? '◎' : '◯';
      return d.mark;
    }).join('');

    final bool isDraw = match.redScore == match.whiteScore;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(rMarksStr, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor, height: 1.1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Icon(isDraw ? Icons.close : Icons.remove, size: 16, color: iconColor),
        ),
        Text(wMarksStr, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor, height: 1.1)),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enableLiquidGlass = ref.watch(settingsProvider).enableLiquidGlass;
    
    // tournamentId から日付をパース (例: bunaiksen_20241010)
    String dateDisplay = '部内戦';
    if (tournamentId.startsWith('bunaiksen_') && tournamentId.length == 18) {
      final dateStr = tournamentId.substring(10);
      if (dateStr.length == 8) {
        dateDisplay = '${dateStr.substring(0,4)}/${dateStr.substring(4,6)}/${dateStr.substring(6,8)}';
      }
    }

    // ★ 修正: リビルドを最小限に抑止するため、select であらかじめフィルタリングする
    // Webバイパスストリーム（matchListProvider）から必要なデータだけを抽出
    final matches = ref.watch(matchListProvider.select((list) => 
        list.where((m) => m.tournamentId == tournamentId).toList()))
      ..sort((a, b) {
        final aFinished = a.status == 'finished' || a.status == 'approved';
        final bFinished = b.status == 'finished' || b.status == 'approved';
        final aInProgress = a.status == 'in_progress';
        final bInProgress = b.status == 'in_progress';
        
        if (aFinished && !bFinished) return 1;
        if (!aFinished && bFinished) return -1;
        
        if (aInProgress && !bInProgress) return -1;
        if (!aInProgress && bInProgress) return 1;
        
        return b.order.compareTo(a.order);
      });

    final hasInfiniteKachinuki = matches.any((m) => m.isKachinuki && m.matchType == '無限勝ち抜き');

    return PopScope(
      canPop: false, // ブラウザのネイティブ戻るを制御するため
      child: LiquidBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            automaticallyImplyLeading: false, // 標準の戻るボタンを消す
            backgroundColor: enableLiquidGlass ? Colors.transparent : (isDark ? const Color(0xFF1C1C1E) : Colors.white),
            foregroundColor: isDark ? Colors.white : const Color(0xFF8B0000),
            title: Text('$dateDisplay の記録 (観戦)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            elevation: 0,
            centerTitle: true,
            leading: GoRouter.of(context).canPop() 
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                    onPressed: () => context.pop(),
                  )
                : null, // ★ QR等直リンクの場合は何も表示しない
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                tooltip: '表示設定',
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const ViewerSettingsBottomSheet(),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.qr_code_2),
                tooltip: '観戦リンクを共有する',
                onPressed: () => _showShareDialog(context, tournamentId, dateDisplay),
              ),
              IconButton(
                icon: const Icon(Icons.leaderboard_outlined),
                // ★ 完全分離した部内戦専用の成績一覧への遷移
                onPressed: () => context.push('/bunaiksen-viewer-record/$tournamentId'),
                tooltip: '成績一覧',
              ),
            ],
          ),
          body: matches.isEmpty 
            ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy, size: 64, color: Colors.grey.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      const Text('この日の記録はありません', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    if (hasInfiniteKachinuki) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Card(
                            color: isDark ? Colors.grey.shade900 : Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.local_fire_department, color: Colors.deepOrange),
                                      const SizedBox(width: 8),
                                      Text('無限勝ち抜き 連勝ランキング', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                                    ],
                                  ),
                                  const Divider(),
                                  const InfiniteStreakLeaderboard(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          color: const Color(0xFF8B0000).withValues(alpha: isDark ? 0.05 : 0.08),
                          width: double.infinity,
                          child: Text('本日の試合一覧', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                        ),
                      ),
                    ],
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final match = matches[index];
                          final hasScore = match.redScore > 0 || match.whiteScore > 0 || match.events.isNotEmpty;
                          final isPlaying = match.status == 'in_progress';
                          final isFinished = (match.status == 'finished' || match.status == 'approved' || hasScore) && !isPlaying;

                          final Color bg = isFinished ? (isDark ? const Color(0xFF161618) : Colors.grey.shade50) : (isDark ? const Color(0xFF1C1C1E) : Colors.white);
                          final Color textC = isFinished ? (isDark ? Colors.grey.shade600 : Colors.grey.shade500) : (isDark ? Colors.white : Colors.black87);
                          final Color noteC = isFinished ? (isDark ? Colors.grey.shade700 : Colors.grey.shade500) : Colors.grey;

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                            child: Card(
                              elevation: 0,
                              margin: EdgeInsets.zero, // ★ Slidable削除による余白調整
                              color: bg,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => context.push('/viewer/${match.id}'), // ★ Viewer用の試合画面へ
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              match.note.isNotEmpty ? match.note : '部内稽古',
                                              style: TextStyle(fontSize: 11, color: noteC, fontWeight: FontWeight.bold),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const Spacer(),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            margin: const EdgeInsets.only(right: 8),
                                            decoration: BoxDecoration(
                                              color: isPlaying ? Colors.blue.shade600 : (isFinished ? (isDark ? Colors.grey.shade800 : Colors.grey.shade300) : (isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade200)),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              isPlaying ? '進行中' : (isFinished ? '終了' : '待機中'),
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: isPlaying ? Colors.white : (isFinished ? (isDark ? Colors.grey.shade400 : Colors.grey.shade600) : (isDark ? Colors.grey.shade400 : Colors.grey.shade700)),
                                              ),
                                            ),
                                          ),
                                          Text(
                                            '第${index + 1}試合',
                                            style: TextStyle(fontSize: 11, color: noteC),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(child: Text(match.redName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textC), textAlign: TextAlign.right, overflow: TextOverflow.ellipsis)),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                            child: isFinished 
                                                ? _buildScoreMarks(match, isDark, isFinished: isFinished) 
                                                : Text('VS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textC)),
                                          ),
                                          Expanded(child: Text(match.whiteName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textC), textAlign: TextAlign.left, overflow: TextOverflow.ellipsis)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: matches.length,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  void _showShareDialog(BuildContext context, String tournamentId, String dateDisplay) {
    final String shareUrl = 'https://kendo-os.web.app/bunaiksen-viewer-home/$tournamentId';
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$dateDisplay 観戦リンク', style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('この部内戦の全試合・スコアを\n観客用に安全に共有できます。', textAlign: TextAlign.center, style: TextStyle(fontSize: 13)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.white,
                child: QrImageView(
                  data: shareUrl,
                  version: QrVersions.auto,
                  size: 200.0,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => SharePlus.instance.share(ShareParams(text: '【剣道OS】部内戦の進行状況をリアルタイムで観戦できます！\n$shareUrl')),
                icon: const Icon(Icons.share),
                label: const Text('LINEやSNSでURLを送る'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey.shade700, foregroundColor: Colors.white, elevation: 0),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('閉じる', style: TextStyle(color: Colors.grey))),
        ],
      ),
    );
  }
}