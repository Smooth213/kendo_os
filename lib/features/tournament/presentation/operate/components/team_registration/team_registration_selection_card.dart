import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 選手選択ダイアログ内の共通カードUI（純粋UIコンポーネント）
class TeamRegistrationSelectionCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final bool isUsed;
  final String usedPos;
  final bool isDark;
  final bool isHelper;
  final bool isBeginner;
  final VoidCallback onTap;

  const TeamRegistrationSelectionCard({
    super.key,
    required this.name,
    required this.subtitle,
    required this.isUsed,
    required this.usedPos,
    required this.isDark,
    this.isHelper = false,
    this.isBeginner = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = context.appColors.textColor;
    final warningColor = context.appColors.warningColor;
    final primaryAccent = context.appColors.primaryAccent;
    final softAccent = context.appColors.softAccent;

    // 状態に応じて色を決定 (助っ人 or 使用済み or 選択可能)
    final Color cardColor;
    final Color borderColor;
    final Color leadingTextColor;
    final Color subtitleColor;

    if (isHelper || isUsed) {
      cardColor = isDark
          ? warningColor.withAlpha(77)
          : warningColor.withAlpha(128);
      borderColor = isDark ? AppKendoColors.transparent : warningColor;
      leadingTextColor = const Color(0xFFFF9800);
      subtitleColor = warningColor;
    } else {
      cardColor = softAccent;
      borderColor = isDark
          ? AppKendoColors.transparent
          : primaryAccent.withValues(alpha: 0.2);
      leadingTextColor = primaryAccent;
      subtitleColor = primaryAccent.withValues(alpha: 0.8);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.medium,
        side: BorderSide(color: borderColor),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: isDark
              ? const Color(0xFF2C2C2E)
              : const Color(0xFFFFFFFF),
          child: Text(
            name.isNotEmpty ? name.substring(0, 1) : '？',
            style: TextStyle(
              color: leadingTextColor,
              fontWeight: AppFontWeight.bold,
            ),
          ),
        ),
        title: Text(
          name,
          style: TextStyle(fontWeight: AppFontWeight.bold, color: textColor),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: AppFontSize.small,
            color: subtitleColor,
            fontWeight: isHelper ? AppFontWeight.bold : AppFontWeight.regular,
          ),
        ),
        trailing: (isHelper || isUsed)
            ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800),
                  borderRadius: AppRadius.small,
                  border: Border.all(color: const Color(0xFFFF9800)),
                ),
                child: Text(
                  '$usedPosと入替',
                  style: TextStyle(
                    color: const Color(0xFFFF9800),
                    fontSize: AppFontSize.caption,
                    fontWeight: AppFontWeight.bold,
                  ),
                ),
              )
            : Icon(Icons.check_circle_outline, color: primaryAccent),
      ),
    );
  }
}
