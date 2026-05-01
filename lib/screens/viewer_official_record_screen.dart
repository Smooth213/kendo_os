import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/match_model.dart';
import '../domain/match/score_event.dart';
import '../presentation/provider/match_list_provider.dart';
import '../application/service/pdf/pdf_service.dart';
import 'kachinuki_scoreboard_screen.dart';
import 'home_screen.dart';
import '../utils/bunaiksen_helper.dart';
import '../domain/kendo_rule_engine.dart';
import '../presentation/provider/match_rule_provider.dart';

class OfficialPointDisplay {
  final String mark;
  final bool isFirstMatchPoint;
  OfficialPointDisplay(this.mark, this.isFirstMatchPoint);
}

class ViewerOfficialRecordScreen extends ConsumerWidget {
  final String tournamentId; 
  const ViewerOfficialRecordScreen({super.key, required this.tournamentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    const String screenTitle = '大会 公式記録';

    final bgColor = isDark ? Colors.black : const Color(0xFFF2F2F7);
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final headerTextColor = isDark ? Colors.white : Colors.indigo.shade900;

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

            // 個人戦グループを統合するためのマップ
            final mergedGroups = <String, List<MatchModel>>{};
            final List<MatchModel> individualMergedList = [];
            final uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');

            groupsMap.forEach((key, matches) {
              final isIndiv = matches.any((m) => m.matchType == 'individual' || m.matchType == '選手' || m.matchType.contains('個人戦'));
              final isLeague = matches.any((m) => m.note.contains('[リーグ戦]'));
              
              // 通常の個人戦（リーグ戦以外）かつ、ID形式のグループ名を統合対象とする
              if (isIndiv && !isLeague && (uuidRegex.hasMatch(key) || key.length > 20)) {
                individualMergedList.addAll(matches);
              } else {
                mergedGroups[key] = matches;
              }
            });

            // 統合された個人戦がある場合、特殊なキーで登録
            if (individualMergedList.isNotEmpty) {
              mergedGroups['__merged_individual__'] = individualMergedList;
            }

            // ソート対象を mergedGroups に変更
            final sortedGroupKeys = mergedGroups.keys.toList()..sort((a, b) {
              final aLast = _getLastTimestamp(mergedGroups[a]!);
              final bLast = _getLastTimestamp(mergedGroups[b]!);
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
                              'matches': mergedGroups[key]!..sort((a, b) => a.order.compareTo(b.order)),
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
                              'matches': mergedGroups[key]!..sort((a, b) => a.order.compareTo(b.order)),
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
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.all(8),
                    itemCount: sortedGroupKeys.length,
                    itemBuilder: (context, index) {
                      final groupName = sortedGroupKeys[index];
                      // 取得先を統合済みの mergedGroups に変更
                      final matches = mergedGroups[groupName]!..sort((a, b) => a.order.compareTo(b.order));
                      
                      if (matches.isNotEmpty && matches.first.isKachinuki) {
                        final firstMatch = matches.first;
                        final note = firstMatch.note;
                        final cleanNote = note.replaceAll('[', '').replaceAll(']', '').trim();
                        final rTeam = firstMatch.redName.contains(':') ? firstMatch.redName.split(':').first.trim() : firstMatch.redName;
                        final wTeam = firstMatch.whiteName.contains(':') ? firstMatch.whiteName.split(':').first.trim() : firstMatch.whiteName;
                        
                        // ヘッダーを【勝ち抜き戦】チーム名 vs チーム名 の形式に統一
                        String titleText = '【勝ち抜き戦】 $rTeam vs $wTeam';
                        if (cleanNote.isNotEmpty && !cleanNote.contains('勝ち抜き戦')) {
                          titleText += ' ($cleanNote)';
                        }

                        int redRem = matches.last.redRemaining.length;
                        int whiteRem = matches.last.whiteRemaining.length;
                        int maxRem = redRem > whiteRem ? redRem : whiteRem;
                        int totalCols = matches.length + maxRem;

                        final canvasWidth = 60.0 + (totalCols * 60.0) + 120.0;
                        
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
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  color: isDark ? Colors.black : Colors.white,
                                  width: canvasWidth < MediaQuery.of(context).size.width ? MediaQuery.of(context).size.width : canvasWidth,
                                  height: 520,
                                  child: CustomPaint(
                                    painter: KachinukiBracketPainter(
                                      matches: matches,
                                      isDark: isDark,
                                      ref: ref,
                                    ),
                                    size: Size.infinite,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      } else if (matches.isNotEmpty && matches.any((m) => m.note.contains('[リーグ戦]'))) {
                        final ownTeams = ref.watch(customTeamNamesProvider).value ?? [];
                        final String leagueTitle = BunaiksenHelper.generateDescriptiveLeagueTitle(matches, ownTeams);
                        final textColor = isDark ? Colors.white : Colors.indigo.shade900;

                        final normalMatches = matches.where((m) => !m.note.contains('[順位決定戦]')).toList();
                        final tieBouts = matches.where((m) => m.note.contains('[順位決定戦]')).toList();

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

                        final isIndiv = matches.any((m) => m.matchType == 'individual' || m.matchType == '選手' || m.matchType.contains('個人戦'));

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 24, bottom: 12, left: 8),
                              child: Text('【リーグ戦】 $leagueTitle', style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 16)),
                            ),
                            
                            _buildLeagueGridTable(context, groupName, matches, cardColor: cardColor, isDark: isDark, ref: ref),
                            
                            const SizedBox(height: 32),
                            const Padding(
                              padding: EdgeInsets.only(left: 8, bottom: 12),
                              child: Text('▼ 対戦カード別 スコア詳細', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
                            ),
                            
                            // 2. 詳細スコアの表示（個人戦なら中枠なしの一括リスト）
                            if (isIndiv)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 24),
                                child: _buildIndividualMatchesList('対戦スコア詳細', normalMatches, cardColor: cardColor, isDark: isDark, ref: ref, applySort: false),
                              )
                            else
                              ...matchupOrder.map((matchupName) {
                                final bouts = boutsByMatchup[matchupName]!;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 24),
                                  child: _buildScoreTable(matchupName, bouts, cardColor: cardColor, isDark: isDark),
                                );
                              }),

                            if (tieBouts.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              const Padding(
                                padding: EdgeInsets.only(left: 8, bottom: 8),
                                child: Text('▼ 順位決定戦', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.orange)),
                              ),
                              if (isIndiv)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _buildIndividualMatchesList('順位決定戦', tieBouts, cardColor: isDark ? Colors.orange.withValues(alpha: 0.1) : Colors.orange.shade50, isDark: isDark, ref: ref, applySort: false),
                                )
                              else
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
                      } else if (matches.isNotEmpty && matches.any((m) => m.matchType == 'individual' || m.matchType == '選手' || m.matchType.contains('個人戦'))) {
                        // 👇 追加: 個人戦の場合は、専用の縦並びリスト形式で描画する
                        return _buildIndividualMatchesList(groupName, matches, cardColor: cardColor, isDark: isDark, ref: ref, applySort: true);
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
    final cleanNote = note.replaceAll('[', '').replaceAll(']', '').trim();

    final redTeam = matches.first.redName.contains(':') ? matches.first.redName.split(':').first.trim() : matches.first.redName;
    final whiteTeam = matches.first.whiteName.contains(':') ? matches.first.whiteName.split(':').first.trim() : matches.first.whiteName;

    // 「赤」「白」ではなく実際のチーム名を表示するように変更
    final String sideLabelRed = redTeam;
    final String sideLabelWhite = whiteTeam;

    // 試合形式に合わせてヘッダーテキストを生成
    String matchTypeStr = '団体戦';
    if (matches.any((m) => m.matchType == 'individual' || m.matchType == '選手' || m.matchType.contains('個人戦'))) {
      matchTypeStr = '個人戦';
    } else if (matches.first.isKachinuki) {
      matchTypeStr = '勝ち抜き戦';
    } else if (matches.any((m) => m.note.contains('リーグ戦'))) {
      matchTypeStr = 'リーグ戦';
    }
    
    String headerTitle = '【$matchTypeStr】 $redTeam vs $whiteTeam';
    if (cleanNote.isNotEmpty && !cleanNote.contains(matchTypeStr)) {
      headerTitle += ' ($cleanNote)';
    }

    final borderColor = isDark ? const Color(0xFF38383A) : Colors.grey.shade300;
    final headerBgColor = isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade50;
    final headerTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade700;
    final daihyoBgColor = isDark ? Colors.red.shade900.withValues(alpha: 0.15) : Colors.red.shade50;

    bool allFinished = matches.every((m) => m.status == 'approved' || m.status == 'finished');

    String teamWinner = 'draw';
    int rWins = 0, wWins = 0, rPts = 0, wPts = 0;
    MatchModel? daihyoMatch;

    for (var m in matches) {
      final rs = (m.redScore as num).toInt();
      final ws = (m.whiteScore as num).toInt();
      rPts += rs; wPts += ws;
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

    final bool isSummary = matches.any((m) => m.note.contains('[SUMMARY]'));

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4), 
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: borderColor)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12), color: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade100, width: double.infinity,
                // 先ほど生成した headerTitle を使用する
                child: Text(headerTitle, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade300 : Colors.grey.shade800)),
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
                      const SizedBox.shrink(),
                      ...matches.map((m) => Container(
                        color: m.matchType == '代表戦' ? daihyoBgColor : Colors.transparent,
                        child: Center(child: Padding(padding: const EdgeInsets.all(8), child: Text(m.matchType, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: m.matchType == '代表戦' ? (isDark ? Colors.red.shade400 : Colors.red.shade900) : (isDark ? Colors.grey.shade300 : Colors.grey.shade800))))),
                      )),
                      Center(child: Padding(padding: const EdgeInsets.all(8), child: Text('勝/本', style: TextStyle(fontSize: 10, color: headerTextColor)))),
                    ],
                  ),
                  TableRow(children: [
                    _teamCell(sideLabelRed, isDark ? Colors.red.shade400 : Colors.red.shade700),
                    ...matches.map((m) => _nameCell(
                      m.redName, isDark, 
                      matches.map((x) => BunaiksenHelper.parseName(x.redName)['last']!).where((s) => s.isNotEmpty).toList(),
                      isDaihyo: m.matchType == '代表戦'
                    )),
                    _summaryCell(matches, true, isDark),
                  ]),
                  TableRow(children: [
                    const SizedBox.shrink(),
                    ...matches.map((m) => _scoreCell(m, isDark, isSummary)),
                    _teamResultCell(teamWinner, isDark, allFinished),
                  ]),
                  TableRow(children: [
                    _teamCell(sideLabelWhite, isDark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade700),
                    ...matches.map((m) => _nameCell(
                      m.whiteName, isDark, 
                      matches.map((x) => BunaiksenHelper.parseName(x.whiteName)['last']!).where((s) => s.isNotEmpty).toList(),
                      isDaihyo: m.matchType == '代表戦'
                    )),
                    _summaryCell(matches, false, isDark),
                  ]),
                ],
              ),
            ],
          ),
          if (isSummary)
            Positioned.fill(
              top: 40,
              child: Container(
                color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.6),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black87 : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)],
                    ),
                    child: Text('※簡易入力された結果です\n（詳細スコアはありません）', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _teamResultCell(String winner, bool isDark, bool allFinished) {
    final textColor = isDark ? Colors.white : Colors.black;
    final dividerColor = isDark ? const Color(0xFF38383A) : Colors.grey.shade300;

    return Container(
      height: 70, 
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (winner != 'draw' || !allFinished)
            Divider(color: dividerColor, thickness: 1, height: 0),
          
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

  // チーム名が長い場合でも中央揃えで綺麗に折り返されるように調整
  Widget _teamCell(String name, Color color) => Center(child: Padding(padding: const EdgeInsets.all(4), child: Text(name, textAlign: TextAlign.center, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11))));

  Widget _nameCell(String rawName, bool isDark, List<String> teamLastNames, {bool isDaihyo = false}) {
    if (rawName.contains('欠員')) {
      return Container(color: isDaihyo ? (isDark ? Colors.red.shade900.withValues(alpha: 0.15) : Colors.red.shade50) : Colors.transparent);
    }

    final parsed = BunaiksenHelper.parseName(rawName);
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

  Widget _scoreCell(MatchModel m, bool isDark, bool isSummary) {
    if (isSummary) return const SizedBox(height: 70);
    final isDone = m.status == 'finished' || m.status == 'approved';
    final rScore = (m.redScore as num).toInt();
    final wScore = (m.whiteScore as num).toInt();

    List<OfficialPointDisplay> redPts = [];
    List<OfficialPointDisplay> whitePts = [];
    int redHansoku = 0;
    int whiteHansoku = 0;
    bool isMatchFirstPoint = true;

    for (var e in m.events) {
      if (e.type == PointType.undo || e.isCanceled) continue;
      if (e.type == PointType.hansoku) {
        if (e.side == Side.red) {
          redHansoku++;
          if (redHansoku == 2 || redHansoku == 4) { whitePts.add(OfficialPointDisplay('反', false)); isMatchFirstPoint = false; }
        } else {
          whiteHansoku++;
          if (whiteHansoku == 2 || whiteHansoku == 4) { redPts.add(OfficialPointDisplay('反', false)); isMatchFirstPoint = false; }
        }
      } else {
        if (e.side == Side.red) { redPts.add(OfficialPointDisplay(_toMark(e.type), isMatchFirstPoint)); isMatchFirstPoint = false; }
        else { whitePts.add(OfficialPointDisplay(_toMark(e.type), isMatchFirstPoint)); isMatchFirstPoint = false; }
      }
    }

    return Container(
      height: 70, alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Divider(color: isDark ? const Color(0xFF38383A) : Colors.grey.shade300, thickness: 1, height: 0),
          Column(
            children: [
              Expanded(child: _buildPointBox(redPts, isDone && rScore > wScore, true, isDark)),
              Expanded(child: _buildPointBox(whitePts, isDone && wScore > rScore, false, isDark)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPointBox(List<OfficialPointDisplay> pts, bool isWinner, bool isRed, bool isDark) {
    final color = isRed ? Colors.red.shade700 : Colors.blue.shade700;
    return SizedBox(
      width: 36, height: 36,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isWinner) Container(width: 32, height: 32, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5))),
          if (pts.isNotEmpty) Positioned(top: 4, left: 6, child: _buildSingleMark(pts[0], color)),
          if (pts.length > 1) Positioned(bottom: 4, right: 6, child: _buildSingleMark(pts[1], color)),
        ],
      ),
    );
  }

  Widget _buildSingleMark(OfficialPointDisplay p, Color color) {
    if (p.isFirstMatchPoint && p.mark != '反') {
      return Container(
        width: 14, height: 14, alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 0.8)),
        child: Text(p.mark, style: TextStyle(fontSize: 8, color: color, fontWeight: FontWeight.bold, height: 1.1)),
      );
    }
    return Text(p.mark, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold, height: 1.1));
  }

  String _toMark(PointType type) {
    switch (type) {
      case PointType.men: return 'メ';
      case PointType.kote: return 'コ';
      case PointType.doIdo: return 'ド';
      case PointType.tsuki: return 'ツ';
      case PointType.hansoku: return '反';
      case PointType.fusen: return '◯';
      default: return '';
    }
  }

  Widget _summaryCell(List<MatchModel> ms, bool isRed, bool isDark) {
    int wins = 0; int pts = 0;
    for (var m in ms) {
      final r = (m.redScore as num).toInt(); final w = (m.whiteScore as num).toInt();
      pts += isRed ? r : w;
      if (isRed && r > w) {
        wins++;
      } else if (!isRed && w > r) {
        wins++;
      }
    }
    return Center(child: Text('$wins\n--\n$pts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade800), textAlign: TextAlign.center));
  }

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
            0: const FixedColumnWidth(100), 
            for (int i = 1; i <= teamList.length; i++) i: const FixedColumnWidth(65), 
            teamList.length + 1: const FixedColumnWidth(45), 
            teamList.length + 2: const FixedColumnWidth(45), 
            teamList.length + 3: const FixedColumnWidth(45), 
            if (hasMatchPoints) teamList.length + 4: const FixedColumnWidth(45), 
            teamList.length + (hasMatchPoints ? 5 : 4): const FixedColumnWidth(45), 
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
                      if (isIndiv) {
                        final extracted = BunaiksenHelper.extractTechs(m.events, isRowRed, isRowRed ? rs : ws);
                        
                        // 🌟 修正：既存の extracted があっても、SUMMARYタグがあれば記号を「◯」に統一する
                        final bool isSummary = m.note.contains('[SUMMARY]');
                        if (isSummary || extracted.isEmpty) {
                          extracted.clear();
                          for(int k=0; k<(isRowRed ? rs : ws); k++) {
                            extracted.add('◯');
                          }
                        }
                        techs.addAll(extracted);
                      }
                    }
                    
                    String result = 'draw';
                    Color symbolColor = isDark ? Colors.amber.shade300 : Colors.amber.shade700;
                    if (rWins > cWins) { result = 'win'; symbolColor = isDark ? Colors.red.shade300 : Colors.red.shade700; }
                    else if (cWins > rWins) { result = 'loss'; symbolColor = isDark ? Colors.blue.shade300 : Colors.indigo.shade700; }
                    
                    if (!bouts.every((m) => m.status == 'approved' || m.status == 'finished')) return const SizedBox(height: 65);
                    
                    final textColor = isDark ? Colors.white : Colors.black87;

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
                                insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                                child: Container(
                                  constraints: const BoxConstraints(maxWidth: 550),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
                                  ),
                                  padding: const EdgeInsets.all(20), 
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: isIndiv 
                                          // 🌟 修正：個人戦なら必ずリスト形式を呼び出し、ソートは不要(applySort: false)
                                          ? _buildIndividualMatchesList('$rowTeam vs $colTeam', bouts, cardColor: Colors.transparent, isDark: isDark, ref: ref, applySort: false)
                                          : _buildScoreTable('$rowTeam vs $colTeam', bouts, cardColor: Colors.transparent, isDark: isDark),
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

  // 👇 ここから追加：個人戦専用の縦並びリスト描画エンジン
  Widget _buildIndividualMatchesList(String groupName, List<MatchModel> matches, {Color? cardColor, required bool isDark, required WidgetRef ref, required bool applySort}) {
    final borderColor = isDark ? const Color(0xFF38383A) : Colors.grey.shade300;
    final headerBgColor = isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade50;
    final textColor = isDark ? Colors.white : Colors.black87;

    List<MatchModel> displayMatches = List.from(matches);

    if (applySort) {
      final ownTeams = ref.watch(customTeamNamesProvider).value ?? [];
      
      int getTeamPriority(MatchModel m) {
        final rTeam = m.redName.contains(':') ? m.redName.split(':').first.trim() : '';
        final wTeam = m.whiteName.contains(':') ? m.whiteName.split(':').first.trim() : '';
        bool rOwn = ownTeams.contains(rTeam) || m.redName.contains('自チーム');
        bool wOwn = ownTeams.contains(wTeam) || m.whiteName.contains('自チーム');
        if (rOwn && wOwn) return 1; // 同門
        if (rOwn || wOwn) return 2; // 自チーム vs 他チーム
        return 3; // 他チーム同士
      }

      String getSortName(MatchModel m) {
        final rTeam = m.redName.contains(':') ? m.redName.split(':').first.trim() : '';
        final wTeam = m.whiteName.contains(':') ? m.whiteName.split(':').first.trim() : '';
        final rName = m.redName.contains(':') ? m.redName.split(':').last.trim() : m.redName;
        final wName = m.whiteName.contains(':') ? m.whiteName.split(':').last.trim() : m.whiteName;
        
        bool rOwn = ownTeams.contains(rTeam) || m.redName.contains('自チーム');
        bool wOwn = ownTeams.contains(wTeam) || m.whiteName.contains('自チーム');
        
        if (rOwn && wOwn) return rName; // 同門は赤優先
        if (rOwn) return rName;
        if (wOwn) return wName;
        return rName; 
      }

      displayMatches.sort((a, b) {
        int pA = getTeamPriority(a);
        int pB = getTeamPriority(b);
        if (pA != pB) return pA.compareTo(pB);

        String nameA = getSortName(a);
        String nameB = getSortName(b);
        int nameCompare = nameA.compareTo(nameB);
        if (nameCompare != 0) return nameCompare;

        return a.order.compareTo(b.order); // 同じ選手なら試合順
      });
    }

    // ヘッダー名からシステムID（英数字とハイフンの羅列）を隠す処理
    final uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
    String displayGroupName = groupName;
    if (uuidRegex.hasMatch(groupName) || groupName.length > 20) {
      displayGroupName = '';
    }

    final note = matches.first.note;
    final cleanNote = note.replaceAll('[', '').replaceAll(']', '').trim();
    String headerTitle = '【個人戦】';
    if (displayGroupName.isNotEmpty) headerTitle += ' $displayGroupName';
    if (cleanNote.isNotEmpty && !cleanNote.contains('個人戦')) headerTitle += ' ($cleanNote)';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: borderColor)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12), color: headerBgColor, width: double.infinity,
            child: Text(headerTitle, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade300 : Colors.grey.shade800)),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayMatches.length,
            separatorBuilder: (context, index) => Divider(color: borderColor, height: 1, indent: 16, endIndent: 16),
            itemBuilder: (context, index) {
              final m = displayMatches[index];
              final rName = m.redName.contains(':') ? m.redName.split(':').last.replaceAll(')', '').trim() : m.redName;
              final wName = m.whiteName.contains(':') ? m.whiteName.split(':').last.replaceAll(')', '').trim() : m.whiteName;
              final rTeam = m.redName.contains(':') ? m.redName.split(':').first.trim() : '';
              final wTeam = m.whiteName.contains(':') ? m.whiteName.split(':').first.trim() : '';

              final isDone = m.status == 'finished' || m.status == 'approved';
              final rScore = (m.redScore as num).toInt();
              final wScore = (m.whiteScore as num).toInt();
              final isDraw = isDone && rScore == wScore;
              final rWin = isDone && rScore > wScore;
              final wWin = isDone && wScore > rScore;

              List<OfficialPointDisplay> redPts = [];
              List<OfficialPointDisplay> whitePts = [];
              int redHansoku = 0; int whiteHansoku = 0; bool isMatchFirstPoint = true;
              for (var e in m.events) {
                if (e.type == PointType.undo || e.isCanceled) continue;
                if (e.type == PointType.hansoku) {
                  if (e.side == Side.red) {
                    redHansoku++;
                    if (redHansoku == 2 || redHansoku == 4) { whitePts.add(OfficialPointDisplay('反', false)); isMatchFirstPoint = false; }
                  } else {
                    whiteHansoku++;
                    if (whiteHansoku == 2 || whiteHansoku == 4) { redPts.add(OfficialPointDisplay('反', false)); isMatchFirstPoint = false; }
                  }
                } else {
                  if (e.side == Side.red) { redPts.add(OfficialPointDisplay(_toMark(e.type), isMatchFirstPoint)); isMatchFirstPoint = false; }
                  else { whitePts.add(OfficialPointDisplay(_toMark(e.type), isMatchFirstPoint)); isMatchFirstPoint = false; }
                }
              }

              // 自チーム判定
              final ownTeams = ref.watch(customTeamNamesProvider).value ?? [];
              final bool rOwn = ownTeams.contains(rTeam) || m.redName.contains('自チーム');
              final bool wOwn = ownTeams.contains(wTeam) || m.whiteName.contains('自チーム');
              final bool hasOwnTeam = rOwn || wOwn;
              final bool isRowSummary = m.note.contains('[SUMMARY]');
              
              // 行のコンテンツ
              Widget rowContent = Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 55,
                      child: Text(m.note.isNotEmpty ? m.note : '第${index+1}試合', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (rTeam.isNotEmpty) Text(rTeam, style: TextStyle(fontSize: 9, color: Colors.grey.shade500), overflow: TextOverflow.ellipsis),
                          Text(rName, style: TextStyle(fontWeight: rWin ? FontWeight.w900 : FontWeight.bold, color: rWin ? Colors.red.shade700 : textColor), overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildPointBox(redPts, rWin, true, isDark),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(isDraw ? '✕' : '-', style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w300, fontSize: 16)),
                    ),
                    _buildPointBox(whitePts, wWin, false, isDark),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (wTeam.isNotEmpty) Text(wTeam, style: TextStyle(fontSize: 9, color: Colors.grey.shade500), overflow: TextOverflow.ellipsis),
                          Text(wName, style: TextStyle(fontWeight: wWin ? FontWeight.w900 : FontWeight.bold, color: wWin ? Colors.red.shade700 : textColor), overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              );

              // 🌟 修正：警告表示の条件とダイアログ形式の統一
              if (isRowSummary && !hasOwnTeam) {
                return Container(
                  color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.05),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Opacity(opacity: 0.2, child: rowContent), // さらに薄く
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade400, width: 0.5),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)],
                        ),
                        child: Text(
                          '※簡易入力された結果です\n（詳細スコアはありません）',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return rowContent;
            },
          ),
        ],
      ),
    );
  }
}

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
      // 🌟 修正：◯（直径 radius * 2）や△と同等のボリューム感になるよう、サイズを拡大（1.8倍に調整）
      final rect = Rect.fromCenter(center: center, width: radius * 1.8, height: radius * 1.8);
      canvas.drawRect(rect, bgPaint);
      canvas.drawRect(rect, strokePaint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Widget _buildIndivSingle(String tech, bool isFirst, Color color) {
  if (isFirst && tech != '◯' && tech != '反') {
    return Container(
      width: 14, height: 14, alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 0.8)),
      child: Text(tech, style: TextStyle(fontSize: 8, color: color, fontWeight: FontWeight.bold, height: 1.1)),
    );
  }
  return Text(tech, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold, height: 1.1));
}