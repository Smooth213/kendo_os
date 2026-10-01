import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 🔍 拡大中のみ表示される「100%（全体表示）に戻す」リセットボタン
class QuickMemoZoomResetButton extends StatelessWidget {
  final bool isDark;
  final AppThemeColors themeColors;
  final VoidCallback onReset;

  const QuickMemoZoomResetButton({
    super.key,
    required this.isDark,
    required this.themeColors,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: AppSpacing.sm,
      right: AppSpacing.sm,
      child: Material(
        color: isDark ? const Color(0xFF1E293B) : AppKendoColors.white,
        borderRadius: AppRadius.full,
        elevation: 4,
        child: InkWell(
          borderRadius: AppRadius.full,
          onTap: onReset,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.compact,
              vertical: AppSpacing.subValue,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.zoom_out_map_rounded,
                  size: AppFontSize.body,
                  color: themeColors.textColor,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '100%に戻す',
                  style: TextStyle(
                    fontSize: AppFontSize.caption,
                    fontWeight: AppFontWeight.bold,
                    color: themeColors.textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 🔍 ピンチ操作中に表示される倍率バッジ（例: 150%）
class QuickMemoZoomBadge extends StatelessWidget {
  final bool isVisible;
  final double zoomScale;

  const QuickMemoZoomBadge({
    super.key,
    required this.isVisible,
    required this.zoomScale,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return Positioned(
      top: AppSpacing.sm,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedOpacity(
          opacity: isVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.compact,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppKendoColors.black.withValues(alpha: 0.72),
              borderRadius: AppRadius.full,
              border: Border.all(
                color: AppKendoColors.white.withValues(alpha: 0.24),
                width: 0.8,
              ),
            ),
            child: Text(
              '${(zoomScale * 100).toInt()}%',
              style: const TextStyle(
                color: AppKendoColors.white,
                fontSize: AppFontSize.small,
                fontWeight: AppFontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
