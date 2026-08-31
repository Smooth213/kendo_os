import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 観客席画面用 試合リスト検索・ソート・一括開閉バー
class ViewerMatchListSearchBar extends StatelessWidget {
  final bool isSearchVisible;
  final String searchQuery;
  final bool isSortAscending;
  final bool isAllExpanded;
  final ValueChanged<String> onSearchQueryChanged;
  final VoidCallback onOpenSearch;
  final VoidCallback onCloseSearch;
  final VoidCallback onToggleSort;
  final VoidCallback onToggleExpandAll;

  const ViewerMatchListSearchBar({
    super.key,
    required this.isSearchVisible,
    required this.searchQuery,
    required this.isSortAscending,
    this.isAllExpanded = false,
    required this.onSearchQueryChanged,
    required this.onOpenSearch,
    required this.onCloseSearch,
    required this.onToggleSort,
    required this.onToggleExpandAll,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1段目: タイトル・検索クエリ・検索ボタン
          Row(
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
                      color: isDark
                          ? const Color(0xFFFFFFFF)
                          : const Color(0xDE000000),
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
              IconButton(
                icon: Icon(
                  isSearchVisible ? Icons.search_off : Icons.search,
                  color: isDark
                      ? const Color(0xFFFFFFFF)
                      : context.appColors.primaryAccent,
                  size: 22,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: isSearchVisible ? '検索を閉じる' : '試合を検索',
                onPressed: isSearchVisible ? onCloseSearch : onOpenSearch,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          // 2段目: ソート・全開閉ボタン
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: onToggleSort,
                  icon: Icon(
                    isSortAscending ? Icons.arrow_downward : Icons.arrow_upward,
                    size: 15,
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
                          : context.appColors.primaryAccent,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.compact,
                      vertical: 0,
                    ),
                    minimumSize: const Size(0, 30),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.small,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                OutlinedButton.icon(
                  onPressed: onToggleExpandAll,
                  icon: Icon(
                    isAllExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                  ),
                  label: Text(
                    isAllExpanded ? '全て閉じる' : '全て開く',
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
                          : context.appColors.primaryAccent,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.compact,
                      vertical: 0,
                    ),
                    minimumSize: const Size(0, 30),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.small,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
