import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/match_model.dart';
import '../domain/match/score_event.dart';
import '../presentation/provider/match_command_provider.dart';
import '../presentation/provider/match_list_provider.dart';
import '../presentation/provider/match_rule_provider.dart'; // ★ 追加：レギュレーション確認用

class TeamPointDisplay {
  final String mark;
  final bool isFirstMatchPoint;
  TeamPointDisplay(this.mark, this.isFirstMatchPoint);
}

class TeamScoreboardScreen extends ConsumerWidget {
  final String? groupName; 
  final List<MatchModel>? matches; // ★ 追加：特定の試合リストを直接受け取れるようにする

  const TeamScoreboardScreen({super.key, this.groupName, this.matches});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ★ 修正：matches が直接渡されている場合はそれを使用し、なければ groupName で監視する
    List<MatchModel> teamMatches = matches ?? [];
    
    if (matches == null && groupName != null) {
      teamMatches = ref.watch(matchListProvider.select((list) => 
        list.where((m) => m.groupName == groupName).toList()
      ));
    }
    
    // ★ 修正：今設定中のルールではなく、その試合自体が持っている「保存されたルール」を最優先で使う
    final rule = (teamMatches.isNotEmpty && teamMatches.first.rule != null) 
        ? teamMatches.first.rule! 
        : ref.watch(matchRuleProvider);
    
    teamMatches.sort((a, b) => a.order.compareTo(b.order));

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : const Color(0xFFF2F2F7);
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final headerColor = isDark ? Colors.white : Colors.indigo.shade900;
    final borderColor = isDark ? const Color(0xFF38383A) : Colors.grey.shade200;

