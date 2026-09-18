import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 🥋 試合形式設定画面 出場自チーム選択カード（スワイプ編集・削除対応）
class MatchFormatTeamSelectionCard extends StatelessWidget {
  final TeamModel team;
  final bool isSelected;
  final AppThemeColors themeColors;
  final Color textColor;
  final bool isDark;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onAdjustOrder;

  const MatchFormatTeamSelectionCard({
    super.key,
    required this.team,
    required this.isSelected,
    required this.themeColors,
    required this.textColor,
    required this.isDark,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
    this.onAdjustOrder,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ClipRRect(
        borderRadius: AppRadius.large,
        child: Slidable(
          key: ValueKey(team.id),
          endActionPane: ActionPane(
            motion: const ScrollMotion(),
            extentRatio: 0.45,
            children: [
              SlidableAction(
                onPressed: (_) => onEdit(),
                backgroundColor: AppKendoColors.blueAccent,
                foregroundColor: AppKendoColors.pureWhite,
                icon: Icons.edit,
                label: '編集',
              ),
              SlidableAction(
                onPressed: (_) => onDelete(),
                backgroundColor: AppKendoColors.redAccent,
                foregroundColor: AppKendoColors.pureWhite,
                icon: Icons.delete_outline,
                label: '削除',
              ),
            ],
          ),
          child: Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.large,
              side: BorderSide(
                color: isSelected
                    ? themeColors.primaryAccent
                    : (isDark
                          ? const Color(0xFF38383A)
                          : const Color(0x33000000)),
                width: isSelected ? 2 : 1.5,
              ),
            ),
            child: ListTile(
              onTap: onSelect,
              contentPadding: const EdgeInsets.only(
                left: 20,
                right: AppSpacing.lg,
                top: AppSpacing.md,
                bottom: AppSpacing.md,
              ),
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: isSelected
                    ? themeColors.softAccent
                    : (isDark
                          ? const Color(0xFF2C2C2E)
                          : const Color(0xFFF2F2F7)),
                child: Icon(
                  Icons.shield,
                  color: isSelected
                      ? themeColors.primaryAccent
                      : context.appColors.subTextColor,
                  size: 24,
                ),
              ),
              title: Text(
                team.teamName,
                style: TextStyle(
                  fontWeight: AppFontWeight.bold,
                  fontSize: AppFontSize.headline,
                  color: isSelected ? themeColors.primaryAccent : textColor,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  '${team.matchType} / 選手: ${team.playerNames.where((n) => n.isNotEmpty).join(", ")}',
                  style: TextStyle(
                    fontSize: AppFontSize.small,
                    color: isSelected
                        ? themeColors.primaryAccent.withValues(alpha: 0.8)
                        : context.appColors.subTextColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              trailing: Icon(
                isSelected ? Icons.check_circle : Icons.circle_outlined,
                color: isSelected
                    ? themeColors.primaryAccent
                    : (isDark
                          ? const Color(0xFFFFFFFF)
                          : const Color(0x33000000)),
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
