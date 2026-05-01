import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/match_model.dart';
import '../presentation/provider/match_list_provider.dart';
import '../widgets/infinite_streak_leaderboard.dart';
import '../presentation/provider/bunaiksen_provider.dart';

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

    List<String> redMarks = [];
    List<String> whiteMarks = [];
    bool isFirst = true;

    for (var event in match.events) {
      try {
        String eStr = event.toString().toLowerCase();
        bool isCanceled = eStr.contains('iscanceled: true') || eStr.contains('iscanceled=true');
        if (event is Map && (event as Map)['isCanceled'] == true) {
          isCanceled = true;
        }
        try {
          if ((event as dynamic).isCanceled == true) {
            isCanceled = true;
          }
        } catch (_) {}
        if (isCanceled) {
          continue;
        }

        bool isRed = eStr.contains('red') || eStr.contains('side.red') || eStr.contains('赤');
        String mark = '';
        
        if (eStr.contains('men') || eStr.contains('メ')) {
          mark = 'メ';
        } else if (eStr.contains('kote') || eStr.contains('コ')) {
          mark = 'コ';
        } else if (eStr.contains('do') || eStr.contains('ド')) {
          mark = 'ド';
        } else if (eStr.contains('tsuki') || eStr.contains('ツ')) {
          mark = 'ツ';
        } else if (eStr.contains('hansoku') || eStr.contains('反')) {
          mark = '反';
        }

        if (mark.isNotEmpty) {
          if (isFirst) {
            if (mark == 'メ') {
              mark = '㋱';
            } else if (mark == 'コ') {
              mark = '㋙';
            } else if (mark == 'ド') {
              mark = '㋣';
            } else if (mark == 'ツ') {
              mark = '㋡';
            }
          }
          if (isRed) {
            redMarks.add(mark);
          } else {
            whiteMarks.add(mark);
          }
          isFirst = false;
        }
      } catch (_) {}
    }
    
    while (redMarks.length < match.redScore) {
      redMarks.add(isFirst ? '◎' : '◯');
      isFirst = false;
    }
    while (whiteMarks.length < match.whiteScore) {
      whiteMarks.add(isFirst ? '◎' : '◯');
      isFirst = false;
    }

    if (redMarks.length > match.redScore) {
      redMarks = redMarks.sublist(0, match.redScore);
    }
    if (whiteMarks.length > match.whiteScore) {
      whiteMarks = whiteMarks.sublist(0, match.whiteScore);
    }

    final bool isDraw = match.redScore == match.whiteScore;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center, // ここで完璧な垂直中央揃えを実現
      children: [
        Text(redMarks.join(''), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor, height: 1.1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          // 引き分けなら「✕（close）」、勝敗がついていれば「-（remove）」のアイコンを表示
          child: Icon(isDraw ? Icons.close : Icons.remove, size: 16, color: iconColor),
        ),
        Text(whiteMarks.join(''), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor, height: 1.1)),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
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

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF8B0000),
        // ★ 修正：タイトルはシンプルにテキストのみ表示
        title: Text(isToday ? '今日の部内戦' : '$dateDisplay の記録', style: const TextStyle(fontWeight: FontWeight.bold)),
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
          onPressed: () => context.pop(),
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
                      final inProgress = match.status == 'in_progress';
                      
                      return Opacity(
                        opacity: isFinished ? 0.6 : 1.0,
                        child: Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          elevation: inProgress ? 4 : 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: inProgress ? Colors.deepOrange.shade400 : Colors.transparent, width: inProgress ? 2 : 0)
                          ),
                          color: isFinished ? (isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade200) : (isDark ? Colors.grey.shade900 : Colors.white),
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
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: isDark ? Colors.grey.shade800 : Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                                        child: Text(match.matchType, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700)),
                                      ),
                                      if (inProgress)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF8B0000).withValues(alpha: isDark ? 0.3 : 0.15), // ★ 修正
                                            borderRadius: BorderRadius.circular(4)
                                          ),
                                          child: Text(
                                            '進行中',
                                            style: TextStyle(
                                              fontSize: 10, 
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? Colors.white : const Color(0xFF8B0000), // ★ 修正
                                            ),
                                          ),
                                        )
                                      else if (isFinished)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300, borderRadius: BorderRadius.circular(8)),
                                          child: Text('終了', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(child: Text(match.redName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red), textAlign: TextAlign.right, overflow: TextOverflow.ellipsis)),
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
    );
  }
}