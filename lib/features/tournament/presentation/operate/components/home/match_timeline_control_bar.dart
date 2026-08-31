import 'package:flutter/material.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 🥋 試合タイムライン用 検索・ルール一括変更・ソートコントロールバー（純粋UIコンポーネント）
class MatchTimelineControlBar extends StatelessWidget {
  final bool isSearchVisible;
  final String searchQuery;
  final bool isSortAscending;
  final bool isAllExpanded;
  final bool isReadOnlyUI;
  final List<MatchModel> allMatches;
  final bool isDark;
  final ValueChanged<bool> onSearchVisibilityChanged;
  final ValueChanged<String> onSearchQueryChanged;
  final VoidCallback onToggleSort;
  final VoidCallback onToggleExpandAll;
  final VoidCallback onBulkRuleEdit;

  const MatchTimelineControlBar({
    super.key,
    required this.isSearchVisible,
    required this.searchQuery,
    required this.isSortAscending,
    this.isAllExpanded = false,
    required this.isReadOnlyUI,
    required this.allMatches,
    required this.isDark,
    required this.onSearchVisibilityChanged,
    required this.onSearchQueryChanged,
    required this.onToggleSort,
    required this.onToggleExpandAll,
    required this.onBulkRuleEdit,
  });

  @override
  Widget build(BuildContext context) {
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
          // 1段目: タイトル・検索クエリ表示・検索トグル
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
                onPressed: () => onSearchVisibilityChanged(!isSearchVisible),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          // 2段目: 横スクロール可能なアクションボタン群 (ルール変更・ソート・全開閉)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (!isReadOnlyUI && allMatches.isNotEmpty) ...[
                  OutlinedButton.icon(
                    onPressed: onBulkRuleEdit,
                    icon: Icon(
                      Icons.gavel,
                      size: 15,
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
                      minimumSize: const Size(0, 30),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.small,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
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
