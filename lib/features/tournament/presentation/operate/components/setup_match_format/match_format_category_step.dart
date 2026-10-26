import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_category_preview_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_team_selection_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/team_registration/team_registration_category_parser.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/team_repository.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/common/category_cascade_selector_view.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

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
  final ValueChanged<TeamModel> onEditTeam;
  final ValueChanged<TeamModel> onDeleteTeam;
  final VoidCallback onNavigateToTeamRegistration;
  final AppThemeColors themeColors;
  final bool isDark;
  final Widget Function(String) buildSectionTitle;

  final String customCategoryName;
  final ValueChanged<String>? onCustomCategoryChanged;

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
    required this.onEditTeam,
    required this.onDeleteTeam,
    required this.onNavigateToTeamRegistration,
    required this.themeColors,
    required this.isDark,
    required this.buildSectionTitle,
    this.customCategoryName = '',
    this.onCustomCategoryChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textColor = context.appColors.textColor;
    final teamsAsync = ref.watch(registeredTeamsProvider(tournamentId));
    final allRegisteredTeams = teamsAsync.valueOrNull ?? [];

    // 「その他」に属する登録済みチームのカテゴリ名と件数を集計
    final otherCategoryCounts = <String, int>{};
    for (final t in allRegisteredTeams) {
      final parsed = TeamRegistrationCategoryParser.parseCategoryToState(
        t.category,
      );
      if (parsed.majorCategory == 'その他') {
        final catKey = t.category.trim().isEmpty ? 'その他の部' : t.category.trim();
        otherCategoryCounts[catKey] = (otherCategoryCounts[catKey] ?? 0) + 1;
      }
    }

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

        // カテゴリ選択（大分類 ＋ 連動サブコンテナ）
        buildSectionTitle('1. 対象カテゴリを選択'),
        CategoryCascadeSelectorView(
          selectedMajorCategory: selectedMajorCategory,
          selectedMinorCategory: selectedMinorCategory,
          customCategoryName: customCategoryName,
          registeredOtherCategoryCounts: otherCategoryCounts,
          themeColors: themeColors,
          onCategoryChanged:
              ({
                required majorCategory,
                required minorCategory,
                customCategoryName,
              }) {
                onCategoryChanged(majorCategory, minorCategory);
                if (customCategoryName != null &&
                    onCustomCategoryChanged != null) {
                  onCustomCategoryChanged!(customCategoryName);
                }
              },
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
            Expanded(child: buildSectionTitle('3. 出場する自チームを選択')),
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

        teamsAsync.when(
          data: (teams) {
            final filteredTeams = teams.where((t) {
              // 1. 完全一致
              if (t.category == category) return true;

              // 2. 「の部」のゆらぎ吸収（例:「その他」と「その他の部」）
              final cleanTeamCat = t.category.replaceAll('の部', '').trim();
              final cleanTargetCat = category.replaceAll('の部', '').trim();
              if (cleanTeamCat.isNotEmpty && cleanTeamCat == cleanTargetCat) {
                return true;
              }

              // 3. 大分類が「その他」の場合、登録済み「その他」系チームを包括的にマッチ
              if (selectedMajorCategory == 'その他') {
                final parsed =
                    TeamRegistrationCategoryParser.parseCategoryToState(
                      t.category,
                    );
                if (parsed.majorCategory == 'その他') {
                  return true;
                }
              }

              return false;
            }).toList();

            // 選択中のカテゴリと完全一致するものを先頭にソート
            filteredTeams.sort((a, b) {
              final aClean = a.category.replaceAll('の部', '').trim();
              final bClean = b.category.replaceAll('の部', '').trim();
              final targetClean = category.replaceAll('の部', '').trim();
              final aMatch = a.category == category || aClean == targetClean;
              final bMatch = b.category == category || bClean == targetClean;
              if (aMatch && !bMatch) return -1;
              if (!aMatch && bMatch) return 1;
              return 0;
            });

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
                  onAdjustOrder: () => onEditTeam(team),
                  onEdit: () => onEditTeam(team),
                  onDelete: () => onDeleteTeam(team),
                );
              }).toList(),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.xxl),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, s) => Text('エラー: $e', style: TextStyle(color: textColor)),
        ),
      ],
    );
  }
}
