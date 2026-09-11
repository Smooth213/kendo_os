import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// ⏱️ 独立型タイマー用の定型プリセットボタンチップ
class DockTimerPresetButton extends StatelessWidget {
  final String label;
  final int seconds;
  final bool isActive;
  final VoidCallback onTap;

  const DockTimerPresetButton({
    super.key,
    required this.label,
    required this.seconds,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? AppKendoColors.orangeAccent.withValues(alpha: 0.2)
              : themeColors.cardBackground,
          borderRadius: AppRadius.round,
          border: Border.all(
            color: isActive
                ? AppKendoColors.orangeAccent
                : themeColors.separatorColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: AppFontSize.bodySmall,
            fontWeight: isActive ? AppFontWeight.bold : AppFontWeight.regular,
            color: isActive
                ? AppKendoColors.orangeAccent
                : themeColors.textColor,
          ),
        ),
      ),
    );
  }
}
