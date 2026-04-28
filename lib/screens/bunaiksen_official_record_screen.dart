import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/match_model.dart';
import '../presentation/provider/match_list_provider.dart';
import '../presentation/provider/bunaiksen_provider.dart';
import '../application/service/pdf_service.dart';
import 'kachinuki_scoreboard_screen.dart'; // 勝ち抜き戦描画用
import '../domain/kendo_rule_engine.dart';
import '../presentation/provider/match_rule_provider.dart';

class BunaiksenOfficialRecordScreen extends ConsumerWidget {
  const BunaiksenOfficialRecordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final viewDate = ref.watch(bunaiksenViewDateProvider);
    final tournamentId = 'bunaiksen_${DateFormat('yyyyMMdd').format(viewDate)}';

    // デザイン定義
    final bgColor = isDark ? Colors.black : const Color(0xFFF2F2F7);
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final bordeaux = const Color(0xFF8B0000);
    final headerTextColor = isDark ? Colors.white : bordeaux;
    
    // 表示対象の日付の試合を取得
    final matches = ref.watch(matchListProvider.select((list) => 
      list.where((m) => m.tournamentId == tournamentId).toList()
    ));

    // カテゴリ（種目）ごとにグループ化（未設定なら「部内戦」）
    final categoryGroups = <String, Map<String, List<MatchModel>>>{};
    for (var m in matches) {
      if (m.groupName == null || m.groupName!.isEmpty) {
        continue;
      }
      final cat = (m.category != null && m.category!.isNotEmpty) ? m.category! : '部内戦';
      categoryGroups.putIfAbsent(cat, () => {});
      categoryGroups[cat]!.putIfAbsent(m.groupName!, () => []).add(m);
    }

