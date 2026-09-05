import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_haptics.dart';

/// 🥋 大会クイックハブ内の機能グリッドタイル
class TournamentQuickHubTile extends StatelessWidget {
  final AppThemeColors themeColors;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final int badgeCount;

  const TournamentQuickHubTile({
    super.key,
    required this.themeColors,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        AppHaptics.light();
        onTap();
      },
      borderRadius: AppRadius.large,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: themeColors.inputBackground,
          borderRadius: AppRadius.large,
          border: Border.all(
            color: themeColors.separatorColor.withValues(alpha: 0.6),
            width: 0.8,
          ),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: AppRadius.small,
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: AppFontSize.subhead,
                    fontWeight: AppFontWeight.bold,
                    color: themeColors.textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: AppFontSize.caption,
                    color: themeColors.subTextColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            if (badgeCount > 0)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.subValue,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: AppKendoColors.redAccent,
                    borderRadius: AppRadius.full,
                    border: Border.all(
                      color: AppKendoColors.pureWhite,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    badgeCount > 99 ? '99+' : '$badgeCount',
                    style: const TextStyle(
                      color: AppKendoColors.pureWhite,
                      fontSize: AppFontSize.badge,
                      fontWeight: AppFontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
