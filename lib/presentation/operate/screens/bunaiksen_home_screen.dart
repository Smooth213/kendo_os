import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kendo_os/domain/entities/match_model.dart';
import '../providers/match_list_provider.dart';
import '../../shared/widgets/infinite_streak_leaderboard.dart';
import '../providers/bunaiksen_provider.dart';
// ★ Phase 8: 削除機能と権限管理用プロバイダを追加
import '../providers/match_command_provider.dart';
import 'package:kendo_os/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/domain/entities/score_event.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../shared/widgets/liquid_background.dart';
import '../providers/settings_provider.dart';

class BunaiksenHomeScreen extends ConsumerWidget {
  const BunaiksenHomeScreen({super.key});

  // ★ 究極版：記号化しつつ、区切り文字を「中央揃えのアイコン」で美しく表示するWidgetエンジン
  Widget _buildScoreMarks(MatchModel match, bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black87;
    // 区切り文字を少しグレーにして、スコア本体(メやコ)と明確に区別する
    final iconColor = isDark ? Colors.grey.shade600 : Colors.grey.shade400;

    // 完全無得点の引き分け
    if (match.redScore == 0 && match.whiteScore == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Icon(Icons.close, size: 18, color: iconColor), // 完璧な中央揃えの「✕」アイコン
      );
    }

    // ★ 修正: KendoRuleEngine を使用し、Undoされたイベントを除外した正確な結果を使用
    final engine = KendoRuleEngine();
    final analysis = engine.analyzeHistory(match.events, match, match.rule);
    
    final rDisplays = analysis.displays[Side.red] ?? [];
    final wDisplays = analysis.displays[Side.white] ?? [];
    
    // 表示用のマークを抽出して、1本目なら丸囲み文字に変換
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
      crossAxisAlignment: CrossAxisAlignment.center, // ここで完璧な垂直中央揃えを実現
      children: [
        Text(rMarksStr, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor, height: 1.1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          // 引き分けなら「✕（close）」、勝敗がついていれば「-（remove）」のアイコンを表示
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
    
    // ★ 修正：今日ではなく「選択された日付」を基準にする
    final viewDate = ref.watch(bunaiksenViewDateProvider);
    final dateId = 'bunaiksen_${DateFormat('yyyyMMdd').format(viewDate)}';
    final dateDisplay = DateFormat('yyyy/MM/dd').format(viewDate);
    final isToday = DateFormat('yyyyMMdd').format(viewDate) == DateFormat('yyyyMMdd').format(DateTime.now());

    // 選択された日の部内戦のみ表示
    final matches = ref.watch(matchListProvider)
        .where((m) => m.tournamentId == dateId)
        .toList()
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

    // 無限勝ち抜きモードの試合が存在するかどうか
    final hasInfiniteKachinuki = matches.any((m) => m.isKachinuki && m.matchType == '無限勝ち抜き');

    return LiquidBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: enableLiquidGlass ? Colors.transparent : (isDark ? const Color(0xFF1C1C1E) : Colors.white),
          foregroundColor: isDark ? Colors.white : const Color(0xFF8B0000),
          // ★ 修正：タイトルはシンプルにテキストのみ表示
        title: Text(isToday ? '今日の部内戦' : '$dateDisplay の記録', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        elevation: 0,
        centerTitle: true,
        actions: [
          // ★ 新設：カレンダーボタン（ここをタップで過去の日付へ）
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: '日付を選択して過去の記録を見る',
            onPressed: () async {
              final allMatchDates = ref.read(matchListProvider)
                  .where((m) => m.tournamentId != null && m.tournamentId!.startsWith('bunaiksen_'))
                  .map((m) => m.tournamentId!.replaceFirst('bunaiksen_', ''))
                  .toSet();

              final picked = await showDatePicker(
                context: context,
                initialDate: viewDate,
                firstDate: DateTime(2024),
                lastDate: DateTime.now(),
                selectableDayPredicate: (DateTime date) {
                  final dStr = DateFormat('yyyyMMdd').format(date);
                  return DateFormat('yyyyMMdd').format(date) == DateFormat('yyyyMMdd').format(DateTime.now()) 
                         || allMatchDates.contains(dStr);
                },
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(primary: const Color(0xFF8B0000), onPrimary: Colors.white, onSurface: isDark ? Colors.white : Colors.black),
                      dialogTheme: DialogThemeData(
                        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                ref.read(bunaiksenViewDateProvider.notifier).state = picked;
              }
            },
          ),
          IconButton(
            // ★ 修正：チェックマークから、成績や順位表を表す「リーダーボード」のアイコンに変更
            icon: const Icon(Icons.leaderboard_outlined),
            onPressed: () => context.push('/bunaiksen-record'),
            tooltip: '成績一覧',
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.go('/'),
        ),
      ),
      body: matches.isEmpty 
        ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 64, color: Colors.grey.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text(isToday ? '今日の試合はまだありません' : 'この日の記録はありません', style: const TextStyle(color: Colors.grey)),
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
                      color: const Color(0xFF8B0000).withValues(alpha: isDark ? 0.05 : 0.08), // ★ 修正
                      width: double.infinity,
                      child: Text('本日の試合一覧', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                    ),
                  ),
                ],
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final match = matches[index];
                      final isFinished = match.status == 'finished' || match.status == 'approved';

                      // ★ 修正：一体化のため、外側のPaddingでリストの余白を管理
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                        child: Slidable(
                          key: ValueKey(match.id),
                          endActionPane: ActionPane(
                            // ★ 修正：選手マスタ画面と完全に同じ滑らかな物理エンジン（ScrollMotion）に統一
                            motion: const ScrollMotion(),
                            children: [
                              SlidableAction(
                                onPressed: (context) => _confirmDeleteMatch(context, ref, match.id),
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                                icon: Icons.delete,
                                label: '削除',
                                // ★ 修正：カードの角丸と完全に一致させる
                                borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
                              ),
                            ],
                          ),
                          child: Card(
                            elevation: 0,
                            margin: EdgeInsets.zero, // ★ 重要：ここをゼロにすることで隙間を消す
                            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => context.push('/match/${match.id}'),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          match.note.isNotEmpty ? match.note : '部内稽古',
                                          style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                                        ),
                                        // 存在しない orderDate を使わず、単に試合番号やテキストにする
                                        Text(
                                          '第${index + 1}試合',
                                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(child: Text(match.redName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87), textAlign: TextAlign.right, overflow: TextOverflow.ellipsis)),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                          child: isFinished 
                                              ? _buildScoreMarks(match, isDark) 
                                              : Text('VS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                                        ),
                                        Expanded(child: Text(match.whiteName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87), textAlign: TextAlign.left, overflow: TextOverflow.ellipsis)),
                                      ],
                                    ),
                                  ],
                                ),
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
      floatingActionButton: isToday ? FloatingActionButton.extended(
        backgroundColor: const Color(0xFF8B0000), // ★ 修正
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          '試合作成',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        onPressed: () => context.push('/bunaiksen-setup'),
        ) : null, // ★ 今日以外を表示している時は作成ボタンを出さない
      ),
    );
  }

  void _confirmDeleteMatch(BuildContext context, WidgetRef ref, String matchId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('試合の削除'),
        content: const Text('この試合データを完全に削除します。この操作は取り消せません。よろしいですか？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(matchCommandProvider).deleteMatch(matchId);
            },
            child: const Text('削除', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}