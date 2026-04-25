import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart'; 
import '../models/match_model.dart';
import '../models/score_event.dart';
import '../providers/match_list_provider.dart';
import '../services/pdf_service.dart'; 
// ★ 追加：先ほど作成した勝ち抜き戦の最強描画エンジンを呼び出す
import 'kachinuki_scoreboard_screen.dart'; 
import 'home_screen.dart'; // ★ 修正：プロバイダーが確実に存在する home_screen を直接読み込む
// ★ Phase 7: 権限プロバイダのインポート
import '../providers/permission_provider.dart';
import '../domain/kendo_rule_engine.dart';
import '../providers/match_rule_provider.dart';

class OfficialPointDisplay {
  final String mark;
  final bool isFirstMatchPoint;
  OfficialPointDisplay(this.mark, this.isFirstMatchPoint);
}

class OfficialRecordScreen extends ConsumerWidget {
  final String tournamentId; 
  const OfficialRecordScreen({super.key, required this.tournamentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // ★ Phase 7: 権限プロバイダから取得
    final permissions = ref.watch(permissionProvider);
    final String screenTitle = permissions.isReadOnly ? '全試合スコア' : '大会 公式記録';

    final bgColor = isDark ? Colors.black : const Color(0xFFF2F2F7);
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final headerTextColor = isDark ? Colors.white : Colors.indigo.shade900;

    // ★ Step 3-2: selectによる最適化
    final matchesForThisTournament = ref.watch(matchListProvider.select((list) => 
      list.where((m) => m.tournamentId == tournamentId).toList()
    ));
    
    final categoryGroups = <String, Map<String, List<MatchModel>>>{};
    for (var m in matchesForThisTournament) { 
      if (m.groupName == null || m.groupName!.isEmpty) continue;
      final cat = (m.category != null && m.category!.isNotEmpty) ? m.category! : '一般';
      categoryGroups.putIfAbsent(cat, () => {});
      categoryGroups[cat]!.putIfAbsent(m.groupName!, () => []).add(m);
    }

    if (categoryGroups.isEmpty) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          leading: IconButton(icon: Icon(Icons.arrow_back_ios_new, color: headerTextColor, size: 20), onPressed: () => Navigator.pop(context)),
          title: Text(screenTitle, style: TextStyle(fontWeight: FontWeight.bold, color: headerTextColor, fontSize: 16)),
          backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          elevation: 0,
        ),
        body: Center(child: Text('記録データがありません', style: TextStyle(color: isDark ? Colors.white : Colors.black))),
      );
    }

    final categories = categoryGroups.keys.toList();

    return DefaultTabController(
      length: categories.length,
      child: Scaffold(
        backgroundColor: bgColor, 
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: headerTextColor, size: 20), 
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(screenTitle, style: TextStyle(fontWeight: FontWeight.bold, color: headerTextColor, fontSize: 16)),
          backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white, 
          elevation: 0,
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: ElevatedButton.icon(
                onPressed: () => context.go('/'),
                icon: Icon(Icons.home, color: Colors.indigo.shade700, size: 16),
                label: Text('トップへ', style: TextStyle(color: Colors.indigo.shade700, fontWeight: FontWeight.bold, fontSize: 12)),
                style: ElevatedButton.styleFrom(backgroundColor: isDark ? Colors.indigo.shade900.withValues(alpha: 0.5) : Colors.indigo.shade50, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 12)),
              ),
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            labelColor: headerTextColor, 
            unselectedLabelColor: isDark ? Colors.grey.shade600 : Colors.grey.shade500,
            indicatorColor: Colors.indigo.shade600,
            tabs: categories.map((cat) => Tab(text: cat)).toList(),
          ),
        ),
        body: TabBarView(
          children: categories.map((cat) {
            final groupsMap = categoryGroups[cat]!;
            
            final sortedGroupKeys = groupsMap.keys.toList()..sort((a, b) {
              final aLast = _getLastTimestamp(groupsMap[a]!);
              final bLast = _getLastTimestamp(groupsMap[b]!);
              return aLast.compareTo(bLast); 
            });

            return Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: cardColor,
                    border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF38383A) : Colors.grey.shade200)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final groupDataList = sortedGroupKeys.map((key) => {
                              'groupName': key,
                              'matches': groupsMap[key]!..sort((a, b) => a.order.compareTo(b.order)),
                            }).toList();

                            showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

                            try {
                              await PdfService.printOfficialRecord(cat, groupDataList);
                            } catch (e) {
                              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('出力に失敗しました: $e')));
                            } finally {
                              if (context.mounted) Navigator.pop(context);
                            }
                          },
                          icon: const Icon(Icons.print),
                          label: const Text('PDF印刷', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade800, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final groupDataList = sortedGroupKeys.map((key) => {
                              'groupName': key,
                              'matches': groupsMap[key]!..sort((a, b) => a.order.compareTo(b.order)),
                            }).toList();

                            showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

                            try {
                              await PdfService.shareOfficialRecordAsImage(cat, groupDataList);
                            } catch (e) {
                              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('出力に失敗しました: $e')));
                            } finally {
                              if (context.mounted) Navigator.pop(context);
                            }
                          },
                          icon: const Icon(Icons.share),
                          label: const Text('画像シェア', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade600, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true, // ★ 追加
                    physics: const ClampingScrollPhysics(), // ★ 追加
                    padding: const EdgeInsets.all(8),
                    itemCount: sortedGroupKeys.length,
                    itemBuilder: (context, index) {
                      final groupName = sortedGroupKeys[index];
                      final matches = groupsMap[groupName]!..sort((a, b) => a.order.compareTo(b.order));
                      
                      if (matches.isNotEmpty && matches.first.isKachinuki) {
                        // 勝ち抜き戦の描画
                        final firstMatch = matches.first;
                        final note = firstMatch.note;
                        final rTeam = firstMatch.redName.contains(':') ? firstMatch.redName.split(':').first.trim() : firstMatch.redName;
                        final wTeam = firstMatch.whiteName.contains(':') ? firstMatch.whiteName.split(':').first.trim() : firstMatch.whiteName;
                        final titleText = note.isNotEmpty ? '勝ち抜き戦：【$note】 $rTeam vs $wTeam' : '勝ち抜き戦：$rTeam vs $wTeam';

                        int redRem = matches.last.redRemaining.length;
                        int whiteRem = matches.last.whiteRemaining.length;
                        int maxRem = redRem > whiteRem ? redRem : whiteRem;
                        int totalCols = matches.length + maxRem;

                        final canvasWidth = 60.0 + (totalCols * 60.0);
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isDark ? const Color(0xFF38383A) : Colors.grey.shade300)),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                color: isDark ? Colors.indigo.shade900.withValues(alpha: 0.4) : Colors.indigo.shade50,
                                width: double.infinity,
                                child: Text(titleText, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.indigo.shade100 : Colors.indigo.shade900)),
                              ),
                              SizedBox(
                                height: 520,
                                width: double.infinity,
                                child: InteractiveViewer(
                                  constrained: false,
                                  boundaryMargin: const EdgeInsets.all(40), 
                                  minScale: 0.2, maxScale: 3.0,
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    color: isDark ? Colors.black : Colors.white,
                                    width: canvasWidth < 600 ? 600 : canvasWidth,
                                    height: 480,
                                    child: CustomPaint(
                                      painter: KachinukiBracketPainter(matches: matches, isDark: isDark, ref: ref),
                                      size: Size.infinite,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      } else if (matches.isNotEmpty && matches.any((m) => m.note.contains('[リーグ戦]'))) {
                        final ownTeams = ref.watch(customTeamNamesProvider).value ?? [];
                        final String leagueTitle = _generateDescriptiveLeagueTitle(matches, ownTeams);
                        final textColor = isDark ? Colors.white : Colors.indigo.shade900;

                        // 通常の試合と決定戦を分離
                        final normalMatches = matches.where((m) => !m.note.contains('[順位決定戦]')).toList();
                        final tieBouts = matches.where((m) => m.note.contains('[順位決定戦]')).toList();

                        // 対戦カードごとのグルーピング（通常用）
                        final boutsByMatchup = <String, List<MatchModel>>{};
                        final matchupOrder = <String>[];
                        for (var m in normalMatches) {
                          final t1 = m.redName.split(':').first.trim();
                          final t2 = m.whiteName.split(':').first.trim();
                          final matchupName = '$t1 vs $t2';
                          if (!boutsByMatchup.containsKey(matchupName)) {
                            matchupOrder.add(matchupName);
                            boutsByMatchup[matchupName] = [];
                          }
                          boutsByMatchup[matchupName]!.add(m);
                        }

                        // ★ 追加：対戦カードごとのグルーピング（順位決定戦用）
                        final tieBoutsByMatchup = <String, List<MatchModel>>{};
                        final tieMatchupOrder = <String>[];
                        for (var m in tieBouts) {
                          final t1 = m.redName.split(':').first.trim();
                          final t2 = m.whiteName.split(':').first.trim();
                          final matchupName = '$t1 vs $t2';
                          if (!tieBoutsByMatchup.containsKey(matchupName)) {
                            tieMatchupOrder.add(matchupName);
                            tieBoutsByMatchup[matchupName] = [];
                          }
                          tieBoutsByMatchup[matchupName]!.add(m);
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 24, bottom: 12, left: 8),
                              child: Text('【リーグ戦】 $leagueTitle', style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 16)),
                            ),
                            
                            // 1. ブラッシュアップされた星取表（マトリックス）
                            _buildLeagueGridTable(context, groupName, matches, cardColor: cardColor, isDark: isDark, ref: ref),
                            
                            const SizedBox(height: 32),
                            const Padding(
                              padding: EdgeInsets.only(left: 8, bottom: 12),
                              child: Text('▼ 対戦カード別 スコア詳細', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
                            ),
                            
                            // 2. 各対戦カード（先鋒〜大将）のまとまり表示
                            ...matchupOrder.map((matchupName) {
                              final bouts = boutsByMatchup[matchupName]!;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 24),
                                child: _buildScoreTable(matchupName, bouts, cardColor: cardColor, isDark: isDark),
                              );
                            }),

                            // 3. ★ 修正：順位決定戦もカードごとに分けて美しく表示
                            if (tieBouts.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              const Padding(
                                padding: EdgeInsets.only(left: 8, bottom: 8),
                                child: Text('▼ 順位決定戦', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.orange)),
                              ),
                              ...tieMatchupOrder.map((matchupName) {
                                final bouts = tieBoutsByMatchup[matchupName]!;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _buildScoreTable(matchupName, bouts, cardColor: isDark ? Colors.orange.withValues(alpha: 0.1) : Colors.orange.shade50, isDark: isDark),
                                );
                              }),
                            ],
                            const SizedBox(height: 48),
                          ],
                        );
                      } else {
                        // 通常団体戦の描画
                        return _buildScoreTable(groupName, matches, cardColor: cardColor, isDark: isDark);
                      }
                    },
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  DateTime _getLastTimestamp(List<MatchModel> ms) {
    DateTime last = DateTime.fromMillisecondsSinceEpoch(0);
    for (var m in ms) {
      if (m.events.isNotEmpty && m.events.last.timestamp.isAfter(last)) {
        last = m.events.last.timestamp;
      }
    }
    return last;
  }

  Widget _buildScoreTable(String groupName, List<MatchModel> matches, {Color? cardColor, bool isDark = false}) {
    final note = matches.first.note;
    // ★ 修正：二重カッコを防ぐため、事前に [ ] を除去する
    final cleanNote = note.replaceAll('[', '').replaceAll(']', '').trim();

    final redTeam = matches.first.redName.contains(':') ? matches.first.redName.split(':').first.trim() : matches.first.redName;
    final whiteTeam = matches.first.whiteName.contains(':') ? matches.first.whiteName.split(':').first.trim() : matches.first.whiteName;

    final borderColor = isDark ? const Color(0xFF38383A) : Colors.grey.shade300;
    final headerBgColor = isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade50;
    final headerTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade700;
    final daihyoBgColor = isDark ? Colors.red.shade900.withValues(alpha: 0.15) : Colors.red.shade50;

    // ★ Phase 8-4: すべての試合が完了しているか判定
    bool allFinished = matches.every((m) => m.status == 'approved' || m.status == 'finished');

    // ★ チーム勝敗判定ロジック
    String teamWinner = 'draw';
    int rWins = 0, wWins = 0, rPts = 0, wPts = 0;
    MatchModel? daihyoMatch;

    for (var m in matches) {
      final rs = (m.redScore as num).toInt();
      final ws = (m.whiteScore as num).toInt();
      rPts += rs; 
      wPts += ws;
      if (rs > ws) {
        rWins++;
      } else if (ws > rs) {
        wWins++;
      }
      if (m.matchType == '代表戦') {
        daihyoMatch = m;
      }
    }

    if (rWins > wWins) {
      teamWinner = 'red';
    } else if (wWins > rWins) {
      teamWinner = 'white';
    } else if (rPts > wPts) {
      teamWinner = 'red';
    } else if (wPts > rPts) {
      teamWinner = 'white';
    } else if (daihyoMatch != null) {
      final rs = (daihyoMatch.redScore as num).toInt();
      final ws = (daihyoMatch.whiteScore as num).toInt();
      if (rs > ws) {
        teamWinner = 'red';
      } else if (ws > rs) {
        teamWinner = 'white';
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4), 
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: borderColor)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12), color: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade100, width: double.infinity,
            // ★ 修正：綺麗にした cleanNote を使う
            child: Text(cleanNote.isNotEmpty ? '【$cleanNote】 $redTeam vs $whiteTeam' : '$redTeam vs $whiteTeam', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade300 : Colors.grey.shade800)),
          ),
          Table(
            border: TableBorder.all(color: borderColor, width: 1),
            columnWidths: {
              0: const FlexColumnWidth(1.2),
              for (int i = 1; i <= matches.length; i++) i: const FlexColumnWidth(1.0),
              matches.length + 1: const FlexColumnWidth(0.8),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(color: headerBgColor),
                children: [
                  const SizedBox.shrink(), // ★ 修正：「ポジション」のテキストセルを削除して完全に空欄に
                  ...matches.map((m) => Container(
                    color: m.matchType == '代表戦' ? daihyoBgColor : Colors.transparent, 
                    child: Center(child: Padding(padding: const EdgeInsets.all(8), child: Text(m.matchType, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: m.matchType == '代表戦' ? (isDark ? Colors.red.shade400 : Colors.red.shade900) : (isDark ? Colors.grey.shade300 : Colors.grey.shade800))))),
                  )),
                  Center(child: Padding(padding: const EdgeInsets.all(8), child: Text('勝/本', style: TextStyle(fontSize: 10, color: headerTextColor)))),
                ],
              ),
              TableRow(children: [
                _teamCell(redTeam, isDark ? Colors.red.shade400 : Colors.red.shade700),
                ...matches.map((m) => _nameCell(
                  m.redName, isDark, 
                  matches.map((x) => _parseName(x.redName)['last']!).where((s) => s.isNotEmpty).toList(),
                  isDaihyo: m.matchType == '代表戦'
                )),
                _summaryCell(matches, true, isDark),
              ]),
              TableRow(children: [
                const SizedBox.shrink(),
                ...matches.map((m) => _scoreCell(m, isDark)),
                _teamResultCell(teamWinner, isDark, allFinished), // ★ allFinishedを渡す
              ]),
              TableRow(children: [
                _teamCell(whiteTeam, isDark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade700),
                ...matches.map((m) => _nameCell(
                  m.whiteName, isDark, 
                  matches.map((x) => _parseName(x.whiteName)['last']!).where((s) => s.isNotEmpty).toList(),
                  isDaihyo: m.matchType == '代表戦'
                )),
                _summaryCell(matches, false, isDark),
              ]),
            ],
          ),
        ],
      ),
    );
  }

  // ★ 追加：名前分割ヘルパー
  Map<String, String> _parseName(String raw) {
    if (raw.contains('欠員')) return {'last': '', 'first': ''};
    String clean = raw.contains(':') ? raw.split(':').last.replaceAll(RegExp(r'[()（）]'), '').trim() : raw.trim();
    var parts = clean.split(RegExp(r'\s+'));
    return {'last': parts[0], 'first': parts.length > 1 ? parts[1] : ''};
  }

  // ★ Phase 8-4: allFinished を受け取り、未完了なら勝敗を隠す
  Widget _teamResultCell(String winner, bool isDark, bool allFinished) {
    final textColor = isDark ? Colors.white : Colors.black;
    final dividerColor = isDark ? const Color(0xFF38383A) : Colors.grey.shade300;

    return Container(
      height: 70, 
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 勝負がついていても、試合途中なら境界線（Divider）だけは表示してレイアウトを保つ
          if (winner != 'draw' || !allFinished)
            Divider(color: dividerColor, thickness: 1, height: 0),
          
          // ★ すべての試合が終わっている場合のみテキストを表示
          if (allFinished) ...[
            if (winner == 'draw')
              Center(child: _buildVerticalName('引き分け', '', isDark))
            else
              Column(
                children: [
                  Expanded(child: Center(child: Text(winner == 'red' ? '勝' : '負', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: winner == 'red' ? Colors.red.shade600 : textColor)))),
                  Expanded(child: Center(child: Text(winner == 'white' ? '勝' : '負', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: winner == 'white' ? Colors.red.shade600 : textColor)))),
                ],
              ),
          ]
        ],
      ),
    );
  }

  Widget _teamCell(String name, Color color) => Center(child: Padding(padding: const EdgeInsets.all(8), child: Text(name, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12))));

  // ★ 修正：公式記録画面の欠員は「完全に空欄」にし、同姓は右下に1文字添える
  Widget _nameCell(String rawName, bool isDark, List<String> teamLastNames, {bool isDaihyo = false}) {
    // 欠員は文字を出さず完全に空欄のセルを返す
    if (rawName.contains('欠員')) {
      return Container(color: isDaihyo ? (isDark ? Colors.red.shade900.withValues(alpha: 0.15) : Colors.red.shade50) : Colors.transparent);
    }

    final parsed = _parseName(rawName);
    final showInitial = teamLastNames.where((n) => n == parsed['last']).length > 1 && parsed['first']!.isNotEmpty;

    return Container(
      color: isDaihyo ? (isDark ? Colors.red.shade900.withValues(alpha: 0.15) : Colors.red.shade50) : Colors.transparent, 
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4), 
          child: _buildVerticalName(parsed['last']!, showInitial ? parsed['first']!.substring(0, 1) : '', isDark),
        ),
      ),
    );
  }

  // ★ 修正：同姓の1文字目を美しく配置する縦書きエンジン
  Widget _buildVerticalName(String text, String initial, bool isDark) {
    final style = TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade400 : Colors.grey.shade800);
    
    Widget nameCol = Column(
      mainAxisSize: MainAxisSize.min,
      children: text.split('').map((char) {
        if (char == 'ー' || char == '-') return RotatedBox(quarterTurns: 1, child: Text(char, style: style));
        if (char == '(' || char == ')' || char == '（' || char == '）') return RotatedBox(quarterTurns: 1, child: Text(char, style: style));
        return Text(char, style: style.copyWith(height: 1.1));
      }).toList(),
    );

    if (initial.isEmpty) return nameCol;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        nameCol,
        Padding(
          padding: const EdgeInsets.only(left: 1, bottom: 0),
          child: Text(initial, style: style.copyWith(fontSize: 8, color: isDark ? Colors.grey.shade600 : Colors.grey.shade500)),
        )
      ],
    );
  }

  Widget _scoreCell(MatchModel m, bool isDark) {
    final isDone = m.status == 'finished' || m.status == 'approved';
    final isDraw = isDone && (m.redScore == m.whiteScore);
    final rScore = (m.redScore as num).toInt();
    final wScore = (m.whiteScore as num).toInt();

    // ポイント計算
    List<OfficialPointDisplay> redPts = [];
    List<OfficialPointDisplay> whitePts = [];
    int redHansoku = 0, whiteHansoku = 0;
    bool isMatchFirstPoint = true; 

    for (var e in m.events) {
      if (e.type == PointType.undo) continue;
      if (e.type == PointType.hansoku) {
        if (e.side == Side.red) { // ★ Enum比較
          redHansoku++;
          if (redHansoku == 2 || redHansoku == 4) { whitePts.add(OfficialPointDisplay('反', isMatchFirstPoint)); isMatchFirstPoint = false; }
        } else if (e.side == Side.white) {
          whiteHansoku++;
          if (whiteHansoku == 2 || whiteHansoku == 4) { redPts.add(OfficialPointDisplay('反', isMatchFirstPoint)); isMatchFirstPoint = false; }
        }
      } else {
        if (e.side == Side.red) { redPts.add(OfficialPointDisplay(_toMark(e.type), isMatchFirstPoint)); isMatchFirstPoint = false; }
        else if (e.side == Side.white) { whitePts.add(OfficialPointDisplay(_toMark(e.type), isMatchFirstPoint)); isMatchFirstPoint = false; }
      }
    }

    return Container(
      height: 70, // ★ 修正：大丸と縦2段、左上配置を綺麗に収めるため高さを少し拡張
      alignment: Alignment.center,
      color: m.matchType == '代表戦' ? (isDark ? Colors.red.shade900.withValues(alpha: 0.15) : Colors.red.shade50) : Colors.transparent, 
      child: Stack(
        alignment: Alignment.center,
        children: [
          Divider(color: isDark ? const Color(0xFF38383A) : Colors.grey.shade300, thickness: 1, height: 0),
          if (isDraw) Center(child: Text('✕', style: TextStyle(fontSize: 44, color: isDark ? Colors.red.shade900.withValues(alpha: 0.6) : Colors.red.shade300, fontWeight: FontWeight.w300))),
          Column(
            children: [
              Expanded(child: _buildPointBox(redPts, rScore > wScore, true, isDark)),
              Expanded(child: _buildPointBox(whitePts, wScore > rScore, false, isDark)),
            ],
          ),
        ],
      ),
    );
  }

  // ★ 修正：マス目内の配置と大丸を管理する新しいボックスWidget
  Widget _buildPointBox(List<OfficialPointDisplay> pts, bool isWinner, bool isRed, bool isDark) {
    if (pts.isEmpty && !isWinner) return const SizedBox.shrink();
    
    final color = isRed 
        ? (isDark ? Colors.red.shade400 : Colors.red.shade700) 
        : (isDark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade700);
    
    final bool isFusen = pts.length == 2 && pts.every((p) => p.mark == '◯');

    // ★ 修正：枠を正方形（36x36）に固定し、技が大丸から絶対にはみ出さないようにする
    return SizedBox(
      width: 36, height: 36,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 勝者には大きな丸を描画
          if (isWinner)
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5)),
            ),
          
          if (isFusen)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('◯', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold, height: 1.0)),
                Text('◯', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold, height: 1.0)),
              ],
            )
          else
            Stack(
              children: [
                if (pts.isNotEmpty)
                  Positioned(top: 4, left: 6, child: _buildSingleMark(pts[0], color)),
                if (pts.length > 1)
                  Positioned(bottom: 4, right: 6, child: _buildSingleMark(pts[1], color)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSingleMark(OfficialPointDisplay p, Color color) {
    if (p.isFirstMatchPoint && p.mark != '◯') {
      // ★ 修正：縦横を同値（14x14）に固定し、Alignment.center で文字を中央に配置して「真円」を作る
      return Container(
        width: 14, height: 14,
        alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 1.2)),
        child: Text(p.mark, style: TextStyle(fontSize: 8, color: color, fontWeight: FontWeight.bold, height: 1.0)),
      );
    }
    return Text(p.mark, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold));
  }

  Widget _summaryCell(List<MatchModel> ms, bool isRed, bool isDark) {
    int wins = 0;
    int pts = 0;
    for (var m in ms) {
      final r = (m.redScore as num).toInt();
      final w = (m.whiteScore as num).toInt();
      pts += isRed ? r : w;
      if (isRed && r > w) wins++;
      if (!isRed && w > r) wins++;
    }
    return Center(child: Text('$wins\n--\n$pts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade800), textAlign: TextAlign.center));
  }

  String _toMark(PointType t) {
    switch (t) {
      case PointType.men: return 'メ';
      case PointType.kote: return 'コ';
      case PointType.doIdo: return 'ド';
      case PointType.tsuki: return 'ツ';
      case PointType.hansoku: return '反';
      case PointType.fusen: return '◯'; 
      default: return '';
    }
  }

  // ★ 修正：ご要望通りのタイトル（自チーム名入り）を生成し、Lint警告も解消
  String _generateDescriptiveLeagueTitle(List<MatchModel> matches, List<String> ownTeams) {
    final participantsSet = <String>{};
    for (var m in matches) {
      participantsSet.add(m.redName.split(':').first.trim());
      participantsSet.add(m.whiteName.split(':').first.trim());
    }
    final int n = participantsSet.length;
    final int mCount = n * (n - 1) ~/ 2;
    final bool isIndiv = matches.any((m) => m.matchType == 'individual' || m.matchType == '選手' || m.matchType.contains('個人戦'));

    String selfInfo = "";
    if (isIndiv) {
      final myMatch = matches.firstWhere((m) => ownTeams.any((ot) => m.redName.contains(ot) || m.whiteName.contains(ot)), orElse: () => matches.first);
      final isRedOwn = ownTeams.any((ot) => myMatch.redName.contains(ot));
      final rawName = isRedOwn ? myMatch.redName : myMatch.whiteName;
      final team = rawName.split(':').first.trim();
      final name = rawName.contains(':') ? rawName.split(':').last.replaceAll(')', '').trim() : rawName;
      selfInfo = "$name（$team）";
    } else {
      selfInfo = participantsSet.firstWhere((p) => ownTeams.contains(p), orElse: () => participantsSet.first);
    }

    // ★ 修正：不要な {} を削除して Lint 警告を消去
    final suffix = isIndiv ? "$n人リーグ" : "$nチームリーグ";
    return "$selfInfo : $suffix（全$mCount試合）";
  }

  // ★ 追加：印刷画面用のリーグ星取表描画メソッド
  Widget _buildLeagueGridTable(BuildContext context, String groupName, List<MatchModel> matches, {Color? cardColor, required bool isDark, required WidgetRef ref}) {
    final normalMatches = matches.where((m) => !m.note.contains('[順位決定戦]')).toList();
    if (normalMatches.isEmpty) return const SizedBox();

    final rule = normalMatches.first.rule ?? ref.read(matchRuleProvider);
    final nonNullRule = rule!;
    final stats = KendoRuleEngine.calculateLeagueStandings(normalMatches, nonNullRule);
    final isIndiv = normalMatches.any((m) => m.matchType == 'individual' || m.matchType == '選手' || m.matchType.contains('個人戦'));
    final allFinished = matches.every((m) => m.status == 'approved' || m.status == 'finished');
    final hasMatchPoints = nonNullRule.isLeague;

    final teams = <String>{};
    for (var m in normalMatches) {
      teams.add(m.redName.split(':').first.trim());
      teams.add(m.whiteName.split(':').first.trim());
    }
    final teamList = teams.toList()..sort();
    
    final borderColor = isDark ? const Color(0xFF38383A) : Colors.grey.shade400;
    final headerColor = isDark ? const Color(0xFF2C2C2E) : Colors.indigo.shade50;
    final blankColor = isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade200;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        elevation: 0,
        color: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: borderColor)),
        clipBehavior: Clip.antiAlias,
        child: Table(
          border: TableBorder.all(color: borderColor, width: 1),
          columnWidths: {
            0: const FixedColumnWidth(100), // チーム名
            for (int i = 1; i <= teamList.length; i++) i: const FixedColumnWidth(65), // 各対戦
            teamList.length + 1: const FixedColumnWidth(45), // 勝数
            teamList.length + 2: const FixedColumnWidth(45), // 勝者
            teamList.length + 3: const FixedColumnWidth(45), // 本数
            if (hasMatchPoints) teamList.length + 4: const FixedColumnWidth(45), // 勝ち点
            teamList.length + (hasMatchPoints ? 5 : 4): const FixedColumnWidth(45), // 順位
          },
          children: [
            TableRow(
              decoration: BoxDecoration(color: headerColor),
              children: [
                const SizedBox(height: 50),
                ...teamList.map((t) => Center(child: Padding(padding: const EdgeInsets.all(4), child: _buildVerticalName(t, '', isDark)))),
                _buildHeaderCell('勝数', isDark), _buildHeaderCell('勝者', isDark), _buildHeaderCell('本数', isDark),
                if (hasMatchPoints) _buildHeaderCell('勝点', isDark),
                _buildHeaderCell('順位', isDark),
              ]
            ),
            ...teamList.map((rowTeam) {
              final stat = stats.firstWhere((s) => s.name == rowTeam, orElse: () => stats.first);
              final rankStr = allFinished ? '${stats.indexWhere((s) => s.name == rowTeam) + 1}' : '-';

              return TableRow(
                children: [
                  Container(
                    height: 65, alignment: Alignment.center, decoration: BoxDecoration(color: headerColor),
                    child: Padding(padding: const EdgeInsets.all(4), child: Text(rowTeam, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isDark ? Colors.white : Colors.black87), textAlign: TextAlign.center, maxLines: 2)),
                  ),
                  ...teamList.map((colTeam) {
                    if (rowTeam == colTeam) {
                      return Container(height: 65, color: blankColor, child: CustomPaint(painter: DiagonalLinePainter(color: borderColor)));
                    }
                    final bouts = normalMatches.where((m) {
                      final r = m.redName.split(':').first.trim();
                      final w = m.whiteName.split(':').first.trim();
                      return (r == rowTeam && w == colTeam) || (r == colTeam && w == rowTeam);
                    }).toList();
                    if (bouts.isEmpty) return const SizedBox(height: 65);
                    
                    int rWins = 0, cWins = 0, rPoints = 0, cPoints = 0, rWinners = 0, cWinners = 0;
                    List<String> techs = [];
                    for (var m in bouts) {
                      final isRowRed = m.redName.split(':').first.trim() == rowTeam;
                      final rs = (m.redScore as num).toInt(); final ws = (m.whiteScore as num).toInt();
                      if (rs > ws) { isRowRed ? rWins++ : cWins++; isRowRed ? rWinners++ : cWinners++; }
                      else if (ws > rs) { isRowRed ? cWins++ : rWins++; isRowRed ? cWinners++ : rWinners++; }
                      isRowRed ? rPoints += rs : cPoints += rs; isRowRed ? cPoints += ws : rPoints += ws;
                      if (isIndiv) techs.addAll(_extractTechs(m.events, isRowRed, isRowRed ? rs : ws));
                    }
                    
                    String result = 'draw';
                    Color symbolColor = isDark ? Colors.amber.shade300 : Colors.amber.shade700;
                    if (rWins > cWins) { result = 'win'; symbolColor = isDark ? Colors.red.shade300 : Colors.red.shade700; }
                    else if (cWins > rWins) { result = 'loss'; symbolColor = isDark ? Colors.blue.shade300 : Colors.indigo.shade700; }
                    
                    if (!bouts.every((m) => m.status == 'approved' || m.status == 'finished')) return const SizedBox(height: 65);
                    
                    final textColor = isDark ? Colors.white : Colors.black87;

                    // ★ 修正：内部余白（Padding）を確保し、フワッと浮かび上がる極上のポップアップ
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        showGeneralDialog(
                          context: context,
                          barrierDismissible: true,
                          barrierLabel: '閉じる',
                          barrierColor: Colors.black.withValues(alpha: 0.7),
                          transitionDuration: const Duration(milliseconds: 350), 
                          pageBuilder: (ctx, anim1, anim2) {
                            return Center(
                              child: Dialog(
                                backgroundColor: Colors.transparent,
                                elevation: 0,
                                insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40), // 画面端との余白
                                child: Container(
                                  constraints: const BoxConstraints(maxWidth: 550),
                                  // ★ ここで「ポップアップの枠」としての外装を定義
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
                                  ),
                                  // ★ 修正ポイント：内部に十分な余白（Padding）を設ける
                                  padding: const EdgeInsets.all(20), 
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: SingleChildScrollView(
                                          child: _buildScoreTable('$rowTeam vs $colTeam', bouts, cardColor: Colors.transparent, isDark: isDark),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                                          foregroundColor: isDark ? Colors.white : Colors.black87,
                                          shape: const StadiumBorder(),
                                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                                          elevation: 0,
                                        ),
                                        child: const Text('閉じる', style: TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                          transitionBuilder: (ctx, anim1, anim2, child) {
                            // フワッと浮かび上がる滑らかなスケールアニメーション
                            return FadeTransition(
                              opacity: anim1,
                              child: ScaleTransition(
                                scale: Tween<double>(begin: 0.9, end: 1.0).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
                                child: child,
                              ),
                            );
                          },
                        );
                      },
                      child: Container(
                        height: 65,
                        alignment: Alignment.center,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(size: const Size(45, 45), painter: ResultShapePainter(result: result, color: symbolColor)),
                            if (isIndiv)
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  techs.isNotEmpty ? _buildIndivSingle(techs[0], true, textColor) : const SizedBox(height: 12),
                                  Container(height: 0.5, width: 18, color: textColor.withValues(alpha: 0.5), margin: const EdgeInsets.symmetric(vertical: 2)),
                                  techs.length > 1 ? _buildIndivSingle(techs[1], false, textColor) : const SizedBox(height: 12),
                                ],
                              )
                            else
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('$rPoints', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, height: 1.1, color: textColor)),
                                  Container(height: 0.5, width: 18, color: textColor.withValues(alpha: 0.5), margin: const EdgeInsets.symmetric(vertical: 2)),
                                  Text('$rWinners', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, height: 1.1, color: textColor)),
                                ]
                              ),
                          ],
                        ),
                      ),
                    );
                  }), // チームループ(colTeam)の閉じ
                  _buildStatCell('${stat.matchWins}', isDark),
                  _buildStatCell('${stat.individualWinners}', isDark),
                  _buildStatCell('${stat.totalPointsScored}', isDark),
                  if (hasMatchPoints) _buildStatCell(stat.customPoints.toStringAsFixed(stat.customPoints.truncateToDouble() == stat.customPoints ? 0 : 1), isDark),
                  _buildStatCell(rankStr, isDark, isRank: true),
                ]
              );
            }), // チームループ(rowTeam)の閉じ
          ]
        )
      ),
    );
  }

  Widget _buildHeaderCell(String text, bool isDark) {
    return Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(text, style: TextStyle(fontSize: 10, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600))));
  }

  Widget _buildStatCell(String text, bool isDark, {bool isRank = false}) {
    return Container(
      height: 65, alignment: Alignment.center,
      color: isRank ? (isDark ? Colors.orange.withValues(alpha: 0.2) : Colors.orange.shade50) : null,
      child: Text(text, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isRank ? 16 : 13, color: isRank ? Colors.orange.shade800 : (isDark ? Colors.white : Colors.black87))),
    );
  }
}

