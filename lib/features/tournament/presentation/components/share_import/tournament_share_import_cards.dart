import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/domain/share_import/player_roster_matcher.dart';
import 'package:kendo_os/features/tournament/domain/share_import/tournament_share_data.dart';
import 'package:kendo_os/features/tournament/domain/share_import/tournament_team_auto_register_service.dart';
import 'package:kendo_os/features/tournament/presentation/components/share_import/edit_parsed_member_dialog.dart';
import 'package:kendo_os/features/tournament/presentation/components/share_import/share_import_edit_sheets.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';

export 'share_import_edit_sheets.dart';
export 'share_import_info_card.dart';

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
  final void Function(String newMatchType)? onMatchTypeUpdated;

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
    this.onMatchTypeUpdated,
  });

  Future<void> _editMatchType(
    BuildContext context,
    String currentMatchType,
  ) async {
    final newType = await ShareImportEditSheets.showMatchTypeSheet(
      context: context,
      teamName: team.teamName,
      currentMatchType: currentMatchType,
      accentColor: accentColor,
      subTextColor: subTextColor,
    );

    if (newType != null && newType.isNotEmpty) {
      onMatchTypeUpdated?.call(newType);
    }
  }

  Future<void> _editCategory(BuildContext context, String currentCat) async {
    final newCat = await ShareImportEditSheets.showCategorySheet(
      context: context,
      teamName: team.teamName,
      currentCategory: currentCat,
      accentColor: accentColor,
      subTextColor: subTextColor,
    );

    if (newCat != null && newCat.isNotEmpty) {
      onCategoryUpdated?.call(newCat);
    }
  }

  Future<void> _editTeamName(BuildContext context) async {
    final newName = await ShareImportEditSheets.showTeamNameSheet(
      context: context,
      currentTeamName: team.teamName,
      accentColor: accentColor,
      textColor: textColor,
      subTextColor: subTextColor,
    );

    if (newName != null && newName.isNotEmpty) {
      onTeamNameUpdated?.call(newName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentCat = TournamentTeamAutoRegisterService.resolveCategory(
      team,
      roster: roster,
    );
    final currentMatchType =
        TournamentTeamAutoRegisterService.determineMatchType(team);

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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
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
                        Icon(
                          Icons.arrow_drop_down,
                          size: 14,
                          color: accentColor,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.subValue),
                InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.tinyValue),
                  onTap: onMatchTypeUpdated != null
                      ? () => _editMatchType(context, currentMatchType)
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.subValue,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppRadius.tinyValue),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currentMatchType,
                          style: TextStyle(
                            fontSize: AppFontSize.caption,
                            fontWeight: AppFontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                        if (onMatchTypeUpdated != null) ...[
                          const SizedBox(width: AppSpacing.xxs),
                          Icon(
                            Icons.arrow_drop_down,
                            size: 14,
                            color: accentColor,
                          ),
                        ],
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
