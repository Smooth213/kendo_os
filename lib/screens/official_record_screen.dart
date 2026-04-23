import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart'; 
import '../models/match_model.dart';
import '../models/score_event.dart';
import '../providers/match_list_provider.dart';
import '../services/pdf_service.dart'; 
// ★ 追加：先ほど作成した勝ち抜き戦の最強描画エンジンを呼び出す
import 'kachinuki_scoreboard_screen.dart'; 
// ★ Phase 7: 権限プロバイダのインポート
import '../providers/permission_provider.dart';

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
                    padding: const EdgeInsets.all(8),
                    itemCount: sortedGroupKeys.length,
                    itemBuilder: (context, index) {
                      final groupName = sortedGroupKeys[index];
                      final matches = groupsMap[groupName]!..sort((a, b) => a.order.compareTo(b.order));
                      
                      if (matches.isNotEmpty && matches.first.isKachinuki) {
                        // ★ 謎の英数字（groupName）をやめ、通常試合と同じようにタイトルを生成する
                        final firstMatch = matches.first;
                        final note = firstMatch.note;
                        final rTeam = firstMatch.redName.contains(':') ? firstMatch.redName.split(':').first.trim() : firstMatch.redName;
                        final wTeam = firstMatch.whiteName.contains(':') ? firstMatch.whiteName.split(':').first.trim() : firstMatch.whiteName;
                        final titleText = note.isNotEmpty ? '勝ち抜き戦：【$note】 $rTeam vs $wTeam' : '勝ち抜き戦：$rTeam vs $wTeam';

                        // ★ 修正：待機中選手の列数も考慮してキャンバスの幅を計算
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
                                // ★ 組み立てたタイトルテキストを使用！
                                child: Text(titleText, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.indigo.shade100 : Colors.indigo.shade900)),
                              ),
                              // ★ 修正：InteractiveViewerをSizedBoxで囲み、高さを固定する（これで真っ白エラーが消滅します！）
                              SizedBox(
                                height: 520, // 親の枠の高さを明示的に確保
                                width: double.infinity,
                                child: InteractiveViewer(
                                  constrained: false,
                                  boundaryMargin: const EdgeInsets.all(40), 
                                  minScale: 0.2,
                                  maxScale: 3.0,
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    color: isDark ? Colors.black : Colors.white, // ★ 修正：キャンバスの背景もダークモード対応
                                    width: canvasWidth < 600 ? 600 : canvasWidth,
                                    height: 480, // キャンバス内の高さ
                                    child: CustomPaint(
                                      painter: KachinukiBracketPainter(matches: matches, isDark: isDark, ref: ref), // ★ 修正：インクの色も反転させる
                                      size: Size.infinite,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      } else {
                        // ★ 修正: isDarkフラグとcardColorをしっかり渡す
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
            child: Text(note.isNotEmpty ? '【$note】 $redTeam vs $whiteTeam' : '$redTeam vs $whiteTeam', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade300 : Colors.grey.shade800)),
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
}