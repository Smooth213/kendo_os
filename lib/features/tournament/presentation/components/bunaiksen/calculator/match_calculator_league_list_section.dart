import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/domain/match_calculator/match_calculation_models.dart';
import 'package:kendo_os/features/tournament/presentation/providers/match_calculator_provider.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_haptics.dart';

/// 🥋 リーグごとの人数個別配分セクション（人数設定に特化）
class MatchCalculatorLeagueListSection extends StatelessWidget {
  final CalculatorSettings settings;
  final MatchCalculatorNotifier notifier;

  const MatchCalculatorLeagueListSection({
    super.key,
    required this.settings,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    final isMultiLeague =
        settings.format == MatchFormatType.multiLeague ||
        settings.format == MatchFormatType.prelimLeagueAndTournament;

    if (!isMultiLeague) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'bunaiksen');

    final hasCustomParticipants = settings.customLeagueParticipants != null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: themeColors.surface,
        borderRadius: AppRadius.medium,
        border: Border.all(
          color: themeColors.subTextColor.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー部
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'リーグ別人数配分 (個別設定)',
                      style: TextStyle(
                        fontSize: AppFontSize.bodySmall,
                        fontWeight: AppFontWeight.bold,
                        color: themeColors.textColor,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'Aリーグ4人・Bリーグ6人のように自由に配分可能',
                      style: TextStyle(
                        fontSize: AppFontSize.caption,
                        color: themeColors.subTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasCustomParticipants)
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: AppSpacing.xxs,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () {
                    AppHaptics.light();
                    notifier.resetLeagueParticipantsToEqual();
                  },
                  child: Text(
                    '均等配分に戻す',
                    style: TextStyle(
                      fontSize: AppFontSize.caption,
                      color: themeColors.primaryAccent,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // 各リーグごとの人数行
          for (int i = 0; i < settings.leagueParticipantCounts.length; i++) ...[
            _buildLeagueRow(
              leagueIndex: i,
              participantCount: settings.leagueParticipantCounts[i],
              themeColors: themeColors,
            ),
            if (i < settings.leagueParticipantCounts.length - 1)
              const SizedBox(height: AppSpacing.xs),
          ],
        ],
      ),
    );
  }

  Widget _buildLeagueRow({
    required int leagueIndex,
    required int participantCount,
    required AppThemeColors themeColors,
  }) {
    final leagueChar = String.fromCharCode(65 + leagueIndex);
    final leagueName = '$leagueCharリーグ';
    final matchCount = (participantCount * (participantCount - 1)) ~/ 2;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: themeColors.surface.withValues(alpha: 0.6),
        borderRadius: AppRadius.small,
        border: Border.all(
          color: themeColors.subTextColor.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: themeColors.primaryAccent.withValues(alpha: 0.15),
                  borderRadius: AppRadius.capsule,
                ),
                child: Text(
                  leagueName,
                  style: TextStyle(
                    fontSize: AppFontSize.caption,
                    fontWeight: AppFontWeight.bold,
                    color: themeColors.primaryAccent,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '総当たり $matchCount試合',
                style: TextStyle(
                  fontSize: AppFontSize.caption,
                  color: themeColors.subTextColor,
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMiniBtn(
                icon: Icons.remove,
                onTap: participantCount > 2
                    ? () {
                        AppHaptics.light();
                        notifier.updateLeagueParticipantCount(
                          leagueIndex,
                          participantCount - 1,
                        );
                      }
                    : null,
                themeColors: themeColors,
              ),
              SizedBox(
                width: 54,
                child: Text(
                  '$participantCount名',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: AppFontSize.bodySmall,
                    fontWeight: AppFontWeight.bold,
                    color: themeColors.textColor,
                  ),
                ),
              ),
              _buildMiniBtn(
                icon: Icons.add,
                onTap: participantCount < 20
                    ? () {
                        AppHaptics.light();
                        notifier.updateLeagueParticipantCount(
                          leagueIndex,
                          participantCount + 1,
                        );
                      }
                    : null,
                themeColors: themeColors,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBtn({
    required IconData icon,
    required VoidCallback? onTap,
    required AppThemeColors themeColors,
  }) {
    final enabled = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.small,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: enabled
                ? themeColors.surface
                : themeColors.surface.withValues(alpha: 0.4),
            borderRadius: AppRadius.small,
            border: Border.all(
              color: themeColors.subTextColor.withValues(
                alpha: enabled ? 0.3 : 0.1,
              ),
            ),
          ),
          child: Icon(
            icon,
            size: 15,
            color: enabled
                ? themeColors.textColor
                : themeColors.subTextColor.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }
}