    if (categoryGroups.isEmpty) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          foregroundColor: headerTextColor,
          title: const Text('成績一覧', style: TextStyle(fontWeight: FontWeight.bold)),
          elevation: 0,
          centerTitle: true,
        ),
        body: const Center(child: Text('この日の記録データはありません', style: TextStyle(color: Colors.grey))),
      );
    }

    final categories = categoryGroups.keys.toList();

    return DefaultTabController(
      length: categories.length,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          foregroundColor: headerTextColor,
          title: Text('${DateFormat('yyyy/MM/dd').format(viewDate)} 成績', style: const TextStyle(fontWeight: FontWeight.bold)),
          elevation: 0,
          centerTitle: true,
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
            final sortedGroupKeys = groupsMap.keys.toList()..sort();

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
                      Expanded(child: _buildActionButton(context, Icons.print, 'PDF印刷', Colors.grey.shade800, () => _handleExport(context, cat, groupsMap, sortedGroupKeys, isPdf: true))),
                      const SizedBox(width: 12),
                      Expanded(child: _buildActionButton(context, Icons.share, '画像シェア', Colors.teal.shade600, () => _handleExport(context, cat, groupsMap, sortedGroupKeys, isPdf: false))),
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
                      final bouts = groupsMap[groupName]!..sort((a, b) => a.order.compareTo(b.order));
                      
                      // 1. 勝ち抜き戦の描画
                      if (bouts.isNotEmpty && bouts.first.isKachinuki) {
                        return _buildKachinukiCard(context, ref, bouts, isDark);
                      }
                      
                      // 2. リーグ戦の描画
                      if (bouts.isNotEmpty && bouts.any((m) => m.note.contains('[リーグ戦]'))) {
                        return _buildLeagueSection(context, ref, groupName, bouts, cardColor, isDark);
                      }

                      // 3. 通常の団体戦・個人戦の描画
                      return _buildScoreTable(groupName, bouts, cardColor: cardColor, isDark: isDark);
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

  // --- ヘルパーWidget ---

  Widget _buildActionButton(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 12), elevation: 0),
    );
  }

  // ★ 勝ち抜き戦カードの描画（公式仕様）
  Widget _buildKachinukiCard(BuildContext context, WidgetRef ref, List<MatchModel> matches, bool isDark) {
    final first = matches.first;
    final rTeam = first.redName.split(':').first.trim();
    final wTeam = first.whiteName.split(':').first.trim();
    final canvasWidth = 60.0 + ((matches.length + 5) * 60.0);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade300)),
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
                painter: KachinukiBracketPainter(matches: matches, isDark: isDark, ref: ref),
                size: Size.infinite,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ★ リーグ戦セクションの描画（公式仕様）
  Widget _buildLeagueSection(BuildContext context, WidgetRef ref, String groupName, List<MatchModel> matches, Color cardColor, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _buildLeagueGridTable(context, groupName, matches, cardColor: cardColor, isDark: isDark, ref: ref),
        const SizedBox(height: 16),
        ..._groupMatchesByMatchup(matches).entries.map((e) => _buildScoreTable(e.key, e.value, cardColor: cardColor, isDark: isDark)),
      ],
    );
  }

  // --- 公式記録テーブルエンジン一式 (OfficialRecordScreenから移植) ---

  Widget _buildScoreTable(String groupName, List<MatchModel> matches, {Color? cardColor, bool isDark = false}) {
    final note = matches.first.note;
    final cleanNote = note.replaceAll('[', '').replaceAll(']', '').trim();

    // ★ 修正1：ヘッダー用の名前と、表の横ラベル用の名前を分離する
    final bool isLeague = matches.any((m) => m.note.contains('[リーグ戦]'));
    final bool isIndividual = matches.length == 1 && (matches.first.matchType == '個人戦' || matches.first.matchType == 'individual');

    // ヘッダー用（個人戦・リーグ戦なら選手名、それ以外はチーム名）
    String headerRed, headerWhite;
    if (isIndividual || isLeague) {
      headerRed = matches.first.redName.contains(':') ? matches.first.redName.split(':').last.trim() : matches.first.redName;
      headerWhite = matches.first.whiteName.contains(':') ? matches.first.whiteName.split(':').last.trim() : matches.first.whiteName;
    } else {
      headerRed = matches.first.redName.split(':').first.trim();
      headerWhite = matches.first.whiteName.split(':').first.trim();
    }

    // ★ 修正2：表の横ラベル（チーム名のところ）は、個人戦・リーグ戦・団体戦問わず「赤」「白」に固定
    String sideLabelRed = '赤';
    String sideLabelWhite = '白';

    final borderColor = isDark ? const Color(0xFF38383A) : Colors.grey.shade300;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: borderColor)),
      clipBehavior: Clip.antiAlias,
      child: Column(
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
                  ...matches.map((m) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(m.matchType, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))
                    )
                  )),
                  const Center(child: Padding(padding: EdgeInsets.all(8), child: Text('勝/本', style: TextStyle(fontSize: 10)))),
                ],
              ),
              // ★ sideLabelRed ("赤") を使用
              _buildTeamRow(matches, true, sideLabelRed, isDark),
              TableRow(children: [
                const SizedBox.shrink(),
                ...matches.map((m) => _scoreCell(m, isDark)),
                _summaryCell(matches, true, isDark),
              ]),
              // ★ sideLabelWhite ("白") を使用
              _buildTeamRow(matches, false, sideLabelWhite, isDark),
            ],
          ),
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
        return Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: _buildVerticalName(cleanName, '', isDark)));
      }),
      _summaryCell(matches, isRed, isDark),
    ]);
  }

  Widget _scoreCell(MatchModel m, bool isDark) {
    final isDone = m.status == 'finished' || m.status == 'approved';
    final rScore = (m.redScore as num).toInt();
    final wScore = (m.whiteScore as num).toInt();
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white; // 背景色取得
    
    // イベントから技を抽出（公式表示用）
    List<String> redPts = _extractMarks(m.events, true);
    List<String> whitePts = _extractMarks(m.events, false);

    return Container(
      height: 70, alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 中央の横線
          Divider(color: isDark ? Colors.white10 : Colors.grey.shade300, thickness: 1, height: 0),
          
          // ★ 修正2：引き分け（分）の時に真ん中に表示する「✕」を太く大きく変更
          if (isDone && rScore == wScore)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              color: cardColor, 
              child: Text(
                '✕', 
                style: TextStyle(
                  fontSize: 16, // サイズアップ
                  fontWeight: FontWeight.w900, // 極太に変更
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade500
                )
              ),
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

  // 公式記録風の技マークボックス（丸囲み等）
  Widget _buildPointBox(List<String> pts, bool isWinner, bool isRed, bool isDark) {
    final color = isRed ? Colors.red.shade700 : Colors.blue.shade700;
    return SizedBox(
      width: 36, height: 36,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isWinner) Container(width: 32, height: 32, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5))),
          if (pts.isNotEmpty) Positioned(top: 4, left: 6, child: _renderMark(pts[0], color, true)),
          if (pts.length > 1) Positioned(bottom: 4, right: 6, child: _renderMark(pts[1], color, false)),
        ],
      ),
    );
  }

  Widget _renderMark(String mark, Color color, bool isFirst) {
    // ★ 修正：コンテナでの枠線描画を廃止し、丸文字化されたテキストだけを美しく表示する
    return Text(mark, style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.bold, height: 1.1));
  }

  // --- 共通ロジック & ヘルパー ---

  List<String> _extractMarks(List<dynamic>? events, bool isRed) {
    if (events == null) return [];
    List<String> res = [];
    bool isFirst = true; // ★ 試合全体の先取を管理
    for (var e in events) {
      String s = e.toString().toLowerCase();
      if (s.contains('iscanceled: true') || s.contains('undo')) continue;
      bool eventIsRed = s.contains('red') || s.contains('赤');
      
      String mark = '';
      if (s.contains('men') || s.contains('メ')) {
        mark = 'メ';
      } else if (s.contains('kote') || s.contains('コ')) {
        mark = 'コ';
      } else if (s.contains('do') || s.contains('ド')) {
        mark = 'ド';
      } else if (s.contains('tsuki') || s.contains('ツ')) {
        mark = 'ツ';
      } else if (s.contains('hansoku') || s.contains('反')) {
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
        if (eventIsRed == isRed) {
          res.add(mark);
        }
        isFirst = false; // 1本目以降は文字だけにする
      }
    }
    return res;
  }

  Widget _buildVerticalName(String text, String initial, bool isDark) {
    final style = TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade400 : Colors.grey.shade800);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: text.split('').map((char) => Text(char, style: style.copyWith(height: 1.1))).toList(),
    );
  }

  Widget _summaryCell(List<MatchModel> ms, bool isRed, bool isDark) {
    int wins = 0, pts = 0;
    for (var m in ms) {
      final r = (m.redScore as num).toInt(); final w = (m.whiteScore as num).toInt();
      pts += isRed ? r : w;
      if (isRed && r > w) {
        wins++;
      } else if (!isRed && w > r) {
        wins++;
      }
    }
    return Center(child: Text('$wins\n$pts', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center));
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

  // ★ 究極版：リーグ戦グリッド描画（公式の自動計算付きフルスペック版）
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

              // ★ 追加：勝=3、分=1、負=0 で「勝ち点」をこの画面独自に強制計算する
              int customTeamPoints = 0;
              for (var colTeam in teamList) {
                if (rowTeam == colTeam) continue;
                final bouts = normalMatches.where((m) {
                  final r = m.redName.split(':').first.trim();
                  final w = m.whiteName.split(':').first.trim();
                  return (r == rowTeam && w == colTeam) || (r == colTeam && w == rowTeam);
                }).toList();
                
                // 試合が終わっていない場合は計算しない
                if (bouts.isEmpty || !bouts.every((m) => m.status == 'approved' || m.status == 'finished')) continue;
                
                int rWins = 0, cWins = 0;
                for (var m in bouts) {
                  final isRowRed = m.redName.split(':').first.trim() == rowTeam;
                  final rs = (m.redScore as num).toInt(); final ws = (m.whiteScore as num).toInt();
                  if (rs > ws) { isRowRed ? rWins++ : cWins++; }
                  else if (ws > rs) { isRowRed ? cWins++ : rWins++; }
                }
                
                // 勝ち点の付与ルール（勝：3、分：1、負：0）
                if (rWins > cWins) {
                  customTeamPoints += 3; 
                } else if (rWins == cWins) {
                  customTeamPoints += 1; 
                }
              }

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

                    return Container(
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
                    );
                  }),
                  _buildStatCell('${stat.matchWins}', isDark),
                  _buildStatCell('${stat.individualWinners}', isDark),
                  _buildStatCell('${stat.totalPointsScored}', isDark),
                  // ★ 修正：システム計算の stat.customPoints ではなく、上で計算した customTeamPoints を表示する
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

  // エクスポート処理
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

