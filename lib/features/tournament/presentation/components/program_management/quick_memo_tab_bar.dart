import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_haptics.dart';

/// 🥋 クイックメモの入力モード
enum QuickMemoMode { drawing, text }

/// 🥋 クイックメモのモード切り替えタブバー
class QuickMemoTabBar extends StatelessWidget {
  final QuickMemoMode currentMode;
  final AppThemeColors themeColors;
  final ValueChanged<QuickMemoMode> onModeChanged;

  const QuickMemoTabBar({
    super.key,
    required this.currentMode,
    required this.themeColors,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      color: themeColors.cardBackground,
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              mode: QuickMemoMode.drawing,
              icon: Icons.brush_rounded,
              label: '手書きメモ',
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _buildTabButton(
              mode: QuickMemoMode.text,
              icon: Icons.keyboard_alt_rounded,
              label: 'テキストメモ',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required QuickMemoMode mode,
    required IconData icon,
    required String label,
  }) {
    final isSelected = currentMode == mode;
    return GestureDetector(
      onTap: () {
        AppHaptics.selection();
        onModeChanged(mode);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: isSelected
              ? themeColors.primaryAccent.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: AppRadius.medium,
          border: Border.all(
            color: isSelected
                ? themeColors.primaryAccent.withValues(alpha: 0.6)
                : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? themeColors.primaryAccent
                  : themeColors.subTextColor,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: TextStyle(
                fontSize: AppFontSize.bodySmall,
                fontWeight: isSelected
                    ? AppFontWeight.bold
                    : AppFontWeight.regular,
                color: isSelected
                    ? themeColors.primaryAccent
                    : themeColors.subTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
