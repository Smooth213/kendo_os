import 'package:flutter/material.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 🥋 試合形式設定画面 出場自チーム選択カード（オーダー調整ボタン付き）
class MatchFormatTeamSelectionCard extends StatelessWidget {
  final TeamModel team;
  final bool isSelected;
  final AppThemeColors themeColors;
  final Color textColor;
  final bool isDark;
  final VoidCallback onSelect;
  final VoidCallback onAdjustOrder;

  const MatchFormatTeamSelectionCard({
    super.key,
    required this.team,
    required this.isSelected,
    required this.themeColors,
    required this.textColor,
    required this.isDark,
    required this.onSelect,
    required this.onAdjustOrder,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.large,
        side: BorderSide(
          color: isSelected
              ? themeColors.primaryAccent
              : (isDark ? const Color(0xFF38383A) : const Color(0x33000000)),
          width: isSelected ? 2 : 1.5,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            onTap: onSelect,
            contentPadding: EdgeInsets.only(
              left: 20,
              right: AppSpacing.lg,
              top: AppSpacing.md,
              bottom: isSelected ? 4 : 12,
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
          if (isSelected)
            Padding(
              padding: const EdgeInsets.only(
                left: 20,
                right: AppSpacing.lg,
                bottom: AppSpacing.lg,
                top: AppSpacing.xs,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: onAdjustOrder,
                    icon: Icon(
                      Icons.swap_horizontal_circle,
                      color: themeColors.primaryAccent,
                      size: 20,
                    ),
                    label: Text(
                      'オーダーを調整',
                      style: TextStyle(
                        color: themeColors.primaryAccent,
                        fontWeight: AppFontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: isDark
                          ? const Color(0xFF1C1C1E)
                          : const Color(0xFFFFFFFF),
                      side: BorderSide(
                        color: themeColors.primaryAccent,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.medium,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