    if (teamMatches.isEmpty) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: headerColor, size: 20),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
          ),
          title: Text('スコアボード', style: TextStyle(fontWeight: FontWeight.bold, color: headerColor, fontSize: 16)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(child: Text('データなし', style: TextStyle(color: isDark ? Colors.white : Colors.black))),
      );
    }

    final redTeam = _cleanName(teamMatches.first.redName, true);
    final whiteTeam = _cleanName(teamMatches.first.whiteName, true);

    // ★ Phase 8: 試合詳細（メモ）を取得
    final matchNote = teamMatches.first.note;

    int rW = 0, wW = 0, rP = 0, wP = 0;
    bool allFinished = true;
    bool hasDaihyo = false;

    for (var m in teamMatches) {
      if (m.matchType == '代表戦') {
        hasDaihyo = true;
      }
      if (m.status != 'approved' && m.status != 'finished') {
        allFinished = false;
      }
      if (m.status == 'approved' || m.status == 'finished') {
        rP += (m.redScore as num).toInt();
        wP += (m.whiteScore as num).toInt();
        if ((m.redScore as num) > (m.whiteScore as num)) {
          rW++;
        } else if ((m.whiteScore as num) > (m.redScore as num)) {
          wW++;
        }
      }
    }

    bool isTie = allFinished && !hasDaihyo && (rW == wW) && (rP == wP);
    // ★ 修正：古いデータでも「[リーグ戦]」という文字があればリーグ戦として扱い、代表戦ボタンを隠す
    final bool isLegacyLeague = teamMatches.isNotEmpty && teamMatches.first.note.contains('[リーグ戦]');
    final bool isLeague = rule.isLeague || isLegacyLeague;
    
    // リーグ戦なら hasLeagueDaihyo を、そうでなければ通常の代表戦フラグを見る
    // ただし、古いリーグ戦データ（ruleがnull）の場合は、安全のため「なし」とみなす
    bool isDaihyoAllowed = isLeague 
        ? (rule.isLeague ? rule.hasLeagueDaihyo : false) 
        : rule.hasRepresentativeMatch;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: headerColor, size: 20),
          // ★ 真の解決: 履歴が消えている場合に備え、安全にpopまたはホームへ戻るフェイルセーフを実装
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else if (teamMatches.isNotEmpty && teamMatches.first.tournamentId != null) {
              context.go('/home/${teamMatches.first.tournamentId}');
            } else {
              context.go('/');
            }
          },
        ),
        title: Text('団体戦 スコアボード', style: TextStyle(fontWeight: FontWeight.bold, color: headerColor, fontSize: 16)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      // ★ 修正：星取表のみをスクロール領域にする（ボタンはここに入れない！）
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ★ Phase 8: 試合詳細（1回戦 第3試合など）を強調表示
            if (matchNote.isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.indigo.shade900.withValues(alpha: 0.2) : Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? Colors.indigo.shade800 : Colors.indigo.shade100),
                ),
                child: Row(
                  children: [
                    // ★ 修正：誤認防止のためアイコンと余白を削除
                    Expanded(
                      child: Text(
                        matchNote,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.indigo.shade100 : Colors.indigo.shade900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: isDark ? null : Border.all(color: borderColor, width: 1.0),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Table(
                    border: TableBorder.symmetric(inside: BorderSide(color: borderColor, width: 0.5)),
                    columnWidths: const {
                      0: FlexColumnWidth(1.2), 1: FlexColumnWidth(2.0), 2: FlexColumnWidth(1.2),
                      3: FlexColumnWidth(1.2), 4: FlexColumnWidth(2.0),
                    },
                    children: [
                      _buildHeaderRow(redTeam, whiteTeam, isDark),
                      // ★ 修正：チーム内の名字の被りを自動判定するためにリストを渡す
                      ...teamMatches.map((m) => _buildMatchRow(
                        m, context, isDark, 
                        teamMatches.map((x) => _parseName(x.redName)['last']!).where((s) => s.isNotEmpty).toList(),
                        teamMatches.map((x) => _parseName(x.whiteName)['last']!).where((s) => s.isNotEmpty).toList()
                      )),
                      // ★ Phase 8-4: 試合がすべて終わるまで勝敗を隠すため allFinished を渡す
                      _buildTotalRow(rW, rP, wW, wP, isDark, allFinished, daihyo: hasDaihyo ? teamMatches.firstWhere((m) => m.matchType == '代表戦') : null),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      // ★ 修正：他の画面と同じように、Scaffoldの機能を使って「画面の最下部（ボトム）」に完全に固定する
      // ★ 修正：先ほど作った正確なフラグ（isDaihyoAllowed）を参照して表示を制御する
      bottomNavigationBar: (isTie && isDaihyoAllowed) ? SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16), // 他の画面のボタンと同じ余白
          child: SizedBox(
            width: double.infinity,
            height: 54, // 他の画面の確定ボタンと同じ高さ
            child: ElevatedButton.icon(
              onPressed: () async {
                final first = teamMatches.first;
                final nextMatchId = 'match_${DateTime.now().millisecondsSinceEpoch}';
                final newMatch = first.copyWith(
                  id: nextMatchId,
                  order: teamMatches.last.order + 1,
                  matchType: '代表戦',
                  redName: '$redTeam : 代表選手',
                  whiteName: '$whiteTeam : 代表選手',
                  status: 'scheduled',
                  redScore: 0, whiteScore: 0, events: const [],
                );
                await ref.read(matchCommandProvider).addMatch(newMatch);

                if (!context.mounted) return;
                
                // ★ 成功したAppleライクなダイアログ
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  barrierColor: Colors.black.withValues(alpha: 0.4),
                  builder: (ctx) => Dialog(
                    backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), shape: BoxShape.circle),
                            child: const Icon(Icons.check, color: Colors.green, size: 36),
                          ),
                          const SizedBox(height: 24),
                          Text('代表戦を追加しました', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: isDark ? Colors.white : Colors.black87)),
                          const SizedBox(height: 8),
                          Text('試合画面へ移動します...', style: TextStyle(fontSize: 14, color: isDark ? Colors.grey.shade400 : Colors.grey.shade500)),
                        ],
                      ),
                    ),
                  ),
                );

                await Future.delayed(const Duration(seconds: 2));

                if (!context.mounted) return;
                Navigator.pop(context); // ダイアログを閉じる
                context.push('/match/$nextMatchId'); // 試合入力画面へ自動遷移
              },
              icon: const Icon(Icons.add_circle, size: 24),
              label: const Text('同点のため、代表戦を追加する', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.red.shade700 : Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ),
        ),
      ) : null,
    );
  }

  // ★ 修正：ヘッダーのチーム名もサイズアップ
  TableRow _buildHeaderRow(String r, String w, bool isDark) {
    final headerBg = isDark ? const Color(0xFF2C2C2E) : Colors.indigo.shade50;
    final textColor = isDark ? Colors.white : Colors.black87;
    return TableRow(
      decoration: BoxDecoration(color: headerBg),
      children: [
        _cell('', isH: true, color: textColor, fs: 12),
        _cell(r, isH: true, color: isDark ? Colors.red.shade300 : Colors.red.shade700, fs: 16), // 13→16
        _cell('赤', isH: true, color: isDark ? Colors.red.shade300 : Colors.red.shade700, fs: 14),
        _cell('白', isH: true, color: isDark ? Colors.grey.shade300 : Colors.blueGrey.shade700, fs: 14),
        _cell(w, isH: true, color: isDark ? Colors.grey.shade300 : Colors.blueGrey.shade700, fs: 16), // 13→16
      ],
    );
  }

  // ★ 追加：名前を名字と名前に分割する魔法のヘルパー
  Map<String, String> _parseName(String raw) {
    if (raw.contains('欠員')) return {'last': '', 'first': ''};
    String clean = raw.contains(':') ? raw.split(':').last.replaceAll(RegExp(r'[()（）]'), '').trim() : raw.trim();
    var parts = clean.split(RegExp(r'\s+'));
    return {'last': parts[0], 'first': parts.length > 1 ? parts[1] : ''};
  }

  // ★ 追加：同姓がいる場合に名前の1文字目を右下に添える専用セル
  Widget _buildNameCell(String rawName, bool isDark, List<String> teamLastNames) {
    final subTextColor = isDark ? const Color(0xFF8E8E93) : Colors.grey.shade600;
    final textColor = isDark ? Colors.white : Colors.black87;

    if (rawName.contains('欠員')) return _cell('(欠員)', fs: 17, color: subTextColor, fontWeight: FontWeight.bold);

    final parsed = _parseName(rawName);
    final count = teamLastNames.where((n) => n == parsed['last']).length;
    final showInitial = count > 1 && parsed['first']!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textColor),
          children: [
            TextSpan(text: parsed['last']),
            if (showInitial) // 被りがある場合のみ右下に添える
              WidgetSpan(
                alignment: PlaceholderAlignment.bottom,
                child: Padding(
                  padding: const EdgeInsets.only(left: 2, bottom: 2),
                  child: Text(parsed['first']!.substring(0, 1), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: subTextColor)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ★ 修正：同姓判定を組み込んだ試合行の構築
  TableRow _buildMatchRow(MatchModel m, BuildContext ctx, bool isDark, List<String> redLastNames, List<String> whiteLastNames) {
    final isDone = m.status == 'approved' || m.status == 'finished';
    final rS = (m.redScore as num).toInt();
    final wS = (m.whiteScore as num).toInt();
    final isDraw = isDone && (rS == wS);
    
    final ptsMap = _calcPts(m);
    final rPts = ptsMap['red'] ?? [];
    final wPts = ptsMap['white'] ?? [];

    // ★ Phase 8: 代表戦の行をうっすら赤くし、文字も赤くハイライトする
    final isDaihyo = m.matchType == '代表戦';
    final daihyoBgColor = isDark ? Colors.red.shade900.withValues(alpha: 0.15) : Colors.red.shade50;
    final matchTypeColor = isDaihyo ? (isDark ? Colors.red.shade400 : Colors.red.shade800) : (isDark ? Colors.grey.shade300 : Colors.grey.shade800);

    return TableRow(
      decoration: isDaihyo ? BoxDecoration(color: daihyoBgColor) : null,
      children: [
        _clickableCell(ctx, m, _cell(m.matchType, fs: 12, fontWeight: FontWeight.bold, color: matchTypeColor)),
        _clickableCell(ctx, m, _buildNameCell(m.redName, isDark, redLastNames)), // ★ 修正
        _clickableCell(ctx, m, _buildMatchScoreBox(rPts, rS > wS, isDraw, true, isDark)),
        _clickableCell(ctx, m, _buildMatchScoreBox(wPts, wS > rS, false, false, isDark)),
        _clickableCell(ctx, m, _buildNameCell(m.whiteName, isDark, whiteLastNames)), // ★ 修正
      ],
    );
  }

  // 修正後 (TableCellを削除し、中のコンテンツだけを返すように変更)
  Widget _buildMatchScoreBox(List<TeamPointDisplay> pts, bool isWinner, bool isDraw, bool isRed, bool isDark) {
    final color = isRed 
        ? (isDark ? Colors.red.shade300 : Colors.red.shade700) 
        : (isDark ? Colors.grey.shade300 : Colors.blueGrey.shade700);
    
    final isFusen = pts.any((p) => p.mark == '◯');

    return SizedBox( // TableCellではなくSizedBoxを返す
      height: 84,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // ★ 修正：大丸をさらに拡大し、境界線を少し太くして視認性をアップ
          if (isWinner)
            Container(
              width: 62, height: 62, // 52→62
              decoration: BoxDecoration(
                shape: BoxShape.circle, 
                border: Border.all(color: color.withValues(alpha: 0.5), width: 2.4)
              ),
            ),
          
          // 技マークの表示エリアも少し広げて配置のバランスを取る
          SizedBox(
            width: 48, height: 48,
            child: Stack(
              children: [
                if (isFusen) ...[
                  Positioned(top: 0, left: 0, child: _ptMark(TeamPointDisplay('◯', false), color, isDark)),
                  Positioned(bottom: 0, right: 0, child: _ptMark(TeamPointDisplay('◯', false), color, isDark)),
                ] else ...[
                  // 斜め配置の隅に少し余裕(2px)を持たせて、大丸との接触を回避
                  if (pts.isNotEmpty) Positioned(top: 2, left: 2, child: _ptMark(pts[0], color, isDark)),
                  if (pts.length > 1) Positioned(bottom: 2, right: 2, child: _ptMark(pts[1], color, isDark)),
                ],
              ],
            ),
          ),

          if (isRed && isDraw)
            Positioned(
              right: -14,
              child: Text('✕', style: TextStyle(fontSize: 28, color: isDark ? Colors.red.shade900.withValues(alpha: 0.6) : Colors.red.shade300, fontWeight: FontWeight.w300)),
            ),
        ],
      ),
    );
  }

  // 修正後
  Widget _clickableCell(BuildContext ctx, MatchModel m, Widget child) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => ctx.push('/match/${m.id}'),
        child: child,
      ),
    );
  }

  Widget _ptMark(TeamPointDisplay p, Color color, bool isDark) {
    if (p.isFirstMatchPoint && p.mark != '◯') {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.all(2),
        // ★ 修正：ダークモード時は丸の枠線を半透明(alpha: 0.4)にして、発光現象（白浮き）を抑える
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color.withValues(alpha: isDark ? 0.4 : 1.0), width: 1.5)),
        child: Text(p.mark, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(p.mark, style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.bold)),
    );
  }

  Widget _cell(String txt, {bool isH = false, Color? color, double fs = 13, FontWeight? fontWeight}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(txt, textAlign: TextAlign.center, style: TextStyle(fontSize: fs, fontWeight: isH ? FontWeight.bold : (fontWeight ?? FontWeight.normal), color: color)),
    );
  }

  // ★ 修正：合計欄の数値・勝敗判定もさらにサイズアップ
  TableRow _buildTotalRow(int rW, int rP, int wW, int wP, bool isDark, bool allFinished, {MatchModel? daihyo}) {
    final bg = isDark ? const Color(0xFF3A2E12) : Colors.amber.shade50; 
    final textColor = isDark ? Colors.white : Colors.black87;
    
    String teamWinner = 'draw';
    if (rW > wW) {
      teamWinner = 'red';
    } else if (wW > rW) {
      teamWinner = 'white';
    } else if (rP > wP) {
      teamWinner = 'red';
    } else if (wP > rP) {
      teamWinner = 'white';
    } else if (daihyo != null) {
      final rs = (daihyo.redScore as num).toInt();
      final ws = (daihyo.whiteScore as num).toInt();
      if (rs > ws) {
        teamWinner = 'red';
      } else if (ws > rs) {
        teamWinner = 'white';
      }
    }

    final isTeamTie = (teamWinner == 'draw');

    return TableRow(
      decoration: BoxDecoration(color: bg), 
      children: [
        const SizedBox.shrink(),
        _cell('$rW / $rP', isH: true, color: isDark ? Colors.red.shade400 : Colors.red.shade700, fs: 18), // 15→18
        
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: SizedBox(
            height: 64, // 56→64
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // ★ Phase 8-4: すべての試合が終わるまで勝敗テキストを隠す
                if (allFinished) ...[
                  if (isTeamTie)
                    Positioned(
                      right: -36, 
                      child: Text('引き分け', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? Colors.amber.shade200 : Colors.amber.shade900)), 
                    )
                  else
                    _cell(teamWinner == 'red' ? '勝' : '負', isH: true, color: teamWinner == 'red' ? Colors.red : textColor, fs: 20),
                ]
              ],
            ),
          ),
        ),

        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: SizedBox(
            height: 64,
            child: Center(
              // ★ Phase 8-4: すべての試合が終わるまで勝敗テキストを隠す
              child: (allFinished && !isTeamTie) ? _cell(teamWinner == 'white' ? '勝' : '負', isH: true, color: teamWinner == 'white' ? Colors.red : textColor, fs: 20) : const SizedBox.shrink(),
            ),
          ),
        ),
        
        _cell('$wW / $wP', isH: true, color: isDark ? Colors.grey.shade400 : Colors.blueGrey.shade800, fs: 18), 
      ],
    );
  }

  Map<String, List<TeamPointDisplay>> _calcPts(MatchModel m) {
    List<TeamPointDisplay> redPts = [];
    List<TeamPointDisplay> whitePts = [];
    int redHansoku = 0;
    int whiteHansoku = 0;
    bool isMatchFirstPoint = true;

    for (var e in m.events) {
      if (e.type == PointType.undo) {
        continue;
      }
      
      if (e.type == PointType.hansoku) {
        if (e.side == Side.red) { // ★ Enum比較
          redHansoku++;
          if (redHansoku == 2 || redHansoku == 4) { 
            whitePts.add(TeamPointDisplay('反', isMatchFirstPoint));
            isMatchFirstPoint = false;
          }
        } else if (e.side == Side.white) { // ★ Enum比較
          whiteHansoku++;
          if (whiteHansoku == 2 || whiteHansoku == 4) { 
            redPts.add(TeamPointDisplay('反', isMatchFirstPoint));
            isMatchFirstPoint = false;
          }
        }
      } else {
        if (e.side == Side.red) { // ★ Enum比較
          redPts.add(TeamPointDisplay(_toM(e.type), isMatchFirstPoint));
          isMatchFirstPoint = false;
        } else if (e.side == Side.white) { // ★ Enum比較
          whitePts.add(TeamPointDisplay(_toM(e.type), isMatchFirstPoint));
          isMatchFirstPoint = false;
        }
      }
    }
    return {'red': redPts, 'white': whitePts};
  }

  String _toM(PointType t) {
    switch (t) {
      case PointType.men: return 'メ';
      case PointType.kote: return 'コ';
      case PointType.doIdo: return 'ド';
      case PointType.tsuki: return 'ツ';
      case PointType.fusen: return '◯'; 
      case PointType.hantei: return '判'; // ★ 追加：判定勝ちは「判」の文字を返す
      default: return '';
    }
  }

  String _cleanName(String n, bool team) {
    if (!n.contains(':')) {
      return team ? 'チーム' : n;
    }
    return team ? n.split(':').first.trim() : n.split(':').last.replaceAll(')', '').trim();
  }
}