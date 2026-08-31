import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/timeline_ui_state_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 🥋 タイムライン用 部門（カテゴリー）クイックフィルターチップバー
class TimelineCategoryFilterChipsBar extends ConsumerWidget {
  final List<MapEntry<String, List<MatchModel>>> categoryEntries;
  final bool isDark;

  const TimelineCategoryFilterChipsBar({
    super.key,
    required this.categoryEntries,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (categoryEntries.length <= 1) {
      return const SizedBox.shrink();
    }

    final selectedCategory = ref.watch(selectedCategoryFilterProvider);
    final int totalAllMatches = categoryEntries.fold(
      0,
      (sum, e) => sum + e.value.length,
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          // 「すべて」チップ
          _buildChip(
            context: context,
            label: 'すべて',
            count: totalAllMatches,
            isSelected: selectedCategory == null,
            onTap: () =>
                ref.read(selectedCategoryFilterProvider.notifier).state = null,
          ),
          const SizedBox(width: AppSpacing.xs),
          // 各カテゴリーのチップ
          ...categoryEntries.map((entry) {
            final categoryName = entry.key;
            final matchCount = entry.value.length;
            final isSelected = selectedCategory == categoryName;

            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: _buildChip(
                context: context,
                label: categoryName,
                count: matchCount,
                isSelected: isSelected,
                onTap: () {
                  if (isSelected) {
                    ref.read(selectedCategoryFilterProvider.notifier).state =
                        null;
                  } else {
                    ref.read(selectedCategoryFilterProvider.notifier).state =
                        categoryName;
                  }
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildChip({
    required BuildContext context,
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final activeBgColor = context.appColors.primaryAccent;
    final inactiveBgColor = isDark
        ? const Color(0xFF2C2C2E)
        : const Color(0xFFE5E5EA);
    final activeTextColor = AppKendoColors.pureWhite;
    final inactiveTextColor = isDark
        ? const Color(0xFFFFFFFF).withValues(alpha: 0.85)
        : const Color(0xFF000000).withValues(alpha: 0.75);

    return Material(
      color: AppKendoColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.full,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.subValue,
          ),
          decoration: BoxDecoration(
            color: isSelected ? activeBgColor : inactiveBgColor,
            borderRadius: AppRadius.full,
            border: Border.all(
              color: isSelected
                  ? activeBgColor
                  : (isDark
                        ? const Color(0xFF38383A)
                        : const Color(0xFFD1D1D6)),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: AppFontSize.caption,
                  fontWeight: isSelected
                      ? AppFontWeight.bold
                      : AppFontWeight.medium,
                  color: isSelected ? activeTextColor : inactiveTextColor,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: 1,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppKendoColors.pureWhite.withValues(alpha: 0.25)
                      : (isDark
                            ? AppKendoColors.pureWhite.withValues(alpha: 0.12)
                            : AppKendoColors.pureBlack.withValues(alpha: 0.08)),
                  borderRadius: AppRadius.full,
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: AppFontSize.badge,
                    fontWeight: AppFontWeight.bold,
                    color: isSelected ? activeTextColor : inactiveTextColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
