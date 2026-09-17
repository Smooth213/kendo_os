import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// ⏱️ 開始予定時刻クイック選択チップリスト
class MatchCalculatorQuickTimeChips extends StatelessWidget {
  final TimeOfDay startTime;
  final bool isDark;
  final AppThemeColors themeColors;
  final Color primaryAccent;
  final ValueChanged<TimeOfDay> onTimeSelected;
  final VoidCallback onCurrentTimeSelected;

  const MatchCalculatorQuickTimeChips({
    super.key,
    required this.startTime,
    required this.isDark,
    required this.themeColors,
    required this.primaryAccent,
    required this.onTimeSelected,
    required this.onCurrentTimeSelected,
  });

  static const quickTimes = [
    TimeOfDay(hour: 8, minute: 30),
    TimeOfDay(hour: 9, minute: 0),
    TimeOfDay(hour: 9, minute: 30),
    TimeOfDay(hour: 10, minute: 0),
    TimeOfDay(hour: 11, minute: 0),
    TimeOfDay(hour: 13, minute: 0),
    TimeOfDay(hour: 13, minute: 30),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.xs),
          child: Text(
            'クイック選択',
            style: TextStyle(
              fontSize: AppFontSize.caption,
              fontWeight: AppFontWeight.bold,
              color: themeColors.subTextColor,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...quickTimes.map((tod) {
                final isSelected =
                    startTime.hour == tod.hour &&
                    startTime.minute == tod.minute;
                final label =
                    '${tod.hour.toString().padLeft(2, '0')}:${tod.minute.toString().padLeft(2, '0')}';
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onTimeSelected(tod),
                      borderRadius: AppRadius.capsule,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? primaryAccent
                              : themeColors.surface,
                          borderRadius: AppRadius.capsule,
                          border: Border.all(
                            color: isSelected
                                ? primaryAccent
                                : themeColors.subTextColor.withValues(
                                    alpha: 0.2,
                                  ),
                          ),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: AppFontSize.caption,
                            fontWeight: isSelected
                                ? AppFontWeight.bold
                                : AppFontWeight.medium,
                            color: isSelected
                                ? AppKendoColors.pureWhite
                                : themeColors.textColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onCurrentTimeSelected,
                    borderRadius: AppRadius.capsule,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: themeColors.primaryAccent.withValues(
                          alpha: 0.15,
                        ),
                        borderRadius: AppRadius.capsule,
                        border: Border.all(
                          color: themeColors.primaryAccent.withValues(
                            alpha: 0.35,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time_filled_rounded,
                            size: 13,
                            color: themeColors.primaryAccent,
                          ),
                          const SizedBox(width: AppSpacing.xxs),
                          Text(
                            '現在時刻',
                            style: TextStyle(
                              fontSize: AppFontSize.caption,
                              fontWeight: AppFontWeight.bold,
                              color: themeColors.primaryAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
