import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/domain/share_import/player_roster_matcher.dart';
import 'package:kendo_os/features/tournament/domain/share_import/tournament_share_data.dart';
import 'package:kendo_os/features/tournament/domain/share_import/tournament_team_auto_register_service.dart';
import 'package:kendo_os/features/tournament/presentation/components/share_import/edit_parsed_member_dialog.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/create_tournament/create_tournament_import_team_tile.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_bottom_sheet.dart';
import 'package:kendo_os/shared/widgets/app_chip.dart';
import 'package:kendo_os/shared/widgets/app_switch.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';
import 'package:kendo_os/shared/widgets/glass_button.dart';

/// 🥋 大会新規作成画面用：取り込みチーム・オーダー自動登録プレビューカード
class CreateTournamentImportTeamsCard extends StatelessWidget {
  final List<ParsedTeamOrder> teams;
  final bool isEnabled;
  final ValueChanged<bool> onToggle;
  final List<PlayerModel> roster;
  final ValueChanged<List<ParsedTeamOrder>>? onTeamsUpdated;

  const CreateTournamentImportTeamsCard({
    super.key,
    required this.teams,
    required this.isEnabled,
    required this.onToggle,
    required this.roster,
    this.onTeamsUpdated,
  });

  Future<void> _editMember(
    BuildContext context,
    int teamIndex,
    int memberIndex,
  ) async {
    final team = teams[teamIndex];
    final member = team.members[memberIndex];

    final category = team.category.isNotEmpty
        ? team.category
        : TournamentTeamAutoRegisterService.determineCategory(
            team.teamName,
            members: team.members,
            roster: roster,
          );

    final updatedMember = await EditParsedMemberDialog.show(
      context,
      member: member,
      roster: roster,
      allTeams: teams,
      currentTeamName: team.teamName,
      category: category,
    );

    if (updatedMember != null && onTeamsUpdated != null) {
      final updatedMembers = List<ParsedTeamMember>.from(team.members);
      updatedMembers[memberIndex] = updatedMember;

      final updatedTeams = List<ParsedTeamOrder>.from(teams);
      updatedTeams[teamIndex] = team.copyWith(members: updatedMembers);

      onTeamsUpdated!(updatedTeams);
    }
  }

  Future<void> _editTeamName(BuildContext context, int teamIndex) async {
    final team = teams[teamIndex];
    final controller = TextEditingController(text: team.teamName);
    final accentColor =
        Theme.of(context).extension<AppThemeColors>()?.primaryAccent ??
        AppKendoColors.blue;
    final textColor = context.appColors.textColor;
    final subTextColor = context.appColors.subTextColor;

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

    if (newName != null && newName.isNotEmpty && onTeamsUpdated != null) {
      final updatedTeams = List<ParsedTeamOrder>.from(teams);
      updatedTeams[teamIndex] = team.copyWith(teamName: newName);
      onTeamsUpdated!(updatedTeams);
    }
  }

  Future<void> _editCategory(BuildContext context, int teamIndex) async {
    final team = teams[teamIndex];
    final currentCat = TournamentTeamAutoRegisterService.resolveCategory(
      team,
      roster: roster,
    );

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

    final accentColor =
        Theme.of(context).extension<AppThemeColors>()?.primaryAccent ??
        AppKendoColors.blue;
    final subTextColor = context.appColors.subTextColor;

    final newCat = await showAppBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) {
        return AppBottomSheetContent(
          title: '「${team.teamName}」の部門選択',
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

    if (newCat != null && onTeamsUpdated != null) {
      final updatedTeams = List<ParsedTeamOrder>.from(teams);
      updatedTeams[teamIndex] = team.copyWith(category: newCat);
      onTeamsUpdated!(updatedTeams);
    }
  }

  Future<void> _editMatchType(BuildContext context, int teamIndex) async {
    final team = teams[teamIndex];
    final currentType = TournamentTeamAutoRegisterService.determineMatchType(
      team,
    );
    final candidateMatchTypes =
        TournamentTeamAutoRegisterService.candidateMatchTypes;

    final accentColor =
        Theme.of(context).extension<AppThemeColors>()?.primaryAccent ??
        AppKendoColors.blue;
    final subTextColor = context.appColors.subTextColor;

    final newType = await showAppBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) {
        return AppBottomSheetContent(
          title: '「${team.teamName}」の試合形式',
          titleIcon: Icons.sports_kabaddi,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '試合形式を選択してください：',
                  style: TextStyle(
                    fontSize: AppFontSize.small,
                    color: subTextColor,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: candidateMatchTypes.map((type) {
                    final isSel = currentType == type;
                    return AppChoiceChip(
                      label: Text(type),
                      selected: isSel,
                      selectedColor: accentColor.withValues(alpha: 0.2),
                      onSelected: (_) => Navigator.of(ctx).pop(type),
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

    if (newType != null && onTeamsUpdated != null) {
      final updatedTeams = List<ParsedTeamOrder>.from(teams);
      updatedTeams[teamIndex] = team.copyWith(matchType: newType);
      onTeamsUpdated!(updatedTeams);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (teams.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardBg = isDark
        ? const Color(0xFF1E1E24)
        : AppKendoColors.pureWhite;
    final Color textColor = context.appColors.textColor;
    final Color subTextColor = context.appColors.subTextColor;
    final Color accentColor = context.appColors.primaryAccent;

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppRadius.largeValue),
        border: Border.all(
          color: isEnabled
              ? accentColor.withValues(alpha: 0.3)
              : subTextColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: AppKendoColors.pureBlack.withValues(alpha: 0.05),
                  blurRadius: AppSpacing.sm,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.auto_awesome, color: accentColor, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'オーダー自動一括登録 (${teams.length}チーム)',
                      style: TextStyle(
                        fontSize: AppFontSize.headline,
                        fontWeight: AppFontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    Text(
                      isEnabled ? '大会作成と同時に全チームのオーダーを自動保存' : 'チームの自動登録は行いません',
                      style: TextStyle(
                        fontSize: AppFontSize.small,
                        color: subTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              AppSwitch(
                value: isEnabled,
                onChanged: onToggle,
                activeColor: accentColor,
              ),
            ],
          ),
          if (isEnabled) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(Icons.touch_app, size: 14, color: accentColor),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'チーム名や選手をタップして内容を微調整できます',
                  style: TextStyle(
                    fontSize: AppFontSize.caption,
                    color: accentColor,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: teams.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, teamIndex) {
                final team = teams[teamIndex];
                final category =
                    TournamentTeamAutoRegisterService.resolveCategory(
                      team,
                      roster: roster,
                    );
                final matchType =
                    TournamentTeamAutoRegisterService.determineMatchType(team);
                final matchedMembers = PlayerRosterMatcher.matchTeamMembers(
                  members: team.members,
                  teamCategory: category,
                  roster: roster,
                );

                return CreateTournamentImportTeamTile(
                  team: team,
                  category: category,
                  matchType: matchType,
                  matchedMembers: matchedMembers,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  accentColor: accentColor,
                  isDark: isDark,
                  onEditTeamName: onTeamsUpdated != null
                      ? () => _editTeamName(context, teamIndex)
                      : null,
                  onEditCategory: onTeamsUpdated != null
                      ? () => _editCategory(context, teamIndex)
                      : null,
                  onEditMatchType: onTeamsUpdated != null
                      ? () => _editMatchType(context, teamIndex)
                      : null,
                  onEditMember: onTeamsUpdated != null
                      ? (memberIndex) =>
                            _editMember(context, teamIndex, memberIndex)
                      : null,
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
