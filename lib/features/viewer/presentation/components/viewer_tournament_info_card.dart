import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 🥋 観客席用 大会情報カード（純粋UIコンポーネント）
class ViewerTournamentInfoCard extends StatelessWidget {
  final TournamentModel tournament;

  const ViewerTournamentInfoCard({super.key, required this.tournament});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
    final cardColor = themeColors.cardBackground;
    final borderColor = context.appColors.separatorColor;
    final textColor = context.appColors.textColor;
    final subTextColor = isDark
        ? const Color(0xFF8E8E93)
        : context.appColors.textColor;
    final iconBgColor = isDark
        ? context.appColors.warningColor.withValues(alpha: 0.3)
        : context.appColors.warningColor;
    final noteBgColor = isDark
        ? const Color(0xFF2C2C2E)
        : context.appColors.cardBackground;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.medium,
        side: BorderSide(color: borderColor, width: isDark ? 0.5 : 1.0),
      ),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.roundValue),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    color: AppKendoColors.amber,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    tournament.name,
                    style: TextStyle(
                      fontSize: AppFontSize.headline,
                      fontWeight: AppFontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Divider(height: 1, color: borderColor),
            ),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: isDark
                      ? const Color(0xFF8E8E93)
                      : context.appColors.textColor.withValues(alpha: 0.6),
                  size: 16,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  DateFormat('yyyy年MM月dd日').format(tournament.date),
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: AppFontSize.bodySmall,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Icon(
                  Icons.location_on,
                  color: isDark
                      ? const Color(0xFF8E8E93)
                      : context.appColors.textColor.withValues(alpha: 0.6),
                  size: 16,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    tournament.venue,
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: AppFontSize.bodySmall,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (tournament.notes.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: noteBgColor,
                  borderRadius: AppRadius.small,
                ),
                child: Text(
                  tournament.notes,
                  style: TextStyle(
                    color: textColor,
                    fontSize: AppFontSize.bodySmall,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
