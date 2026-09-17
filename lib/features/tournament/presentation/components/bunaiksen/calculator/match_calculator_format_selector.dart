import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/domain/match_calculator/match_calculation_models.dart';
import 'package:kendo_os/features/tournament/presentation/providers/match_calculator_provider.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_haptics.dart';

/// 🥋 試合形式選択セグメント
class MatchCalculatorFormatSelector extends StatelessWidget {
  final CalculatorSettings settings;
  final MatchCalculatorNotifier notifier;

  const MatchCalculatorFormatSelector({
    super.key,
    required this.settings,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'bunaiksen');

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: MatchFormatType.values.map((format) {
          final isSelected = settings.format == format;
          final accentColor = themeColors.primaryAccent;

          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  AppHaptics.selection();
                  notifier.updateFormat(format);
                },
                borderRadius: AppRadius.capsule,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? accentColor : themeColors.surface,
                    borderRadius: AppRadius.capsule,
                    border: Border.all(
                      color: isSelected
                          ? accentColor
                          : themeColors.subTextColor.withValues(alpha: 0.2),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        format.icon,
                        size: 16,
                        color: isSelected
                            ? themeColors.onPrimaryAccent
                            : themeColors.subTextColor,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        format.label,
                        style: TextStyle(
                          fontSize: AppFontSize.bodySmall,
                          fontWeight: isSelected
                              ? AppFontWeight.bold
                              : AppFontWeight.medium,
                          color: isSelected
                              ? themeColors.onPrimaryAccent
                              : themeColors.subTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
