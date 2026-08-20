import 'package:flutter/material.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';

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
          if (!isSearchVisible)
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
                      enabledBorder: OutlineInputBorder(
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
                        onPressed: () {
                          onSearchQueryChanged('');
                          onSearchVisibilityChanged(false);
                        },
                      ),
                    ),
                    onChanged: onSearchQueryChanged,
                  ),
                ),
              ),
            ),

          if (!isSearchVisible)
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.search,
                        color: context.appColors.primaryAccent,
                        size: 22,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => onSearchVisibilityChanged(true),
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
