import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/match_model.dart';
import '../domain/match/score_event.dart';
import '../presentation/provider/match_list_provider.dart';
import '../domain/match/team_match_calculator.dart';
import 'viewer_kachinuki_scoreboard_screen.dart';

class TeamPointDisplay {
  final String mark;
  final bool isFirstMatchPoint;
  TeamPointDisplay(this.mark, this.isFirstMatchPoint);
}

class ViewerTeamScoreboardScreen extends ConsumerWidget {
  final String? groupName; 
  final List<MatchModel>? matches;

  const ViewerTeamScoreboardScreen({super.key, this.groupName, this.matches});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List<MatchModel> teamMatches = matches ?? [];
    
    if (matches == null && groupName != null) {
      teamMatches = ref.watch(matchListProvider.select((list) => 
        list.where((m) => m.groupName == groupName).toList()
      ));
    }
    
    if (teamMatches.isEmpty) return const Scaffold(body: Center(child: Text('データがありません')));

    final firstMatch = teamMatches.first;
    if (firstMatch.isKachinuki || (firstMatch.rule?.isKachinuki ?? false)) {
      return ViewerKachinukiScoreboardScreen(groupName: firstMatch.groupName ?? '');
    }

    teamMatches.sort((a, b) => a.order.compareTo(b.order));

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : const Color(0xFFF2F2F7);
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final headerColor = isDark ? Colors.white : Colors.indigo.shade900;
    final borderColor = isDark ? const Color(0xFF38383A) : Colors.grey.shade200;

    final redTeam = _cleanName(teamMatches.first.redName, true);
    final whiteTeam = _cleanName(teamMatches.first.whiteName, true);
    final matchNote = teamMatches.first.note;

