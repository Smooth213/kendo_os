import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/name_formatter.dart';
import 'package:kendo_os/shared/widgets/vertical_name_text.dart';

Widget buildScoreTableTeamResultCell(
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
                            ? const Color(0xFFE53935)
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
                            ? const Color(0xFF2196F3)
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

Widget buildScoreTableTeamCell(String name, Color color) => Center(
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

Widget buildScoreTableNameCell(
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

  return onTap != null ? InkWell(onTap: onTap, child: cell) : cell;
}

Widget buildScoreTableSummaryCell(
  BuildContext context,
  int wins,
  int points,
  bool isDark,
) {
  final themeColors =
      Theme.of(context).extension<AppThemeColors>() ??
      AppThemeColors.ofMode(isDark: isDark, mode: 'normal');

  return Center(
    child: Text(
      '$points\n--\n$wins',
      style: TextStyle(
        fontWeight: AppFontWeight.bold,
        fontSize: AppFontSize.small,
        color: themeColors.subTextColor,
      ),
      textAlign: TextAlign.center,
    ),
  );
}
