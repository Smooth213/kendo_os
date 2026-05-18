import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/domain/entities/match_model.dart';
import 'package:kendo_os/application/services/pdf_service.dart';
import '../../operate/screens/kachinuki_scoreboard_screen.dart';
import 'package:kendo_os/domain/services/kendo_rule_engine.dart';
import '../../operate/providers/match_rule_provider.dart';
import 'package:kendo_os/domain/services/bunaiksen_helper.dart';
import 'package:kendo_os/application/mappers/match_projection_mapper.dart';
import 'package:kendo_os/domain/entities/score_event.dart';
import '../../shared/widgets/liquid_background.dart';
import '../../operate/providers/settings_provider.dart';
import '../../operate/providers/match_view_model_provider.dart';
import '../painters/league_table_painters.dart';

class OfficialPointDisplay {
  final String mark;
  final bool isFirstMatchPoint;
  OfficialPointDisplay(this.mark, this.isFirstMatchPoint);
}

class ViewerBunaiksenOfficialRecordScreen extends ConsumerWidget {
  final String tournamentId;

  const ViewerBunaiksenOfficialRecordScreen({super.key, required this.tournamentId});

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

    // デザイン定義
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final bordeaux = const Color(0xFF8B0000);
    final headerTextColor = isDark ? Colors.white : bordeaux;

    final categoryGroups = ref.watch(bunaiksenRecordCategoryGroupsProvider(tournamentId));

