import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_haptics.dart';

/// 🥋 プログラムボトムシート用 PDFページ送りナビゲーションバー
class ProgramSheetPaginationBar extends StatelessWidget {
  final int currentPage;
  final int pageCount;
  final AppThemeColors themeColors;
  final bool isDark;
  final ValueChanged<int>? onPageChanged;

  const ProgramSheetPaginationBar({
    super.key,
    required this.currentPage,
    required this.pageCount,
    required this.themeColors,
    required this.isDark,
    this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (pageCount <= 1) return const SizedBox.shrink();

    final canGoPrev = currentPage > 1;
    final canGoNext = currentPage < pageCount;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF1E1E20) : AppKendoColors.pureWhite)
            .withValues(alpha: 0.95),
        borderRadius: AppRadius.full,
        border: Border.all(
          color: themeColors.separatorColor.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppKendoColors.pureBlack.withValues(
              alpha: isDark ? 0.40 : 0.18,
            ),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ◀ 前ページボタン
          _buildArrowButton(
            icon: Icons.chevron_left,
            enabled: canGoPrev,
            tooltip: '前のページ',
            onTap: () {
              if (canGoPrev) {
                AppHaptics.selection();
                onPageChanged?.call(currentPage - 1);
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              '$currentPage / $pageCount',
              style: TextStyle(
                fontSize: AppFontSize.bodySmall,
                fontWeight: AppFontWeight.bold,
                color: themeColors.textColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
          // 次ページ ▶ ボタン
          _buildArrowButton(
            icon: Icons.chevron_right,
            enabled: canGoNext,
            tooltip: '次のページ',
            onTap: () {
              if (canGoNext) {
                AppHaptics.selection();
                onPageChanged?.call(currentPage + 1);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildArrowButton({
    required IconData icon,
    required bool enabled,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    final activeColor = themeColors.textColor;
    final disabledColor = themeColors.subTextColor.withValues(alpha: 0.25);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppKendoColors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: AppRadius.full,
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: enabled
                  ? themeColors.primaryAccent.withValues(alpha: 0.12)
                  : AppKendoColors.transparent,
            ),
            child: Icon(
              icon,
              size: 24,
              color: enabled ? activeColor : disabledColor,
            ),
          ),
        ),
      ),
    );
  }
}
