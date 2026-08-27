import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_header.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';

/// 🔍 kendo_os 全体で統一されたモダン＆プレミアムな検索AppBarヘッダー
class AppSearchHeader extends StatelessWidget implements PreferredSizeWidget {
  final String searchQuery;
  final ValueChanged<String> onSearchQueryChanged;
  final VoidCallback onClose;
  final String hintText;
  final bool enableLiquidGlass;

  const AppSearchHeader({
    super.key,
    required this.searchQuery,
    required this.onSearchQueryChanged,
    required this.onClose,
    this.hintText = '選手名・チーム名で検索...',
    this.enableLiquidGlass = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');

    final effectiveBgColor = enableLiquidGlass
        ? AppKendoColors.transparent
        : themeColors.cardBackground;

    return AppHeader(
      backgroundColor: effectiveBgColor,
      centerTitle: false,
      titleWidget: Container(
        height: 40,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          borderRadius: AppRadius.round,
          border: Border.all(
            color: themeColors.primaryAccent.withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Row(
          children: [
            Icon(Icons.search, color: themeColors.primaryAccent, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppTextField(
                autofocus: true,
                controller: TextEditingController(text: searchQuery)
                  ..selection = TextSelection.fromPosition(
                    TextPosition(offset: searchQuery.length),
                  ),
                style: TextStyle(
                  fontSize: AppFontSize.body,
                  fontWeight: AppFontWeight.medium,
                  color: themeColors.textColor,
                ),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: TextStyle(
                    fontSize: AppFontSize.bodySmall,
                    color: themeColors.subTextColor.withValues(alpha: 0.8),
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: onSearchQueryChanged,
              ),
            ),
            if (searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () => onSearchQueryChanged(''),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                  ),
                  child: Icon(
                    Icons.cancel,
                    color: themeColors.subTextColor.withValues(alpha: 0.7),
                    size: 18,
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: onClose,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            minimumSize: const Size(64, 36),
          ),
          child: Text(
            'キャンセル',
            style: TextStyle(
              color: isDark
                  ? AppKendoColors.pureWhite
                  : themeColors.primaryAccent,
              fontWeight: AppFontWeight.bold,
              fontSize: AppFontSize.bodySmall,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
      ],
    );
  }
}
