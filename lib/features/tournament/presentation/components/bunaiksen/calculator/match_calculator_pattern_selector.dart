import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/domain/match_calculator/match_calculation_models.dart';
import 'package:kendo_os/features/tournament/presentation/providers/match_calculator_provider.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_haptics.dart';

/// 🥋 コート割り振りパターン選択コンポーネント
class MatchCalculatorPatternSelector extends StatelessWidget {
  final CalculatorSettings settings;
  final MatchCalculatorNotifier notifier;

  const MatchCalculatorPatternSelector({
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

    final primaryAccent = themeColors.primaryAccent;

    return Column(
      children: AllocationPattern.values.map((pat) {
        final isSelected = settings.pattern == pat;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                AppHaptics.selection();
                notifier.updatePattern(pat);
              },
              borderRadius: AppRadius.medium,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryAccent.withValues(alpha: 0.12)
                      : themeColors.surface,
                  borderRadius: AppRadius.medium,
                  border: Border.all(
                    color: isSelected
                        ? primaryAccent
                        : themeColors.subTextColor.withValues(alpha: 0.15),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    // ラジオボタン風インジケータ
                    Container(
                      width: 20,
                      height: 20,
                      margin: const EdgeInsets.only(right: AppSpacing.sm),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? primaryAccent
                              : themeColors.subTextColor.withValues(alpha: 0.4),
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? Center(
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: primaryAccent,
                                ),
                              ),
                            )
                          : null,
                    ),
                    Icon(
                      pat.icon,
                      size: 18,
                      color: isSelected
                          ? primaryAccent
                          : themeColors.subTextColor,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pat.title,
                            style: TextStyle(
                              fontSize: AppFontSize.bodySmall,
                              fontWeight: isSelected
                                  ? AppFontWeight.bold
                                  : AppFontWeight.medium,
                              color: isSelected
                                  ? primaryAccent
                                  : themeColors.textColor,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            pat.description,
                            style: TextStyle(
                              fontSize: AppFontSize.caption,
                              color: themeColors.subTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
