import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/match_tables/point_mark_badge.dart';
import 'package:kendo_os/shared/widgets/vertical_name_text.dart';
import 'package:kendo_os/shared/utils/name_formatter.dart';

class ScoreTableMatchItem {
  final String id;
  final String matchType;
  final String redName;
  final String whiteName;
  final int redScore;
  final int whiteScore;
  final bool isFinished;
  final bool isSummary;
  final bool isEncho;
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
    this.isEncho = false,
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
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');

    final borderColor = themeColors.separatorColor;
    final headerBgColor = themeColors.inputBackground;
    final headerTextColor = themeColors.subTextColor;
    final daihyoBgColor = isDark
        ? const Color(0xFFE53935).withValues(alpha: 0.15)
        : const Color(0xFFFFF5F5);

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
      child: Stack(
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                color: themeColors.inputBackground,
                width: double.infinity,
                child: Text(
                  info.headerTitle,
                  style: TextStyle(
                    fontWeight: AppFontWeight.bold,
                    color: themeColors.textColor,
                  ),
                ),
              ),
              Table(
                border: TableBorder.all(color: borderColor, width: 1),
                columnWidths: {
                  0: const FlexColumnWidth(1.2),
                  for (int i = 1; i <= matches.length; i++)
                    i: const FlexColumnWidth(1.0),
                  matches.length + 1: const FlexColumnWidth(0.8),
                },
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: headerBgColor),
                    children: [
                      const SizedBox.shrink(),
                      ...matches.map(
                        (m) => Container(
                          color: m.matchType == '代表戦'
                              ? daihyoBgColor
                              : AppKendoColors.transparent,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              child: Text(
                                m.matchType,
                                style: TextStyle(
                                  fontSize: AppFontSize.badge,
                                  fontWeight: AppFontWeight.bold,
                                  color: m.matchType == '代表戦'
                                      ? (isDark
                                            ? const Color(0xFFFF6B6B)
                                            : AppKendoColors.hansokuRed)
                                      : themeColors.textColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          child: Text(
                            '本/勝',
                            style: TextStyle(
                              fontSize: AppFontSize.badge,
                              color: headerTextColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      _teamCell(
                        info.sideLabelRed,
                        isDark
                            ? const Color(0xFFE53935)
                            : const Color(0xFFE53935),
                      ),
                      ...matches.map(
                        (m) => _nameCell(
                          m.redName,
                          isDark,
                          matches
                              .map(
                                (x) => NameFormatter.parse(x.redName)['last']!,
                              )
                              .where((s) => s.isNotEmpty)
                              .toList(),
                          isDaihyo: m.matchType == '代表戦',
                          onTap: m.onTap,
                        ),
                      ),
                      _summaryCell(
                        context,
                        info.redWins,
                        info.redTotalPoints,
                        isDark,
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      const SizedBox.shrink(),
                      ...matches.map(
                        (m) => _scoreCell(m, isDark, info.isSummary),
                      ),
                      _teamResultCell(
                        context,
                        info.teamWinner,
                        isDark,
                        info.allFinished,
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      _teamCell(
                        info.sideLabelWhite,
                        isDark
                            ? context.appColors.subTextColor
                            : context.appColors.subTextColor,
                      ),
                      ...matches.map(
                        (m) => _nameCell(
                          m.whiteName,
                          isDark,
                          matches
                              .map(
                                (x) =>
                                    NameFormatter.parse(x.whiteName)['last']!,
                              )
                              .where((s) => s.isNotEmpty)
                              .toList(),
                          isDaihyo: m.matchType == '代表戦',
                          onTap: m.onTap,
                        ),
                      ),
                      _summaryCell(
                        context,
                        info.whiteWins,
                        info.whiteTotalPoints,
                        isDark,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          if (info.isSummary)
            Positioned.fill(
              top: 40,
              child: Container(
                color: isDark
                    ? const Color(0xFFFFFFFF).withValues(alpha: 0.3)
                    : const Color(0xFFFFFFFF).withValues(alpha: 0.6),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? context.appColors.cardBackground
                          : context.appColors.inputBackground,
                      borderRadius: AppRadius.small,
                      border: Border.all(
                        color: context.appColors.separatorColor,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppKendoColors.pureBlack.withValues(
                            alpha: 0.1,
                          ),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Text(
                      '※簡易入力された結果です\n（詳細スコアはありません）',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: AppFontSize.bodySmall,
                        fontWeight: AppFontWeight.bold,
                        color: themeColors.textColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _teamResultCell(
    BuildContext context,
    String winner,
    bool isDark,
    bool allFinished,
  ) {
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');

    final textColor = themeColors.textColor;
    final dividerColor = themeColors.separatorColor;

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
              Center(
                child: VerticalNameText(text: '引き分け', isDark: isDark),
              )
            else
              Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        winner == 'red' ? '勝' : '負',
                        style: TextStyle(
                          fontSize: AppFontSize.body,
                          fontWeight: AppFontWeight.bold,
                          color: winner == 'red'
                              ? (isDark
                                    ? const Color(0xFFE53935)
                                    : const Color(0xFFE53935))
                              : textColor,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        winner == 'white' ? '勝' : '負',
                        style: TextStyle(
                          fontSize: AppFontSize.body,
                          fontWeight: AppFontWeight.bold,
                          color: winner == 'white'
                              ? (isDark
                                    ? const Color(0xFF2196F3)
                                    : const Color(0xFF2196F3))
                              : textColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }

  Widget _teamCell(String name, Color color) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: Text(
        name,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontWeight: AppFontWeight.bold,
          fontSize: AppFontSize.caption,
        ),
      ),
    ),
  );

  Widget _nameCell(
    String rawName,
    bool isDark,
    List<String> teamLastNames, {
    bool isDaihyo = false,
    VoidCallback? onTap,
  }) {
    if (rawName.contains('欠員')) {
      return Container(
        color: isDaihyo
            ? (isDark
                  ? const Color(0xFFE53935).withValues(alpha: 0.15)
                  : const Color(0xFFE53935))
            : Colors.transparent,
      );
    }

    final parsed = NameFormatter.parse(rawName);
    final showInitial =
        teamLastNames.where((n) => n == parsed['last']).length > 1 &&
        parsed['first']!.isNotEmpty;

    final cell = Container(
      color: isDaihyo
          ? (isDark
                ? const Color(0xFFE53935).withValues(alpha: 0.15)
                : const Color(0xFFFFF5F5))
          : Colors.transparent,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.xs,
          ),
          child: VerticalNameText(
            text: parsed['last']!,
            initial: showInitial ? parsed['first']!.substring(0, 1) : '',
            isDark: isDark,
          ),
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
      height: 70,
      alignment: Alignment.center,
      child: Builder(
        builder: (context) {
          final themeColors =
              Theme.of(context).extension<AppThemeColors>() ??
              AppThemeColors.ofMode(isDark: isDark, mode: 'normal');

          return Stack(
            alignment: Alignment.center,
            children: [
              Divider(
                color: themeColors.separatorColor,
                thickness: 1,
                height: 0,
              ),
              if (m.isFinished && m.redScore == m.whiteScore)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxs,
                  ),
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
              else if (m.isEncho)
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
                      points: m.redPoints,
                      isWinner: m.isFinished && m.redScore > m.whiteScore,
                      isRed: true,
                      isDark: isDark,
                    ),
                  ),
                  Expanded(
                    child: PointBox(
                      points: m.whitePoints,
                      isWinner: m.isFinished && m.whiteScore > m.redScore,
                      isRed: false,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _summaryCell(BuildContext context, int wins, int pts, bool isDark) {
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');

    return Center(
      child: Text(
        '$pts\n--\n$wins',
        style: TextStyle(
          fontWeight: AppFontWeight.bold,
          fontSize: AppFontSize.small,
          color: themeColors.subTextColor,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
