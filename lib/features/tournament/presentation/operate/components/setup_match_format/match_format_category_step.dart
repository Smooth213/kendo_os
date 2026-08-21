import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_category_preview_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_team_selection_card.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/team_repository.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';

/// 大会カテゴリおよび自チーム選択ステップ（第1ページ）
class MatchFormatCategoryStep extends ConsumerWidget {
  final String tournamentId;
  final String category;
  final String selectedMajorCategory;
  final String selectedMinorCategory;
  final String? selectedTeamId;
  final List<String> majorCategories;
  final List<String> Function(String) getMinorCategories;
  final void Function(String major, String minor) onCategoryChanged;
  final ValueChanged<TeamModel> onTeamSelected;
  final ValueChanged<TeamModel> onAdjustOrder;
  final VoidCallback onNavigateToTeamRegistration;
  final AppThemeColors themeColors;
  final bool isDark;
  final Widget Function(String) buildSectionTitle;

  const MatchFormatCategoryStep({
    super.key,
    required this.tournamentId,
    required this.category,
    required this.selectedMajorCategory,
    required this.selectedMinorCategory,
    required this.selectedTeamId,
    required this.majorCategories,
    required this.getMinorCategories,
    required this.onCategoryChanged,
    required this.onTeamSelected,
    required this.onAdjustOrder,
    required this.onNavigateToTeamRegistration,
    required this.themeColors,
    required this.isDark,
    required this.buildSectionTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textColor = context.appColors.textColor;

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      children: [
        Text(
          '対象のカテゴリと\n自チームを選んでください',
          style: TextStyle(
            fontSize: AppFontSize.display,
            fontWeight: AppFontWeight.bold,
            height: 1.4,
            color: textColor,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),

        // カテゴリ大分類
        buildSectionTitle('1. 対象カテゴリを選択（大分類）'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: majorCategories
              .map(
                (cat) => AppChoiceChip(
                  label: Text(cat),
                  selected: selectedMajorCategory == cat,
                  onSelected: (s) {
                    if (s) {
                      onCategoryChanged(cat, '全体');
                    }
                  },
                ),
              )
              .toList(),
        ),
        const SizedBox(height: AppSpacing.xl),

        // カテゴリ小分類
        buildSectionTitle('2. 対象カテゴリを選択（小分類）'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: getMinorCategories(selectedMajorCategory).map((cat) {
            String label = cat;
            if (selectedMajorCategory == '小学生') {
              if (cat == '低学年') label = '低学年 (1-4年)';
              if (cat == '高学年') label = '高学年 (5-6年)';
            }
            return AppChoiceChip(
              label: Text(label),
              selected: selectedMinorCategory == cat,
              onSelected: (s) {
                if (s) {
                  onCategoryChanged(selectedMajorCategory, cat);
                }
              },
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.lg),

        // プレビュー表示
        MatchFormatCategoryPreviewCard(
          category: category,
          themeColors: themeColors,
          textColor: textColor,
        ),

        const SizedBox(height: 40),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            buildSectionTitle('3. 出場する自チームを選択'),
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: TextButton.icon(
                onPressed: onNavigateToTeamRegistration,
                icon: const Icon(Icons.group_add, size: 18),
                label: const Text(
                  'チームを追加・編集',
                  style: TextStyle(
                    fontWeight: AppFontWeight.bold,
                    fontSize: AppFontSize.bodySmall,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: themeColors.primaryAccent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                ),
              ),
            ),
          ],
        ),

        ref
            .watch(registeredTeamsProvider(tournamentId))
            .when(
              data: (teams) {
                final filteredTeams = teams
                    .where((t) => t.category == category)
                    .toList();

                if (filteredTeams.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xxl,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2C2C2E)
                          : const Color(0xFFF2F2F7),
                      borderRadius: AppRadius.large,
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF38383A)
                            : const Color(0x33000000),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.group_off_outlined,
                          color: context.appColors.subTextColor,
                          size: 40,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          '「$category」のチームが未登録です。\n右上の「チームを追加・編集」から\n登録を行ってください。',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: context.appColors.subTextColor,
                            fontSize: AppFontSize.bodySmall,
                            fontWeight: AppFontWeight.bold,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: filteredTeams.map((team) {
                    final isSelected = selectedTeamId == team.id;
                    return MatchFormatTeamSelectionCard(
                      team: team,
                      isSelected: isSelected,
                      themeColors: themeColors,
                      textColor: textColor,
                      isDark: isDark,
                      onSelect: () => onTeamSelected(team),
                      onAdjustOrder: () => onAdjustOrder(team),
                    );
                  }).toList(),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.xxl),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, s) =>
                  Text('エラー: $e', style: TextStyle(color: textColor)),
            ),
      ],
    );
  }
}
