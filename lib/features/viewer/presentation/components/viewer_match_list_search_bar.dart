import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '試合リスト',
                style: TextStyle(
                  fontSize: AppFontSize.subhead,
                  fontWeight: AppFontWeight.bold,
                  color: context.appColors.subTextColor,
                ),
              ),
              if (searchQuery.isNotEmpty) ...[
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: context.appColors.primaryAccent.withValues(
                      alpha: 0.15,
                    ),
                    borderRadius: AppRadius.small,
                    border: Border.all(
                      color: context.appColors.primaryAccent.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '「$searchQuery」',
                        style: TextStyle(
                          fontSize: AppFontSize.caption,
                          color: context.appColors.primaryAccent,
                          fontWeight: AppFontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      GestureDetector(
                        onTap: onCloseSearch,
                        child: Icon(
                          Icons.close,
                          size: 14,
                          color: context.appColors.primaryAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              isSearchVisible ? Icons.search_off : Icons.search,
              color: context.appColors.primaryAccent,
              size: 22,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: isSearchVisible ? '検索を閉じる' : '試合を検索',
            onPressed: isSearchVisible ? onCloseSearch : onOpenSearch,
          ),
          const SizedBox(width: AppSpacing.md),
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