// ★ 追加：表の「自分自身」のセルに斜め線を引くためのクラス
class DiagonalLinePainter extends CustomPainter {
  final Color color;
  DiagonalLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 1;
    canvas.drawLine(const Offset(0, 0), Offset(size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ★ ◯・△・□ を描画する究極のペインター（図形のみを描画、分数の線はWidget側で描画します）
class ResultShapePainter extends CustomPainter {
  final String result; // 'win', 'loss', 'draw'
  final Color color;
  ResultShapePainter({required this.result, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = color.withValues(alpha: 0.1)..style = PaintingStyle.fill;
    final strokePaint = Paint()..color = color..strokeWidth = 1.0..style = PaintingStyle.stroke;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.42;

    if (result == 'win') {
      canvas.drawCircle(center, radius, bgPaint);
      canvas.drawCircle(center, radius, strokePaint);
    } else if (result == 'loss') {
      final path = Path();
      path.moveTo(center.dx, center.dy - radius);
      path.lineTo(center.dx + radius * 1.1, center.dy + radius * 0.8);
      path.lineTo(center.dx - radius * 1.1, center.dy + radius * 0.8);
      path.close();
      canvas.drawPath(path, bgPaint);
      canvas.drawPath(path, strokePaint);
    } else {
      final rect = Rect.fromCenter(center: center, width: radius * 1.6, height: radius * 1.6);
      canvas.drawRect(rect, bgPaint);
      canvas.drawRect(rect, strokePaint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ★ 1本目だけ丸囲みするヘルパー
Widget _buildIndivSingle(String tech, bool isFirst, Color color) {
  if (isFirst && tech != '◯') {
    return Container(
      width: 14, height: 14, alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 0.8)),
      child: Text(tech, style: TextStyle(fontSize: 8, color: color, fontWeight: FontWeight.bold, height: 1.1)),
    );
  }
  return Text(tech, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold, height: 1.1));
}

// ★ ログから技（メ・コ・ド・ツ・反）を抽出するヘルパー
List<String> _extractTechs(List<dynamic> logs, bool isRed, int count) {
  List<String> res = [];
  for (var log in logs) {
    String s = log.toString();
    bool isRedPoint = s.contains('red') || s.contains('赤');
    if (isRed == isRedPoint) {
      if (s.contains('メ')) {
        res.add('メ');
      } else if (s.contains('コ')) {
        res.add('コ');
      } else if (s.contains('ド')) {
        res.add('ド');
      } else if (s.contains('ツ')) {
        res.add('ツ');
      } else if (s.contains('反')) {
        res.add('反');
      } else {
        res.add('◯');
      }
    }
  }
  while (res.length < count) {
    res.add('◯');
  }
  return res.take(count).toList();
}