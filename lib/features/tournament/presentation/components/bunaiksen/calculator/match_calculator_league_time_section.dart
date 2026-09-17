import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/domain/match_calculator/match_calculation_models.dart';
import 'package:kendo_os/features/tournament/presentation/providers/match_calculator_provider.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_haptics.dart';

/// 🥋 リーグごとの試合時間（個別設定ブロック）
class MatchCalculatorLeagueTimeSection extends StatelessWidget {
  final CalculatorSettings settings;
  final MatchCalculatorNotifier notifier;
  final AppThemeColors themeColors;
  final bool isPrelimWithTournament;

  const MatchCalculatorLeagueTimeSection({
    super.key,
    required this.settings,
    required this.notifier,
    required this.themeColors,
    required this.isPrelimWithTournament,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'リーグごとの試合時間 (個別設定)',
          style: TextStyle(
            fontSize: AppFontSize.bodySmall,
            fontWeight: AppFontWeight.bold,
            color: themeColors.textColor,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          '学年・カテゴリに合わせて各リーグの試合時間を自由に設定できます',
          style: TextStyle(
            fontSize: AppFontSize.caption,
            color: themeColors.subTextColor,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // 各リーグカード
        for (int i = 0; i < settings.leagueParticipantCounts.length; i++) ...[
          _buildLeagueTimeCard(
            leagueIndex: i,
            durationMinutes: settings.getLeagueMatchDuration(i),
          ),
          if (i < settings.leagueParticipantCounts.length - 1)
            const SizedBox(height: AppSpacing.xs),
        ],

        // 予選L＋決勝Tの場合の決勝トーナメントカード
        if (isPrelimWithTournament) ...[
          const SizedBox(height: AppSpacing.sm),
          _buildTournamentTimeCard(
            durationMinutes: settings.tournamentMatchDuration,
          ),
        ],
      ],
    );
  }

  Widget _buildLeagueTimeCard({
    required int leagueIndex,
    required double durationMinutes,
  }) {
    final leagueChar = String.fromCharCode(65 + leagueIndex);
    final leagueName = '$leagueCharリーグ';
    final timeStr = CalculatorSettings.formatMinutes(durationMinutes);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: themeColors.surface.withValues(alpha: 0.6),
        borderRadius: AppRadius.small,
        border: Border.all(
          color: themeColors.subTextColor.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMiniStepBtn(
                    icon: Icons.remove,
                    onTap: durationMinutes > 0.5
                        ? () {
                            AppHaptics.light();
                            notifier.updateLeagueMatchDuration(
                              leagueIndex,
                              durationMinutes - 0.5,
                            );
                          }
                        : null,
                  ),
                  SizedBox(
                    width: 58,
                    child: Text(
                      timeStr,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: AppFontSize.bodySmall,
                        fontWeight: AppFontWeight.bold,
                        color: themeColors.textColor,
                      ),
                    ),
                  ),
                  _buildMiniStepBtn(
                    icon: Icons.add,
                    onTap: durationMinutes < 15.0
                        ? () {
                            AppHaptics.light();
                            notifier.updateLeagueMatchDuration(
                              leagueIndex,
                              durationMinutes + 0.5,
                            );
                          }
                        : null,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          _buildQuickChips(
            currentMinutes: durationMinutes,
            onSelect: (mins) {
              AppHaptics.selection();
              notifier.updateLeagueMatchDuration(leagueIndex, mins);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTournamentTimeCard({required double durationMinutes}) {
    final timeStr = CalculatorSettings.formatMinutes(durationMinutes);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: themeColors.primaryAccent.withValues(alpha: 0.05),
        borderRadius: AppRadius.small,
        border: Border.all(
          color: themeColors.primaryAccent.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: themeColors.primaryAccent.withValues(alpha: 0.2),
                  borderRadius: AppRadius.capsule,
                ),
                child: Text(
                  '決勝トーナメント',
                  style: TextStyle(
                    fontSize: AppFontSize.caption,
                    fontWeight: AppFontWeight.bold,
                    color: themeColors.primaryAccent,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMiniStepBtn(
                    icon: Icons.remove,
                    onTap: durationMinutes > 0.5
                        ? () {
                            AppHaptics.light();
                            notifier.updateTournamentMatchDuration(
                              durationMinutes - 0.5,
                            );
                          }
                        : null,
                  ),
                  SizedBox(
                    width: 58,
                    child: Text(
                      timeStr,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: AppFontSize.bodySmall,
                        fontWeight: AppFontWeight.bold,
                        color: themeColors.textColor,
                      ),
                    ),
                  ),
                  _buildMiniStepBtn(
                    icon: Icons.add,
                    onTap: durationMinutes < 15.0
                        ? () {
                            AppHaptics.light();
                            notifier.updateTournamentMatchDuration(
                              durationMinutes + 0.5,
                            );
                          }
                        : null,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          _buildQuickChips(
            currentMinutes: durationMinutes,
            onSelect: (mins) {
              AppHaptics.selection();
              notifier.updateTournamentMatchDuration(mins);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChips({
    required double currentMinutes,
    required ValueChanged<double> onSelect,
  }) {
    final presets = [1.5, 2.0, 2.5, 3.0, 4.0];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: presets.map((mins) {
          final isSelected = (currentMinutes - mins).abs() < 0.01;
          final label = CalculatorSettings.formatMinutes(mins);

          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onSelect(mins),
                borderRadius: AppRadius.capsule,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 3.0,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? themeColors.primaryAccent.withValues(alpha: 0.2)
                        : themeColors.surface,
                    borderRadius: AppRadius.capsule,
                    border: Border.all(
                      color: isSelected
                          ? themeColors.primaryAccent
                          : themeColors.subTextColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: AppFontSize.micro + 2.0,
                      fontWeight: isSelected
                          ? AppFontWeight.bold
                          : AppFontWeight.regular,
                      color: isSelected
                          ? themeColors.primaryAccent
                          : themeColors.textColor,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMiniStepBtn({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    final enabled = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.small,
        child: Container(
          width: 28,
          height: 28,
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
            size: 14,
            color: enabled
                ? themeColors.textColor
                : themeColors.subTextColor.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }
}
