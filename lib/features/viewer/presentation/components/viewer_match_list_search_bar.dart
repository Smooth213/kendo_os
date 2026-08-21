import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';

/// 観客席画面用 試合リスト検索・ソートバー
class ViewerMatchListSearchBar extends StatelessWidget {
  final bool isSearchVisible;
  final String searchQuery;
  final bool isSortAscending;
  final ValueChanged<String> onSearchQueryChanged;
  final VoidCallback onOpenSearch;
  final VoidCallback onCloseSearch;
  final VoidCallback onToggleSort;

  const ViewerMatchListSearchBar({
    super.key,
    required this.isSearchVisible,
    required this.searchQuery,
    required this.isSortAscending,
    required this.onSearchQueryChanged,
    required this.onOpenSearch,
    required this.onCloseSearch,
    required this.onToggleSort,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (!isSearchVisible)
            Text(
              '試合リスト',
              style: TextStyle(
                fontSize: AppFontSize.subhead,
                fontWeight: AppFontWeight.bold,
                color: context.appColors.subTextColor,
              ),
            ),
          if (isSearchVisible)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: SizedBox(
                  height: 32,
                  child: AppTextField(
                    autofocus: true,
                    style: TextStyle(
                      fontSize: AppFontSize.bodySmall,
                      color: context.appColors.textColor,
                    ),
                    decoration: InputDecoration(
                      hintText: '選手名・チーム名で検索...',
                      hintStyle: TextStyle(
                        fontSize: AppFontSize.small,
                        color: context.appColors.subTextColor,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 0,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF2C2C2E)
                          : context.appColors.inputBackground,
                      border: OutlineInputBorder(
                        borderRadius: AppRadius.small,
                        borderSide: BorderSide(
                          color: isDark
                              ? const Color(0xFF38383A)
                              : const Color(0x33000000),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: AppRadius.small,
                        borderSide: BorderSide(
                          color: context.appColors.primaryAccent,
                        ),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: onCloseSearch,
                      ),
                    ),
                    onChanged: onSearchQueryChanged,
                  ),
                ),
              ),
            ),
          if (!isSearchVisible) const Spacer(),
          if (!isSearchVisible)
            IconButton(
              icon: Icon(
                Icons.search,
                color: context.appColors.primaryAccent,
                size: 22,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onOpenSearch,
            ),
          if (!isSearchVisible) const SizedBox(width: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: onToggleSort,
            icon: Icon(
              isSortAscending ? Icons.arrow_downward : Icons.arrow_upward,
              size: 16,
            ),
            label: Text(
              isSortAscending ? 'カテゴリ昇順' : 'カテゴリ降順',
              style: const TextStyle(
                fontWeight: AppFontWeight.bold,
                fontSize: AppFontSize.small,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: context.appColors.primaryAccent,
              side: BorderSide(
                color: isDark
                    ? const Color(0xFF38383A)
                    : context.appColors.subTextColor,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 0,
              ),
              minimumSize: const Size(0, 32),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.small),
            ),
          ),
        ],
      ),
    );
  }
}
