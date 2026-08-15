import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/match_tables/point_mark_badge.dart';

/// 星取表カードにおける個々の対戦スコアセル（純粋UIコンポーネント）
class ScoreTableCell extends StatelessWidget {
  final bool isSummary;
  final bool isFinished;
  final bool isEncho;
  final int redScore;
  final int whiteScore;
  final List<PointMark> redPoints;
  final List<PointMark> whitePoints;
  final bool isDark;

  const ScoreTableCell({
    super.key,
    this.isSummary = false,
    required this.isFinished,
    this.isEncho = false,
    required this.redScore,
    required this.whiteScore,
    required this.redPoints,
    required this.whitePoints,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (isSummary) return const SizedBox(height: 70);

    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');

    return Container(
      height: 70,
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Divider(color: themeColors.separatorColor, thickness: 1, height: 0),
          if (isFinished && redScore == whiteScore)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
              color: themeColors.cardBackground,
              child: Text(
                '✕',
                style: TextStyle(
                  fontSize: AppFontSize.subhead,
                  fontWeight: AppFontWeight.bold,
                  color: themeColors.hintColor,
                ),
              ),
            )
          else if (isEncho)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xxs,
                vertical: 1,
              ),
              color: themeColors.cardBackground,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '延',
                    style: TextStyle(
                      fontSize: AppFontSize.badge,
                      fontWeight: AppFontWeight.bold,
                      height: 1.0,
                      color: themeColors.textColor,
                    ),
                  ),
                  Text(
                    '長',
                    style: TextStyle(
                      fontSize: AppFontSize.badge,
                      fontWeight: AppFontWeight.bold,
                      height: 1.0,
                      color: themeColors.textColor,
                    ),
                  ),
                ],
              ),
            ),
          Column(
            children: [
              Expanded(
                child: PointBox(
                  points: redPoints,
                  isWinner: isFinished && redScore > whiteScore,
                  isRed: true,
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: PointBox(
                  points: whitePoints,
                  isWinner: isFinished && whiteScore > redScore,
                  isRed: false,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
