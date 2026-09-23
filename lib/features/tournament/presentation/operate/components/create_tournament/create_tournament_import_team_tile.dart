import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/domain/share_import/player_roster_matcher.dart';
import 'package:kendo_os/features/tournament/domain/share_import/tournament_share_data.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';

/// 🥋 大会新規作成・取り込みチーム単一カード行
class CreateTournamentImportTeamTile extends StatelessWidget {
  final ParsedTeamOrder team;
  final String category;
  final String matchType;
  final List<MatchedTeamMember> matchedMembers;
  final Color textColor;
  final Color subTextColor;
  final Color accentColor;
  final bool isDark;
  final VoidCallback? onEditTeamName;
  final VoidCallback? onEditCategory;
  final VoidCallback? onEditMatchType;
  final void Function(int memberIndex)? onEditMember;

  const CreateTournamentImportTeamTile({
    super.key,
    required this.team,
    required this.category,
    required this.matchType,
    required this.matchedMembers,
    required this.textColor,
    required this.subTextColor,
    required this.accentColor,
    required this.isDark,
    this.onEditTeamName,
    this.onEditCategory,
    this.onEditMatchType,
    this.onEditMember,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF282830) : const Color(0xFFF7F7FA),
        borderRadius: BorderRadius.circular(AppRadius.mediumValue),
        border: Border.all(color: subTextColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.tinyValue),
                  onTap: onEditTeamName,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: AppSpacing.xxs,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            team.teamName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: AppFontSize.body,
                              fontWeight: AppFontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Icon(Icons.edit, size: 13, color: subTextColor),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              InkWell(
                borderRadius: BorderRadius.circular(AppRadius.tinyValue),
                onTap: onEditCategory,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.subValue,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.tinyValue),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        category,
                        style: TextStyle(
                          fontSize: AppFontSize.caption,
                          color: accentColor,
                          fontWeight: AppFontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      Icon(Icons.arrow_drop_down, size: 14, color: accentColor),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              InkWell(
                borderRadius: BorderRadius.circular(AppRadius.tinyValue),
                onTap: onEditMatchType,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.subValue,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF33333E)
                        : const Color(0xFFE8E8EE),
                    borderRadius: BorderRadius.circular(AppRadius.tinyValue),
                    border: Border.all(
                      color: subTextColor.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        matchType,
                        style: TextStyle(
                          fontSize: AppFontSize.caption,
                          color: textColor,
                          fontWeight: AppFontWeight.bold,
                        ),
                      ),
                      if (onEditMatchType != null) ...[
                        const SizedBox(width: AppSpacing.xxs),
                        Icon(
                          Icons.arrow_drop_down,
                          size: 14,
                          color: subTextColor,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.subValue),
          Wrap(
            spacing: AppSpacing.subValue,
            runSpacing: AppSpacing.xs,
            children: List.generate(team.members.length, (memberIndex) {
              final m = matchedMembers[memberIndex];

              return Material(
                color: AppKendoColors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.tinyValue),
                  onTap: onEditMember != null
                      ? () => onEditMember!(memberIndex)
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.subValue,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: m.isMatched
                          ? AppKendoColors.green.withValues(alpha: 0.08)
                          : AppKendoColors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.tinyValue),
                      border: Border.all(
                        color: m.isMatched
                            ? AppKendoColors.green.withValues(alpha: 0.4)
                            : subTextColor.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          m.position,
                          style: TextStyle(
                            fontSize: AppFontSize.caption,
                            fontWeight: AppFontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          m.displayName,
                          style: TextStyle(
                            fontSize: AppFontSize.caption,
                            color: textColor,
                            fontWeight: m.isMatched
                                ? AppFontWeight.bold
                                : AppFontWeight.regular,
                          ),
                        ),
                        if (m.gradeInfo != null) ...[
                          const SizedBox(width: AppSpacing.xxs),
                          Text(
                            '(${m.gradeInfo})',
                            style: TextStyle(
                              fontSize: AppFontSize.badge,
                              color: AppKendoColors.green,
                              fontWeight: AppFontWeight.bold,
                            ),
                          ),
                        ],
                        const SizedBox(width: AppSpacing.xxs),
                        Icon(
                          Icons.edit,
                          size: AppFontSize.badge,
                          color: subTextColor.withValues(alpha: 0.7),
                        ),
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
