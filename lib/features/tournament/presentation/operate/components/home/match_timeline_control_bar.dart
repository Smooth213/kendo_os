import 'package:flutter/material.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 🥋 試合タイムライン用 検索・ルール一括変更・ソートコントロールバー（純粋UIコンポーネント）
class MatchTimelineControlBar extends StatelessWidget {
  final bool isSearchVisible;
  final String searchQuery;
  final bool isSortAscending;
  final bool isReadOnlyUI;
  final List<MatchModel> allMatches;
  final bool isDark;
  final ValueChanged<bool> onSearchVisibilityChanged;
  final ValueChanged<String> onSearchQueryChanged;
  final VoidCallback onToggleSort;
  final VoidCallback onBulkRuleEdit;

  const MatchTimelineControlBar({
    super.key,
    required this.isSearchVisible,
    required this.searchQuery,
    required this.isSortAscending,
    required this.isReadOnlyUI,
    required this.allMatches,
    required this.isDark,
    required this.onSearchVisibilityChanged,
    required this.onSearchQueryChanged,
    required this.onToggleSort,
    required this.onBulkRuleEdit,
  });

  @override
  Widget build(BuildContext context) {
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
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () {
                          onSearchQueryChanged('');
                          onSearchVisibilityChanged(false);
                        },
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
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
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
                    onPressed: () =>
                        onSearchVisibilityChanged(!isSearchVisible),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  if (!isReadOnlyUI && allMatches.isNotEmpty) ...[
                    OutlinedButton.icon(
                      onPressed: onBulkRuleEdit,
                      icon: Icon(
                        Icons.gavel,
                        size: 16,
                        color: context.appColors.primaryAccent,
                      ),
                      label: Text(
                        'ルール一括変更',
                        style: TextStyle(
                          fontWeight: AppFontWeight.bold,
                          fontSize: AppFontSize.small,
                          color: context.appColors.primaryAccent,
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
                        minimumSize: const Size(0, 32),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.small,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  OutlinedButton.icon(
                    onPressed: onToggleSort,
                    icon: Icon(
                      isSortAscending
                          ? Icons.arrow_downward
                          : Icons.arrow_upward,
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
                            : context.appColors.primaryAccent,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 0,
                      ),
                      minimumSize: const Size(0, 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.small,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
