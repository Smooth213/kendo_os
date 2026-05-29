import 'package:flutter/material.dart';
import 'package:kendo_os/presentation/shared/widgets/match_tables/point_mark_badge.dart';

class IndividualMatchItem {
  final String id;
  final String note;
  final String redTeam;
  final String whiteTeam;
  final String redName;
  final String whiteName;
  final int redScore;
  final int whiteScore;
  final bool isFinished;
  final bool isSummary;
  final bool isDraw;
  final bool rWin;
  final bool wWin;
  final bool hasOwnTeam;
  final List<PointMark> redPoints;
  final List<PointMark> whitePoints;
  final VoidCallback? onTap;

  const IndividualMatchItem({
    required this.id,
    required this.note,
    required this.redTeam,
    required this.whiteTeam,
    required this.redName,
    required this.whiteName,
    required this.redScore,
    required this.whiteScore,
    required this.isFinished,
    required this.isSummary,
    required this.isDraw,
    required this.rWin,
    required this.wWin,
    required this.hasOwnTeam,
    required this.redPoints,
    required this.whitePoints,
    this.onTap,
  });
}

class IndividualListCard extends StatelessWidget {
  final String headerTitle;
  final List<IndividualMatchItem> matches;
  final Color? cardColor;
  final bool isDark;

  const IndividualListCard({
    super.key,
    required this.headerTitle,
    required this.matches,
    this.cardColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? const Color(0xFF38383A) : Colors.grey.shade300;
    final headerBgColor = isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade50;
    final textColor = isDark ? Colors.white : Colors.black87;

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
                          if (m.redTeam.isNotEmpty) Text(m.redTeam, style: TextStyle(fontSize: 9, color: Colors.grey.shade500), overflow: TextOverflow.ellipsis),
                          Text(m.redName, style: TextStyle(fontWeight: m.rWin ? FontWeight.w900 : FontWeight.bold, color: m.rWin ? Colors.red.shade700 : textColor), overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    PointBox(points: m.redPoints, isWinner: m.rWin, isRed: true, isDark: isDark),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(m.isDraw ? '✕' : '-', style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w300, fontSize: 16)),
                    ),
                    PointBox(points: m.whitePoints, isWinner: m.wWin, isRed: false, isDark: isDark),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (m.whiteTeam.isNotEmpty) Text(m.whiteTeam, style: TextStyle(fontSize: 9, color: Colors.grey.shade500), overflow: TextOverflow.ellipsis),
                          Text(m.whiteName, style: TextStyle(fontWeight: m.wWin ? FontWeight.w900 : FontWeight.bold, color: m.wWin ? Colors.red.shade700 : textColor), overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              );

              if (m.onTap != null) {
                rowContent = InkWell(onTap: m.onTap, child: rowContent);
              }

              if (m.isSummary && !m.hasOwnTeam) {
                return Container(
                  color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.05),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Opacity(opacity: 0.2, child: rowContent),
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