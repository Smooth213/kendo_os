import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/domain/share_import/player_roster_matcher.dart';
import 'package:kendo_os/features/tournament/domain/share_import/tournament_share_data.dart';
import 'package:kendo_os/features/tournament/domain/share_import/tournament_team_auto_register_service.dart';
import 'package:kendo_os/features/tournament/presentation/components/share_import/edit_parsed_member_dialog.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';
import 'package:kendo_os/shared/widgets/glass_button.dart';

/// 🥋 共有インポート用：情報カード共通ウィジェット
class ShareImportInfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final Color cardColor;
  final Color textColor;
  final Color subTextColor;
  final List<Widget> children;

  const ShareImportInfoCard({
    super.key,
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.cardColor,
    required this.textColor,
    required this.subTextColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppRadius.largeValue),
        border: Border.all(color: accentColor.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 20),
              const SizedBox(width: AppSpacing.xs),
              Text(
                title,
                style: TextStyle(
                  fontSize: AppFontSize.headline,
                  fontWeight: AppFontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          ...children,
        ],
      ),
    );
  }
}

/// 🥋 共有インポート用：チームオーダー表示カードウィジェット
class ShareImportTeamSection extends StatelessWidget {
  final ParsedTeamOrder team;
  final Color accentColor;
  final Color textColor;
  final Color subTextColor;
  final List<PlayerModel>? roster;
  final List<ParsedTeamOrder>? allTeams;
  final void Function(int memberIndex, ParsedTeamMember updated)?
  onMemberUpdated;
  final void Function(String newName)? onTeamNameUpdated;
  final void Function(String newCategory)? onCategoryUpdated;

  const ShareImportTeamSection({
    super.key,
    required this.team,
    required this.accentColor,
    required this.textColor,
    required this.subTextColor,
    this.roster,
    this.allTeams,
    this.onMemberUpdated,
    this.onTeamNameUpdated,
    this.onCategoryUpdated,
  });

