import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_haptics.dart';

/// 🥋 クイックテキストメモ用のアクションツールバー
class QuickMemoTextToolbar extends StatelessWidget {
  final AppThemeColors themeColors;
  final bool isDark;
  final int charCount;
  final VoidCallback onInsertTimestamp;
  final VoidCallback? onCopy;
  final VoidCallback? onClear;

  const QuickMemoTextToolbar({
    super.key,
    required this.themeColors,
    required this.isDark,
    required this.charCount,
    required this.onInsertTimestamp,
    required this.onCopy,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? themeColors.cardBackground.withValues(alpha: 0.95)
            : themeColors.cardBackground,
        borderRadius: AppRadius.round,
        border: Border.all(
          color: themeColors.separatorColor.withValues(alpha: 0.8),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: AppKendoColors.pureBlack.withValues(
              alpha: isDark ? 0.35 : 0.08,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ⏰ 時刻挿入ボタン
          _buildActionButton(
            icon: Icons.schedule_rounded,
            label: '時刻挿入',
            onTap: onInsertTimestamp,
            isPrimary: true,
          ),
          const SizedBox(width: AppSpacing.xs),

          // 📋 コピーボタン
          _buildActionButton(
            icon: Icons.copy_rounded,
            label: 'コピー',
            onTap: onCopy,
          ),
          const SizedBox(width: AppSpacing.xs),

          // 🗑️ 全消去ボタン
          _buildActionButton(
            icon: Icons.delete_sweep_rounded,
            label: '全消去',
            onTap: onClear,
            isDestructive: true,
          ),
          const SizedBox(width: AppSpacing.sm),

          // 文字数表示
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: themeColors.inputBackground,
              borderRadius: AppRadius.small,
            ),
            child: Text(
              '$charCount 文字',
              style: TextStyle(
                fontSize: AppFontSize.caption,
                color: themeColors.subTextColor,
                fontWeight: AppFontWeight.medium,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    bool isPrimary = false,
    bool isDestructive = false,
  }) {
    final isEnabled = onTap != null;
    Color fgColor;
    if (!isEnabled) {
      fgColor = themeColors.disabledTextColor;
    } else if (isDestructive) {
      fgColor = themeColors.errorColor;
    } else if (isPrimary) {
      fgColor = themeColors.primaryAccent;
    } else {
      fgColor = themeColors.textColor;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled
            ? () {
                AppHaptics.selection();
                onTap();
              }
            : null,
        borderRadius: AppRadius.medium,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: fgColor),
              const SizedBox(width: AppSpacing.xxs),
              Text(
                label,
                style: TextStyle(
                  fontSize: AppFontSize.caption,
                  fontWeight: isPrimary
                      ? AppFontWeight.bold
                      : AppFontWeight.medium,
                  color: fgColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