    final result = TeamMatchCalculator.calculate(teamMatches);
    
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: headerColor, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else if (teamMatches.isNotEmpty && teamMatches.first.tournamentId != null) {
              context.go('/viewer-home/${teamMatches.first.tournamentId}');
            } else {
              context.go('/');
            }
          },
        ),
        title: Text('団体戦 スコア (観戦)', style: TextStyle(fontWeight: FontWeight.bold, color: headerColor, fontSize: 16)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
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
                      ...teamMatches.map((m) => _buildMatchRow(
                        m, context, isDark, 
                        teamMatches.map((x) => _parseName(x.redName)['last']!).where((s) => s.isNotEmpty).toList(),
                        teamMatches.map((x) => _parseName(x.whiteName)['last']!).where((s) => s.isNotEmpty).toList()
                      )),
                      _buildTotalRow(result, isDark),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TableRow _buildHeaderRow(String r, String w, bool isDark) {
    final headerBg = isDark ? const Color(0xFF2C2C2E) : Colors.indigo.shade50;
    final textColor = isDark ? Colors.white : Colors.black87;
    return TableRow(
      decoration: BoxDecoration(color: headerBg),
      children: [
        _cell('', isH: true, color: textColor, fs: 12),
        _cell(r, isH: true, color: isDark ? Colors.red.shade300 : Colors.red.shade700, fs: 16),
        _cell('赤', isH: true, color: isDark ? Colors.red.shade300 : Colors.red.shade700, fs: 14),
        _cell('白', isH: true, color: isDark ? Colors.grey.shade300 : Colors.blueGrey.shade700, fs: 14),
        _cell(w, isH: true, color: isDark ? Colors.grey.shade300 : Colors.blueGrey.shade700, fs: 16),
      ],
    );
  }

  Map<String, String> _parseName(String raw) {
    if (raw.contains('欠員')) return {'last': '', 'first': ''};
    String clean = raw.contains(':') ? raw.split(':').last.replaceAll(RegExp(r'[()（）]'), '').trim() : raw.trim();
    var parts = clean.split(RegExp(r'\s+'));
    return {'last': parts[0], 'first': parts.length > 1 ? parts[1] : ''};
  }

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
            if (showInitial)
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

  TableRow _buildMatchRow(MatchModel m, BuildContext ctx, bool isDark, List<String> redLastNames, List<String> whiteLastNames) {
    final isDone = m.status == 'approved' || m.status == 'finished';
    final rS = (m.redScore as num).toInt();
    final wS = (m.whiteScore as num).toInt();
    final isDraw = isDone && (rS == wS);
    
    final ptsMap = _calcPts(m);
    final rPts = ptsMap['red'] ?? [];
    final wPts = ptsMap['white'] ?? [];

    final isDaihyo = m.matchType == '代表戦';
    final daihyoBgColor = isDark ? Colors.red.shade900.withValues(alpha: 0.15) : Colors.red.shade50;
    final matchTypeColor = isDaihyo ? (isDark ? Colors.red.shade400 : Colors.red.shade800) : (isDark ? Colors.grey.shade300 : Colors.grey.shade800);

    return TableRow(
      decoration: isDaihyo ? BoxDecoration(color: daihyoBgColor) : null,
      children: [
        _clickableCell(ctx, m, _cell(m.matchType, fs: 12, fontWeight: FontWeight.bold, color: matchTypeColor)),
        _clickableCell(ctx, m, _buildNameCell(m.redName, isDark, redLastNames)),
        _clickableCell(ctx, m, _buildMatchScoreBox(rPts, isDone && rS > wS, isDraw, true, isDark)),
        _clickableCell(ctx, m, _buildMatchScoreBox(wPts, isDone && wS > rS, false, false, isDark)),
        _clickableCell(ctx, m, _buildNameCell(m.whiteName, isDark, whiteLastNames)),
      ],
    );
  }

  Widget _buildMatchScoreBox(List<TeamPointDisplay> pts, bool isWinner, bool isDraw, bool isRed, bool isDark) {
    final color = isRed 
        ? (isDark ? Colors.red.shade300 : Colors.red.shade700) 
        : (isDark ? Colors.grey.shade300 : Colors.blueGrey.shade700);
    
    final isFusen = pts.any((p) => p.mark == '◯');

    return SizedBox(
      height: 84,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (isWinner)
            Container(
              width: 62, height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle, 
                border: Border.all(color: color.withValues(alpha: 0.5), width: 2.4)
              ),
            ),
          
          SizedBox(
            width: 48, height: 48,
            child: Stack(
              children: [
                if (isFusen) ...[
                  Positioned(top: 0, left: 0, child: _ptMark(TeamPointDisplay('◯', false), color, isDark)),
                  Positioned(bottom: 0, right: 0, child: _ptMark(TeamPointDisplay('◯', false), color, isDark)),
                ] else ...[
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

  Widget _clickableCell(BuildContext ctx, MatchModel m, Widget child) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => ctx.push('/viewer/${m.id}'),
        child: child,
      ),
    );
  }

  Widget _ptMark(TeamPointDisplay p, Color color, bool isDark) {
    if (p.isFirstMatchPoint && p.mark != '◯') {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.all(2),
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

  TableRow _buildTotalRow(TeamMatchResult result, bool isDark) {
    final bg = isDark ? const Color(0xFF3A2E12) : Colors.amber.shade50; 
    final textColor = isDark ? Colors.white : Colors.black87;
    final isTeamTie = (result.teamWinner == 'draw');

    return TableRow(
      decoration: BoxDecoration(color: bg), 
      children: [
        const SizedBox.shrink(),
        _cell('${result.redWins} / ${result.redPoints}', isH: true, color: isDark ? Colors.red.shade400 : Colors.red.shade700, fs: 18), 
        
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: SizedBox(
            height: 64,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                if (result.allFinished) ...[
                  if (isTeamTie)
                    Positioned(
                      right: -36, 
                      child: Text('引き分け', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? Colors.amber.shade200 : Colors.amber.shade900)), 
                    )
                  else
                    _cell(result.teamWinner == 'red' ? '勝' : '負', isH: true, color: result.teamWinner == 'red' ? Colors.red : textColor, fs: 20),
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
              child: (result.allFinished && !isTeamTie) ? _cell(result.teamWinner == 'white' ? '勝' : '負', isH: true, color: result.teamWinner == 'white' ? Colors.red : textColor, fs: 20) : const SizedBox.shrink(),
            ),
          ),
        ),
        
        _cell('${result.whiteWins} / ${result.whitePoints}', isH: true, color: isDark ? Colors.grey.shade400 : Colors.blueGrey.shade800, fs: 18), 
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
      if (e.type == PointType.undo || e.isCanceled) continue;
      
      if (e.type == PointType.hansoku) {
        if (e.side == Side.red) {
          redHansoku++;
          if (redHansoku == 2 || redHansoku == 4) { 
            whitePts.add(TeamPointDisplay('反', isMatchFirstPoint));
            isMatchFirstPoint = false;
          }
        } else if (e.side == Side.white) {
          whiteHansoku++;
          if (whiteHansoku == 2 || whiteHansoku == 4) { 
            redPts.add(TeamPointDisplay('反', isMatchFirstPoint));
            isMatchFirstPoint = false;
          }
        }
      } else {
        if (e.side == Side.red) {
          redPts.add(TeamPointDisplay(_toM(e.type), isMatchFirstPoint));
          isMatchFirstPoint = false;
        } else if (e.side == Side.white) {
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
      case PointType.hantei: return '判';
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