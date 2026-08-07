import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/match_tables/point_mark_badge.dart';

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
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');

    final borderColor = themeColors.separatorColor;
    final headerBgColor = themeColors.inputBackground;
    final textColor = themeColors.textColor;

    return Card(
      margin: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
        horizontal: AppSpacing.xs,
      ),
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.large,
        side: BorderSide(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            color: headerBgColor,
            width: double.infinity,
            child: Text(
              headerTitle,
              style: TextStyle(
                fontWeight: AppFontWeight.bold,
                color: textColor,
              ),
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: matches.length,
            separatorBuilder: (context, index) => Divider(
              color: borderColor,
              height: 1,
              indent: 16,
              endIndent: 16,
            ),
            itemBuilder: (context, index) {
              final m = matches[index];

              Widget rowContent = Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.md,
                  horizontal: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 55,
                      child: Text(
                        m.note.isNotEmpty ? m.note : '第${index + 1}試合',
                        style: TextStyle(
                          fontSize: AppFontSize.badge,
                          color: Colors.grey.shade500,
                          fontWeight: AppFontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (m.redTeam.isNotEmpty)
                            Text(
                              m.redTeam,
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey.shade500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          Text(
                            m.redName,
                            style: TextStyle(
                              fontWeight: m.rWin
                                  ? AppFontWeight.bold
                                  : AppFontWeight.bold,
                              color: m.rWin ? Colors.red.shade700 : textColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    PointBox(
                      points: m.redPoints,
                      isWinner: m.rWin,
                      isRed: true,
                      isDark: isDark,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                      child: Text(
                        m.isDraw ? '✕' : '-',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.w300,
                          fontSize: AppFontSize.subhead,
                        ),
                      ),
                    ),
                    PointBox(
                      points: m.whitePoints,
                      isWinner: m.wWin,
                      isRed: false,
                      isDark: isDark,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (m.whiteTeam.isNotEmpty)
                            Text(
                              m.whiteTeam,
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey.shade500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          Text(
                            m.whiteName,
                            style: TextStyle(
                              fontWeight: m.wWin
                                  ? AppFontWeight.bold
                                  : AppFontWeight.bold,
                              color: m.wWin ? Colors.red.shade700 : textColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
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
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.05),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Opacity(opacity: 0.2, child: rowContent),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1C1C1E)
                              : Colors.white,
                          borderRadius: AppRadius.small,
                          border: Border.all(
                            color: Colors.grey.shade400,
                            width: 0.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Text(
                          '※簡易入力された結果です\n（詳細スコアはありません）',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: AppFontSize.caption,
                            fontWeight: AppFontWeight.bold,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade700,
                          ),
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