// =========================================================================
// ★ リーグ戦星取表用の専用ペインター＆ヘルパー群
// =========================================================================

// 自分自身との交差セルに斜め線を引く
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

// ★ ◯（勝ち）・△（負け）・✕（引き分け）を描画する究極のペインター
class ResultShapePainter extends CustomPainter {
  final String result; // 'win', 'loss', 'draw'
  final Color color;
  ResultShapePainter({required this.result, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = color.withValues(alpha: 0.1)..style = PaintingStyle.fill;
    final strokePaint = Paint()..color = color..strokeWidth = 1.5..style = PaintingStyle.stroke;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.42;

    if (result == 'win') { // ◯ 勝ち
      canvas.drawCircle(center, radius, bgPaint);
      canvas.drawCircle(center, radius, strokePaint);
    } else if (result == 'loss') { // △ 負け
      final path = Path();
      path.moveTo(center.dx, center.dy - radius);
      path.lineTo(center.dx + radius * 1.1, center.dy + radius * 0.8);
      path.lineTo(center.dx - radius * 1.1, center.dy + radius * 0.8);
      path.close();
      canvas.drawPath(path, bgPaint);
      canvas.drawPath(path, strokePaint);
    } else { // □ 引き分け（星取り表）
      final double d = radius * 0.6; // □のサイズ調整
      final rect = Rect.fromCenter(center: center, width: d * 2, height: d * 2);
      canvas.drawRect(rect, bgPaint);
      canvas.drawRect(rect, strokePaint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 1本目だけ丸囲みする個人戦用ヘルパー
Widget _buildIndivSingle(String tech, bool isFirst, Color color) {
  // ★ 修正：コンテナを使わず文字だけで表示
  return Text(tech, style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.bold, height: 1.1));
}

// ログから技（メ・コ・ド・ツ・反）を抽出するヘルパー
List<String> _extractTechs(List<dynamic> logs, bool isRed, int count) {
  List<String> res = [];
  bool isFirst = true; // ★ 試合全体の先取を管理
  for (var log in logs) {
    String s = log.toString().toLowerCase();
    if (s.contains('undo') || s.contains('iscanceled: true')) continue;
    bool isRedPoint = s.contains('red') || s.contains('赤');
    
    String mark = '';
    if (s.contains('men') || s.contains('メ')) {
      mark = 'メ';
    } else if (s.contains('kote') || s.contains('コ')) {
      mark = 'コ';
    } else if (s.contains('do') || s.contains('ド')) {
      mark = 'ド';
    } else if (s.contains('tsuki') || s.contains('ツ')) {
      mark = 'ツ';
    } else if (s.contains('hansoku') || s.contains('反')) {
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
      if (isRed == isRedPoint) {
        res.add(mark);
      }
      isFirst = false;
    }
  }
  while (res.length < count) {
    res.add('◯');
  }
  return res.take(count).toList();
}