  Future<void> _editCategory(BuildContext context, String currentCat) async {
    final candidateCategories = [
      '小学生低学年の部',
      '小学生高学年の部',
      '小学生の部',
      '中学生の部',
      '中学生男子の部',
      '中学生女子の部',
      '高校生の部',
      '一般の部',
    ];

    final newCat = await showAppBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) {
        return AppBottomSheetContent(
          title: '「${team.teamName}」のカテゴリ（部門）',
          titleIcon: Icons.category,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '所属する部門を選択してください：',
                  style: TextStyle(
                    fontSize: AppFontSize.small,
                    color: subTextColor,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: candidateCategories.map((cat) {
                    final isSel = currentCat == cat;
                    return AppChoiceChip(
                      label: Text(cat),
                      selected: isSel,
                      selectedColor: accentColor.withValues(alpha: 0.2),
                      onSelected: (_) => Navigator.of(ctx).pop(cat),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        );
      },
    );

    if (newCat != null && newCat.isNotEmpty) {
      onCategoryUpdated?.call(newCat);
    }
  }

  Future<void> _editTeamName(BuildContext context) async {
    final controller = TextEditingController(text: team.teamName);
    final newName = await showAppBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AppBottomSheetContent(
        title: 'チーム名の変更',
        titleIcon: Icons.edit,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '新しいチーム名を入力してください',
                style: TextStyle(
                  fontSize: AppFontSize.small,
                  color: subTextColor,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                controller: controller,
                autofocus: true,
                style: TextStyle(
                  fontSize: AppFontSize.body,
                  fontWeight: AppFontWeight.bold,
                  color: textColor,
                ),
                decoration: const InputDecoration(
                  labelText: 'チーム名',
                  hintText: '例: 低学年A, 中学生男子',
                  prefixIcon: Icon(Icons.groups),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: GlassButton(
                  onPressed: () {
                    final val = controller.text.trim();
                    if (val.isNotEmpty) Navigator.of(ctx).pop(val);
                  },
                  color: accentColor,
                  icon: Icons.check,
                  label: '変更を保存',
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
    if (newName != null && newName.isNotEmpty) {
      onTeamNameUpdated?.call(newName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentCat = team.category.isNotEmpty
        ? team.category
        : TournamentTeamAutoRegisterService.determineCategory(
            team.teamName,
            members: team.members,
            roster: roster,
          );

    final matchedMembers = roster != null
        ? PlayerRosterMatcher.matchTeamMembers(
            members: team.members,
            teamCategory: currentCat,
            roster: roster!,
          )
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(AppRadius.smallValue),
                onTap: onTeamNameUpdated != null
                    ? () => _editTeamName(context)
                    : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.smallValue),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        team.teamName,
                        style: TextStyle(
                          fontSize: AppFontSize.body,
                          fontWeight: AppFontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                      if (onTeamNameUpdated != null) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Icon(Icons.edit, size: 12, color: accentColor),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.subValue),
              InkWell(
                borderRadius: BorderRadius.circular(AppRadius.tinyValue),
                onTap: () => _editCategory(context, currentCat),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.subValue,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.tinyValue),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currentCat,
                        style: TextStyle(
                          fontSize: AppFontSize.caption,
                          fontWeight: AppFontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      Icon(Icons.arrow_drop_down, size: 14, color: accentColor),
                    ],
                  ),
                ),
              ),
              if (onMemberUpdated != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '(タップで編集)',
                  style: TextStyle(
                    fontSize: AppFontSize.caption,
                    color: subTextColor,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.subValue),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.subValue,
            children: List.generate(team.members.length, (index) {
              final rawMember = team.members[index];
              final matched = matchedMembers?[index];

              final isMatched = matched?.isMatched ?? false;
              final displayName = matched?.displayName ?? rawMember.name;
              final gradeInfo = matched?.gradeInfo;

              return Material(
                color: AppKendoColors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.mediumValue),
                  onTap: onMemberUpdated != null && roster != null
                      ? () async {
                          final updated = await EditParsedMemberDialog.show(
                            context,
                            member: rawMember,
                            roster: roster!,
                            allTeams: allTeams,
                            currentTeamName: team.teamName,
                            category: currentCat,
                          );
                          if (updated != null) {
                            onMemberUpdated!(index, updated);
                          }
                        }
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: isMatched
                          ? AppKendoColors.green.withValues(alpha: 0.08)
                          : AppKendoColors.transparent,
                      border: Border.all(
                        color: isMatched
                            ? AppKendoColors.green.withValues(alpha: 0.5)
                            : subTextColor.withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(
                        AppRadius.mediumValue,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (roster != null) ...[
                          Icon(
                            isMatched ? Icons.check_circle : Icons.help_outline,
                            size: 14,
                            color: isMatched
                                ? AppKendoColors.green
                                : AppKendoColors.amber,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                        ],
                        Text(
                          rawMember.position,
                          style: TextStyle(
                            fontSize: AppFontSize.caption,
                            fontWeight: AppFontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.subValue),
                        Text(
                          displayName,
                          style: TextStyle(
                            fontSize: AppFontSize.body,
                            fontWeight: isMatched
                                ? AppFontWeight.bold
                                : AppFontWeight.regular,
                            color: textColor,
                          ),
                        ),
                        if (gradeInfo != null) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            '($gradeInfo)',
                            style: TextStyle(
                              fontSize: AppFontSize.caption,
                              color: AppKendoColors.green,
                              fontWeight: AppFontWeight.bold,
                            ),
                          ),
                        ] else if (roster != null && !isMatched) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            '(未登録)',
                            style: TextStyle(
                              fontSize: AppFontSize.caption,
                              color: AppKendoColors.amber,
                            ),
                          ),
                        ],
                        if (onMemberUpdated != null) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Icon(
                            Icons.edit,
                            size: 11,
                            color: subTextColor.withValues(alpha: 0.6),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
