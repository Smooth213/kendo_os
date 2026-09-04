import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_haptics.dart';

/// 🥋 クイック手書きメモの下部描画ツールバー
class QuickMemoDrawingToolbar extends StatelessWidget {
  final AppThemeColors themeColors;
  final bool isDark;
  final Color selectedColor;
  final double selectedWidth;
  final bool isEraser;
  final ValueChanged<Color> onColorChanged;
  final VoidCallback onToggleWidth;
  final VoidCallback onToggleEraser;

  const QuickMemoDrawingToolbar({
    super.key,
    required this.themeColors,
    required this.isDark,
    required this.selectedColor,
    required this.selectedWidth,
    required this.isEraser,
    required this.onColorChanged,
    required this.onToggleWidth,
    required this.onToggleEraser,
  });

  @override
  Widget build(BuildContext context) {
    final availableColors = [
      isDark ? AppKendoColors.pureWhite : AppKendoColors.pureBlack,
      AppKendoColors.redAccent,
      AppKendoColors.blue,
      AppKendoColors.ipponGold,
      AppKendoColors.green,
    ];

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: (isDark ? const Color(0xFF1E293B) : AppKendoColors.pureWhite)
              .withValues(alpha: 0.94),
          borderRadius: AppRadius.full,
          border: Border.all(
            color:
                (isDark ? AppKendoColors.pureWhite : AppKendoColors.pureBlack)
                    .withValues(alpha: 0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: AppKendoColors.pureBlack.withValues(alpha: 0.2),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (final color in availableColors)
              GestureDetector(
                onTap: () {
                  AppHaptics.selection();
                  onColorChanged(color);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    border: Border.all(
                      color: !isEraser && selectedColor == color
                          ? (isDark
                                ? AppKendoColors.pureWhite
                                : AppKendoColors.pureBlack)
                          : Colors.transparent,
                      width: 2.2,
                    ),
                    boxShadow: [
                      if (!isEraser && selectedColor == color)
                        BoxShadow(
                          color: color.withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(width: AppSpacing.xs),
            Container(
              width: 1,
              height: 24,
              color:
                  (isDark ? AppKendoColors.pureWhite : AppKendoColors.pureBlack)
                      .withValues(alpha: 0.15),
            ),
            const SizedBox(width: AppSpacing.xs),
            IconButton(
              icon: Icon(
                selectedWidth < 3.0
                    ? Icons.line_weight_rounded
                    : (selectedWidth < 6.0
                          ? Icons.brush_rounded
                          : Icons.highlight_rounded),
                size: 20,
                color: !isEraser
                    ? themeColors.primaryAccent
                    : themeColors.textColor.withValues(alpha: 0.5),
              ),
              tooltip: 'ペンの太さ',
              onPressed: () {
                AppHaptics.selection();
                onToggleWidth();
              },
            ),
            IconButton(
              icon: Icon(
                Icons.auto_fix_normal_rounded,
                size: 22,
                color: isEraser
                    ? AppKendoColors.redAccent
                    : themeColors.textColor.withValues(alpha: 0.6),
              ),
              tooltip: '消しゴム',
              onPressed: () {
                AppHaptics.selection();
                onToggleEraser();
              },
            ),
          ],
        ),
      ),
    );
  }
}