    if (categoryGroups.isEmpty) {
      return LiquidBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: enableLiquidGlass ? Colors.transparent : cardColor,
            foregroundColor: headerTextColor,
            title: const Text('成績一覧 (観戦)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            elevation: 0,
            centerTitle: true,
            leading: GoRouter.of(context).canPop() 
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                    onPressed: () => context.pop(),
                  )
                : null,
          ),
          body: const Center(child: Text('この日の記録データはありません', style: TextStyle(color: Colors.grey))),
        ),
      );
    }

    final categories = categoryGroups.keys.toList();

    return PopScope(
      canPop: false,
      child: DefaultTabController(
        length: categories.length,
        child: LiquidBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: enableLiquidGlass ? Colors.transparent : cardColor,
              foregroundColor: headerTextColor,
              title: Text('$dateDisplay 成績 (観戦)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              elevation: 0,
              centerTitle: true,
              leading: GoRouter.of(context).canPop() 
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                      onPressed: () => context.pop(),
                    )
                  : null,
              bottom: TabBar(
                isScrollable: true,
                labelColor: headerTextColor,
                unselectedLabelColor: Colors.grey,
                indicatorColor: bordeaux,
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
                  
                  if (isIndiv && !isLeague && (uuidRegex.hasMatch(key) || key.length > 20)) {
                    individualMergedList.addAll(matches);
                  } else {
                    mergedGroups[key] = matches;
                  }
                });

                if (individualMergedList.isNotEmpty) {
                  mergedGroups['__merged_individual__'] = individualMergedList;
                }

                final sortedGroupKeys = mergedGroups.keys.toList()..sort();

                return Column(
                  children: [
                    // 共有・印刷アクションバー
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: cardColor,
                        border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF38383A) : Colors.grey.shade200)),
                      ),
                      child: Row(
                        children: [
                          Expanded(child: _buildActionButton(context, Icons.print, 'PDF印刷', Colors.grey.shade800, () => _handleExport(context, cat, mergedGroups, sortedGroupKeys, isPdf: true))),
                          const SizedBox(width: 12),
                          Expanded(child: _buildActionButton(context, Icons.share, '画像シェア', Colors.teal.shade600, () => _handleExport(context, cat, mergedGroups, sortedGroupKeys, isPdf: false))),
                        ],
                      ),
                    ),
                    // 記録コンテンツ
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: sortedGroupKeys.length,
                        itemBuilder: (context, index) {
                          final groupName = sortedGroupKeys[index];
                          final bouts = mergedGroups[groupName]!..sort((a, b) => a.order.compareTo(b.order));
                          
                          if (bouts.isNotEmpty && bouts.first.isKachinuki) {
                            return _buildKachinukiCard(context, ref, bouts, isDark);
                          }
                          
                          if (bouts.isNotEmpty && bouts.any((m) => m.note.contains('[リーグ戦]'))) {
                            return _buildLeagueSection(context, ref, groupName, bouts, cardColor, isDark);
                          }

                          if (bouts.isNotEmpty && bouts.any((m) => m.matchType == 'individual' || m.matchType == '選手' || m.matchType.contains('個人戦'))) {
                            return _buildIndividualMatchesList(groupName, bouts, cardColor: cardColor, isDark: isDark);
                          } else {
                            return _buildScoreTable(groupName, bouts, cardColor: cardColor, isDark: isDark);
                          }
                        },
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  // --- ヘルパーWidget ---

  Widget _buildActionButton(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 12), elevation: 0),
    );
  }

  Widget _buildKachinukiCard(BuildContext context, WidgetRef ref, List<MatchModel> matches, bool isDark) {
    final first = matches.first;
    final rTeam = first.redName.split(':').first.trim();
    final wTeam = first.whiteName.split(':').first.trim();
    final canvasWidth = 60.0 + ((matches.length + 5) * 60.0);

    final engine = KendoRuleEngine();
    final projections = matches.map((m) {
      final analysis = engine.analyzeHistory(m.events, m, m.rule);
      return MatchProjectionMapper.toProjection(m, analysis);
    }).toList();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade300)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: isDark ? Colors.indigo.shade900.withValues(alpha: 0.4) : Colors.indigo.shade50,
            width: double.infinity,
            child: Text('勝ち抜き戦：$rTeam vs $wTeam', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.indigo.shade100 : Colors.indigo.shade900)),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              padding: const EdgeInsets.all(16),
              width: canvasWidth,
              height: 480,
              child: CustomPaint(
                painter: KachinukiBracketPainter(matches: projections, isDark: isDark, ref: ref),
                size: Size.infinite,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeagueSection(BuildContext context, WidgetRef ref, String groupName, List<MatchModel> matches, Color cardColor, bool isDark) {
    final isIndiv = matches.any((m) => 
      m.matchType == 'individual' || m.matchType == '選手' || m.matchType.contains('個人戦') ||
      (!m.redName.contains(':') && !m.whiteName.contains(':')) 
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _buildLeagueGridTable(context, groupName, matches, cardColor: cardColor, isDark: isDark, ref: ref),
        const SizedBox(height: 16),
        ..._groupMatchesByMatchup(matches).entries.map((e) {
          return isIndiv
              ? _buildIndividualMatchesList(e.key, e.value, cardColor: cardColor, isDark: isDark)
              : _buildScoreTable(e.key, e.value, cardColor: cardColor, isDark: isDark);
        }),
      ],
    );
  }

  Widget _buildScoreTable(String groupName, List<MatchModel> matches, {Color? cardColor, bool isDark = false}) {
    final note = matches.first.note;
    final cleanNote = note.replaceAll('[', '').replaceAll(']', '').trim();

    final bool isLeague = matches.any((m) => m.note.contains('[リーグ戦]'));
    final bool isIndividual = matches.length == 1 && (matches.first.matchType == '個人戦' || matches.first.matchType == 'individual');

    String headerRed, headerWhite;
    if (isIndividual || isLeague) {
      headerRed = matches.first.redName.contains(':') ? matches.first.redName.split(':').last.trim() : matches.first.redName;
      headerWhite = matches.first.whiteName.contains(':') ? matches.first.whiteName.split(':').last.trim() : matches.first.whiteName;
    } else {
      headerRed = matches.first.redName.split(':').first.trim();
      headerWhite = matches.first.whiteName.split(':').first.trim();
    }

    String sideLabelRed = '赤';
    String sideLabelWhite = '白';

    final borderColor = isDark ? const Color(0xFF38383A) : Colors.grey.shade300;
    final headerTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade700;
    final daihyoBgColor = isDark ? Colors.red.shade900.withValues(alpha: 0.15) : Colors.red.shade50;

    bool allFinished = matches.every((m) {
      final hasScore = (m.redScore as num).toInt() > 0 || (m.whiteScore as num).toInt() > 0;
      final isOfficial = m.status == 'approved' || m.status == 'finished';
      return isOfficial || hasScore;
    });

    String teamWinner = 'draw';
    int rWins = 0, wWins = 0, rPts = 0, wPts = 0;
    MatchModel? daihyoMatch;

    for (var m in matches) {
      if (m.matchType == '代表戦') {
        daihyoMatch = m;
        continue; 
      }
      final rs = (m.redScore as num).toInt();
      final ws = (m.whiteScore as num).toInt();
      rPts += rs; wPts += ws;
      if (rs > ws) {
        rWins++;
      } else if (ws > rs) {
        wWins++;
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: borderColor)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                color: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade100,
                width: double.infinity,
                child: Text(
                  cleanNote.isNotEmpty ? '【$cleanNote】 $headerRed vs $headerWhite' : '$headerRed vs $headerWhite',
                  style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade300 : Colors.grey.shade800),
                ),
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
                    decoration: BoxDecoration(color: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade50),
                    children: [
                      const SizedBox.shrink(),
                      ...matches.map((m) => Container(
                        color: m.matchType == '代表戦' ? daihyoBgColor : Colors.transparent,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(m.matchType, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: m.matchType == '代表戦' ? (isDark ? Colors.red.shade400 : Colors.red.shade900) : (isDark ? Colors.grey.shade300 : Colors.grey.shade800)))
                          )
                        )
                      )),
                      Center(child: Padding(padding: const EdgeInsets.all(8), child: Text('勝/本', style: TextStyle(fontSize: 10, color: headerTextColor)))),
                    ],
                  ),
                  _buildTeamRow(matches, true, sideLabelRed, isDark),
                  TableRow(children: [
                    const SizedBox.shrink(),
                    ...matches.map((m) => _scoreCell(m, isDark, isSummary)),
                    _teamResultCell(teamWinner, isDark, allFinished),
                  ]),
                  _buildTeamRow(matches, false, sideLabelWhite, isDark),
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
                  Expanded(child: Center(child: Text(winner == 'white' ? '勝' : '負', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: winner == 'white' ? Colors.blue.shade600 : textColor)))),
                ],
              ),
          ]
        ],
      ),
    );
  }

  TableRow _buildTeamRow(List<MatchModel> matches, bool isRed, String teamName, bool isDark) {
    return TableRow(children: [
      Center(child: Padding(padding: const EdgeInsets.all(8), child: Text(teamName, style: TextStyle(color: isRed ? Colors.red.shade700 : Colors.blue.shade700, fontWeight: FontWeight.bold, fontSize: 11)))),
      ...matches.map((m) {
        final name = isRed ? m.redName : m.whiteName;
        final cleanName = name.contains(':') ? name.split(':').last.trim() : name;
        final isDaihyo = m.matchType == '代表戦';
        return Container(
          color: isDaihyo ? (isDark ? Colors.red.shade900.withValues(alpha: 0.15) : Colors.red.shade50) : Colors.transparent,
          child: Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: _buildVerticalName(cleanName, '', isDark)))
        );
      }),
      _summaryCell(matches, isRed, isDark),
    ]);
  }

  Widget _scoreCell(MatchModel m, bool isDark, bool isSummary) {
    if (isSummary) {
      return Container(height: 70, color: Colors.transparent);
    }
    final isDone = m.status == 'finished' || m.status == 'approved';
    final rScore = (m.redScore as num).toInt();
    final wScore = (m.whiteScore as num).toInt();
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white; 
    
    final engine = KendoRuleEngine();
    final analysis = engine.analyzeHistory(m.events, m, m.rule);
    
    final redPts = (analysis.displays[Side.red] ?? [])
        .map((d) => OfficialPointDisplay(d.mark, d.isFirstMatchPoint))
        .toList();
    final whitePts = (analysis.displays[Side.white] ?? [])
        .map((d) => OfficialPointDisplay(d.mark, d.isFirstMatchPoint))
        .toList();

    return Container(
      height: 70, alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Divider(color: isDark ? Colors.white10 : Colors.grey.shade300, thickness: 1, height: 0),
          if (isDone && rScore == wScore)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              color: cardColor, 
              child: Text('✕', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: isDark ? Colors.grey.shade500 : Colors.grey.shade500)),
            ),
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
          if (pts.isNotEmpty) Positioned(top: 4, left: 6, child: _renderMark(pts[0], color)),
          if (pts.length > 1) Positioned(bottom: 4, right: 6, child: _renderMark(pts[1], color)),
        ],
      ),
    );
  }

  Widget _renderMark(OfficialPointDisplay p, Color color) {
    String displayMark = p.mark == '判定' ? '判' : p.mark;
    if (p.isFirstMatchPoint && displayMark != '反') {
      return Container(
        width: 14, height: 14, alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 0.8)),
        child: Text(displayMark, style: TextStyle(fontSize: 8, color: color, fontWeight: FontWeight.bold, height: 1.1)),
      );
    }
    return Text(displayMark, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold, height: 1.1));
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

  Widget _summaryCell(List<MatchModel> ms, bool isRed, bool isDark) {
    int wins = 0, pts = 0;
    for (var m in ms) {
      if (m.matchType == '代表戦') continue;
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

  Map<String, List<MatchModel>> _groupMatchesByMatchup(List<MatchModel> matches) {
    final Map<String, List<MatchModel>> res = {};
    for (var m in matches) {
      final t1 = m.redName.split(':').first.trim();
      final t2 = m.whiteName.split(':').first.trim();
      final key = '$t1 vs $t2';
      res.putIfAbsent(key, () => []).add(m);
    }
    return res;
  }

  Widget _buildLeagueGridTable(BuildContext context, String groupName, List<MatchModel> matches, {Color? cardColor, required bool isDark, required WidgetRef ref}) {
    final normalMatches = matches.where((m) => !m.note.contains('[順位決定戦]')).toList();
    if (normalMatches.isEmpty) return const SizedBox();

    final rule = normalMatches.first.rule ?? ref.read(matchRuleProvider);
    final nonNullRule = rule!;
    final stats = KendoRuleEngine.calculateLeagueStandings(normalMatches, nonNullRule);
    
    final isIndiv = normalMatches.any((m) => 
      m.matchType == 'individual' || m.matchType == '選手' || m.matchType.contains('個人戦') ||
      (!m.redName.contains(':') && !m.whiteName.contains(':'))
    );
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

              int customTeamPoints = BunaiksenHelper.calculateCustomLeaguePoints(rowTeam, teamList, normalMatches);

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
                    
                    if (bouts.isEmpty) {
                      return const SizedBox(height: 65);
                    }
                    
                    int rWins = 0, cWins = 0, rPoints = 0, cPoints = 0, rWinners = 0, cWinners = 0;
                    List<String> techs = [];
                    for (var m in bouts) {
                      final isRowRed = m.redName.split(':').first.trim() == rowTeam;
                      final rs = (m.redScore as num).toInt(); final ws = (m.whiteScore as num).toInt();
                      if (rs > ws) { isRowRed ? rWins++ : cWins++; isRowRed ? rWinners++ : cWinners++; }
                      else if (ws > rs) { isRowRed ? cWins++ : rWins++; isRowRed ? cWinners++ : rWinners++; }
                      isRowRed ? rPoints += rs : cPoints += rs; isRowRed ? cPoints += ws : rPoints += ws;
                      if (isIndiv) {
                        final engine = KendoRuleEngine();
                        final analysis = engine.analyzeHistory(m.events, m, m.rule);
                        final displays = isRowRed ? analysis.displays[Side.red] : analysis.displays[Side.white];
                        List<String> extracted = displays?.map((d) => d.mark).toList() ?? [];
                        
                        final bool isSummary = m.note.contains('[SUMMARY]');
                        if (isSummary || extracted.isEmpty) {
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
                    
                    if (!bouts.every((m) {
                      final hasScore = (m.redScore as num).toInt() > 0 || (m.whiteScore as num).toInt() > 0;
                      final isOfficial = m.status == 'approved' || m.status == 'finished';
                      return isOfficial || hasScore;
                    })) {
                      return const SizedBox(height: 65);
                    }
                    
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
                                          ? _buildIndividualMatchesList('$rowTeam vs $colTeam', bouts, cardColor: Colors.transparent, isDark: isDark)
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
                                  techs.isNotEmpty ? buildIndivSingle(techs[0], true, textColor) : const SizedBox(height: 12),
                                  Container(height: 0.5, width: 18, color: textColor.withValues(alpha: 0.5), margin: const EdgeInsets.symmetric(vertical: 2)),
                                  techs.length > 1 ? buildIndivSingle(techs[1], false, textColor) : const SizedBox(height: 12),
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
                  }),
                  _buildStatCell('${stat.matchWins}', isDark),
                  _buildStatCell('${stat.individualWinners}', isDark),
                  _buildStatCell('${stat.totalPointsScored}', isDark),
                  if (hasMatchPoints) _buildStatCell('$customTeamPoints', isDark),
                  _buildStatCell(rankStr, isDark, isRank: true),
                ]
              );
            }),
          ],
        ),
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

  Widget _buildIndividualMatchesList(String groupName, List<MatchModel> matches, {Color? cardColor, required bool isDark}) {
    final borderColor = isDark ? const Color(0xFF38383A) : Colors.grey.shade300;
    final headerBgColor = isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade50;
    final textColor = isDark ? Colors.white : Colors.black87;

    final uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
    String displayGroupName = groupName;
    if (uuidRegex.hasMatch(groupName) || groupName.length > 20 || groupName == '__default__') {
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: borderColor)),
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
            itemCount: matches.length,
            separatorBuilder: (context, index) => Divider(color: borderColor, height: 1, indent: 16, endIndent: 16),
            itemBuilder: (context, index) {
              final m = matches[index];
              final rName = m.redName.contains(':') ? m.redName.split(':').last.replaceAll(')', '').trim() : m.redName;
              final wName = m.whiteName.contains(':') ? m.whiteName.split(':').last.replaceAll(')', '').trim() : m.whiteName;
              final rTeam = m.redName.contains(':') ? m.redName.split(':').first.trim() : '';
              final wTeam = m.whiteName.contains(':') ? m.whiteName.split(':').first.trim() : '';

              final isDone = m.status == 'finished' || m.status == 'approved' || (m.redScore as num).toInt() > 0 || (m.whiteScore as num).toInt() > 0;
              final rScore = (m.redScore as num).toInt();
              final wScore = (m.whiteScore as num).toInt();
              final isDraw = isDone && rScore == wScore;
              final rWin = isDone && rScore > wScore;
              final wWin = isDone && wScore > rScore;

              final engine = KendoRuleEngine();
              final analysis = engine.analyzeHistory(m.events, m, m.rule);
              
              final redPts = (analysis.displays[Side.red] ?? [])
                  .map((d) => OfficialPointDisplay(d.mark, d.isFirstMatchPoint))
                  .toList();
              final whitePts = (analysis.displays[Side.white] ?? [])
                  .map((d) => OfficialPointDisplay(d.mark, d.isFirstMatchPoint))
                  .toList();

              return Padding(
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
            },
          ),
        ],
      ),
    );
  }

  Future<void> _handleExport(BuildContext context, String cat, Map<String, List<MatchModel>> groupsMap, List<String> sortedGroupKeys, {required bool isPdf}) async {
    final groupDataList = sortedGroupKeys.map((key) => { 'groupName': key, 'matches': groupsMap[key]!..sort((a, b) => a.order.compareTo(b.order)) }).toList();
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    try {
      if (isPdf) {
        await PdfService.printOfficialRecord(cat, groupDataList);
      } else {
        await PdfService.shareOfficialRecordAsImage(cat, groupDataList);
      }
    } finally {
      if (context.mounted) {
        Navigator.pop(context);
      }
    }
  }
}