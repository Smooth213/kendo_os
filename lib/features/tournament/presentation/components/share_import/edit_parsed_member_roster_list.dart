import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/domain/share_import/player_roster_matcher.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';

/// 🥋 取り込み選手編集用：道場名簿サジェストリスト
class EditParsedMemberRosterList extends StatelessWidget {
  final List<PlayerModel> roster;
  final String currentName;
  final String? category;
  final Map<String, String>? assignedPlayerMap;
  final Color accentColor;
  final Color textColor;
  final Color subTextColor;
  final Color borderColor;
  final bool isDark;
  final ValueChanged<String> onSelectName;

  const EditParsedMemberRosterList({
    super.key,
    required this.roster,
    required this.currentName,
    this.category,
    this.assignedPlayerMap,
    required this.accentColor,
    required this.textColor,
    required this.subTextColor,
    required this.borderColor,
    required this.isDark,
    required this.onSelectName,
  });

  @override
  Widget build(BuildContext context) {
    if (roster.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Text(
            '該当する選手は見つかりません',
            style: TextStyle(
              fontSize: AppFontSize.caption,
              color: subTextColor,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      itemCount: roster.length,
      separatorBuilder: (_, _) =>
          Divider(height: 1, color: borderColor.withValues(alpha: 0.5)),
      itemBuilder: (context, index) {
        final p = roster[index];
        final isCurrent = currentName.trim() == p.name.trim();
        final assignedInfo =
            assignedPlayerMap?[p.id] ??
            assignedPlayerMap?[PlayerRosterMatcher.normalize(p.name)];
        final isAssigned = assignedInfo != null;
        final isCategoryMatch =
            category == null ||
            PlayerRosterMatcher.matchesCategory(p, category);

        return ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xxs,
          ),
          leading: CircleAvatar(
            radius: AppSpacing.modernValue,
            backgroundColor: isCurrent
                ? accentColor.withValues(alpha: 0.2)
                : (isAssigned
                      ? AppKendoColors.green.withValues(alpha: 0.15)
                      : (isDark
                            ? const Color(0xFF38383A)
                            : const Color(0xFFE5E5EA))),
            child: Text(
              p.name.isNotEmpty ? p.name.substring(0, 1) : '？',
              style: TextStyle(
                fontSize: AppFontSize.small,
                fontWeight: AppFontWeight.bold,
                color: isCurrent
                    ? accentColor
                    : (isAssigned
                          ? AppKendoColors.green
                          : (isCategoryMatch ? textColor : subTextColor)),
              ),
            ),
          ),
          title: Row(
            children: [
              Text(
                p.name,
                style: TextStyle(
                  fontSize: AppFontSize.bodySmall,
                  fontWeight: (isCurrent || isAssigned)
                      ? AppFontWeight.bold
                      : AppFontWeight.regular,
                  color: isCurrent
                      ? accentColor
                      : (isCategoryMatch
                            ? textColor
                            : subTextColor.withValues(alpha: 0.8)),
                ),
              ),
              if (!isCategoryMatch) ...[
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '(他部門)',
                  style: TextStyle(
                    fontSize: AppFontSize.badge,
                    color: subTextColor.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ],
          ),
          subtitle: Row(
            children: [
              Text(
                p.gradeName,
                style: TextStyle(
                  fontSize: AppFontSize.caption,
                  color: subTextColor,
                ),
              ),
              if (isAssigned) ...[
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.subValue,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: AppKendoColors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.tinyValue),
                    border: Border.all(
                      color: AppKendoColors.green.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 11,
                        color: AppKendoColors.green,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '$assignedInfo に登録済',
                        style: TextStyle(
                          fontSize: AppFontSize.badge,
                          fontWeight: AppFontWeight.bold,
                          color: AppKendoColors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          trailing: isCurrent
              ? Icon(Icons.check_circle, size: 18, color: accentColor)
              : (isAssigned
                    ? Icon(
                        Icons.check_circle,
                        size: 16,
                        color: AppKendoColors.green,
                      )
                    : null),
          onTap: () => onSelectName(p.name),
        );
      },
    );
  }
}
