import 'package:flutter/material.dart';
import 'package:kendo_os/presentation/shared/widgets/match_tables/point_mark_badge.dart';
import 'package:kendo_os/presentation/shared/widgets/vertical_name_text.dart';
import 'package:kendo_os/core/utils/name_formatter.dart';

class ScoreTableMatchItem {
  final String id;
  final String matchType;
  final String redName;
  final String whiteName;
  final int redScore;
  final int whiteScore;
  final bool isFinished;
  final bool isSummary;
  final List<PointMark> redPoints;
  final List<PointMark> whitePoints;
  final VoidCallback? onTap;

  const ScoreTableMatchItem({
    required this.id,
    required this.matchType,
    required this.redName,
    required this.whiteName,
    required this.redScore,
    required this.whiteScore,
    required this.isFinished,
    this.isSummary = false,
    required this.redPoints,
    required this.whitePoints,
    this.onTap,
  });
}

class ScoreTableGroupInfo {
  final String groupName;
  final String headerTitle;
  final String sideLabelRed;
  final String sideLabelWhite;
  final bool isSummary;
  final String teamWinner;
  final int redWins;
  final int whiteWins;
  final int redTotalPoints;
  final int whiteTotalPoints;
  final bool allFinished;

  const ScoreTableGroupInfo({
    required this.groupName,
    required this.headerTitle,
    required this.sideLabelRed,
    required this.sideLabelWhite,
    required this.isSummary,
    required this.teamWinner,
    required this.redWins,
    required this.whiteWins,
    required this.redTotalPoints,
    required this.whiteTotalPoints,
    required this.allFinished,
  });
}

class ScoreTableCard extends StatelessWidget {
  final ScoreTableGroupInfo info;
  final List<ScoreTableMatchItem> matches;
  final Color? cardColor;
  final bool isDark;

  const ScoreTableCard({
    super.key,
    required this.info,
    required this.matches,
    this.cardColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? const Color(0xFF38383A) : Colors.grey.shade300;
    final headerBgColor = isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade50;
    final headerTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade700;
    final daihyoBgColor = isDark ? Colors.red.shade900.withValues(alpha: 0.15) : Colors.red.shade50;

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
                padding: const EdgeInsets.all(12), color: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade100, width: double.infinity,
                child: Text(info.headerTitle, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade300 : Colors.grey.shade800)),
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
                      Center(child: Padding(padding: const EdgeInsets.all(8), child: Text('本/勝', style: TextStyle(fontSize: 10, color: headerTextColor)))),
                    ],
                  ),
                  TableRow(children: [
                    _teamCell(info.sideLabelRed, isDark ? Colors.red.shade400 : Colors.red.shade700),
                    ...matches.map((m) => _nameCell(
                      m.redName, isDark, 
                      matches.map((x) => NameFormatter.parse(x.redName)['last']!).where((s) => s.isNotEmpty).toList(),
                      isDaihyo: m.matchType == '代表戦',
                      onTap: m.onTap,
                    )),
                    _summaryCell(info.redWins, info.redTotalPoints, isDark),
                  ]),
                  TableRow(children: [
                    const SizedBox.shrink(),
                    ...matches.map((m) => _scoreCell(m, isDark, info.isSummary)),
                    _teamResultCell(info.teamWinner, isDark, info.allFinished),
                  ]),
                  TableRow(children: [
                    _teamCell(info.sideLabelWhite, isDark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade700),
                    ...matches.map((m) => _nameCell(
                      m.whiteName, isDark, 
                      matches.map((x) => NameFormatter.parse(x.whiteName)['last']!).where((s) => s.isNotEmpty).toList(),
                      isDaihyo: m.matchType == '代表戦',
                      onTap: m.onTap,
                    )),
                    _summaryCell(info.whiteWins, info.whiteTotalPoints, isDark),
                  ]),
                ],
              ),
            ],
          ),
          if (info.isSummary)
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
              Center(child: VerticalNameText(text: '引き分け', isDark: isDark))
            else
              Column(
                children: [
                  Expanded(child: Center(child: Text(winner == 'red' ? '勝' : '負', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: winner == 'red' ? (isDark ? Colors.red.shade400 : Colors.red.shade600) : textColor)))),
                  Expanded(child: Center(child: Text(winner == 'white' ? '勝' : '負', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: winner == 'white' ? (isDark ? Colors.blue.shade400 : Colors.blue.shade600) : textColor)))),
                ],
              ),
          ]
        ],
      ),
    );
  }

  Widget _teamCell(String name, Color color) => Center(child: Padding(padding: const EdgeInsets.all(4), child: Text(name, textAlign: TextAlign.center, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11))));

  Widget _nameCell(String rawName, bool isDark, List<String> teamLastNames, {bool isDaihyo = false, VoidCallback? onTap}) {
    if (rawName.contains('欠員')) {
      return Container(color: isDaihyo ? (isDark ? Colors.red.shade900.withValues(alpha: 0.15) : Colors.red.shade50) : Colors.transparent);
    }

    final parsed = NameFormatter.parse(rawName);
    final showInitial = teamLastNames.where((n) => n == parsed['last']).length > 1 && parsed['first']!.isNotEmpty;

    final cell = Container(
      color: isDaihyo ? (isDark ? Colors.red.shade900.withValues(alpha: 0.15) : Colors.red.shade50) : Colors.transparent, 
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4), 
          child: VerticalNameText(text: parsed['last']!, initial: showInitial ? parsed['first']!.substring(0, 1) : '', isDark: isDark),
        ),
      ),
    );

    if (onTap != null) {
      return InkWell(onTap: onTap, child: cell);
    }
    return cell;
  }

  Widget _scoreCell(ScoreTableMatchItem m, bool isDark, bool isSummary) {
    if (isSummary) return const SizedBox(height: 70);

    return Container(
      height: 70, alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Divider(color: isDark ? const Color(0xFF38383A) : Colors.grey.shade300, thickness: 1, height: 0),
          if (m.isFinished && m.redScore == m.whiteScore)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              child: Text('✕', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: isDark ? Colors.grey.shade500 : Colors.grey.shade400)),
            ),
          Column(
            children: [
              Expanded(child: PointBox(points: m.redPoints, isWinner: m.isFinished && m.redScore > m.whiteScore, isRed: true, isDark: isDark)),
              Expanded(child: PointBox(points: m.whitePoints, isWinner: m.isFinished && m.whiteScore > m.redScore, isRed: false, isDark: isDark)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryCell(int wins, int pts, bool isDark) {
    return Center(child: Text('$pts\n--\n$wins', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade800), textAlign: TextAlign.center));
  }
}