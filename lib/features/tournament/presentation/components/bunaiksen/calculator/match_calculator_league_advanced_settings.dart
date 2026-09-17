import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/domain/match_calculator/match_calculation_models.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/calculator/match_calculator_league_list_section.dart';
import 'package:kendo_os/features/tournament/presentation/providers/match_calculator_provider.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_haptics.dart';
import 'package:kendo_os/shared/widgets/app_switch.dart';

/// 🥋 リーグ人数配分・進出枠・3位決定戦等の詳細設定コンポーネント
class MatchCalculatorLeagueAdvancedSettings extends StatelessWidget {
  final CalculatorSettings settings;
  final MatchCalculatorNotifier notifier;

  const MatchCalculatorLeagueAdvancedSettings({
    super.key,
    required this.settings,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'bunaiksen');

    final isMultiLeague =
        settings.format == MatchFormatType.multiLeague ||
        settings.format == MatchFormatType.prelimLeagueAndTournament;
    final isPrelimWithTournament =
        settings.format == MatchFormatType.prelimLeagueAndTournament;
    final isTournament = settings.format == MatchFormatType.tournament;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. リーグブロック数ステッパー（複数リーグ時のみ）
        if (isMultiLeague) ...[
          _buildStepperRow(
            label: 'リーグブロック数',
            value: '${settings.leagueCount} リーグ',
            onMinus: settings.leagueCount > 2
                ? () {
                    AppHaptics.light();
                    notifier.updateLeagueCount(settings.leagueCount - 1);
                  }
                : null,
            onPlus: settings.leagueCount < 8
                ? () {
                    AppHaptics.light();
                    notifier.updateLeagueCount(settings.leagueCount + 1);
                  }
                : null,
            themeColors: themeColors,
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),

          // 2. 各リーグの人数配分
          MatchCalculatorLeagueListSection(
            settings: settings,
            notifier: notifier,
          ),
        ],

        // 3. 決勝T進出枠（予選L＋決勝T時）
        if (isPrelimWithTournament) ...[
          if (isMultiLeague) ...[
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.sm),
          ],
          _buildAdvancingCountSection(themeColors),
        ],

        // 4. 3位決定戦（トーナメント または 予選L＋決勝T時）
        if (isTournament || isPrelimWithTournament) ...[
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '3位決定戦を行う',
                    style: TextStyle(
                      fontSize: AppFontSize.bodySmall,
                      fontWeight: AppFontWeight.medium,
                      color: themeColors.textColor,
                    ),
                  ),
                  Text(
                    '準決勝惜敗者同士による対戦を組みます',
                    style: TextStyle(
                      fontSize: AppFontSize.caption,
                      color: themeColors.subTextColor,
                    ),
                  ),
                ],
              ),
              AppSwitch(
                value: settings.hasThirdPlaceMatch,
                activeColor: themeColors.primaryAccent,
                onChanged: (val) {
                  notifier.updateThirdPlaceMatch(val);
                },
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildAdvancingCountSection(AppThemeColors themeColors) {
    final advancingOptions = [
      (count: 1, label: '1位のみ'),
      (count: 2, label: '上位2名'),
      (count: 3, label: '上位3名'),
      (count: 4, label: '上位4名'),
    ];

    final totalTournamentParticipants =
        settings.leagueCount * settings.advancingCountPerLeague;
    final tournamentMatches = totalTournamentParticipants >= 2
        ? totalTournamentParticipants - 1
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '各リーグの上位進出枠（決勝T進出）',
                  style: TextStyle(
                    fontSize: AppFontSize.bodySmall,
                    fontWeight: AppFontWeight.bold,
                    color: themeColors.textColor,
                  ),
                ),
                Text(
                  '決勝T進出: 計$totalTournamentParticipants名 (${settings.leagueCount}L × ${settings.advancingCountPerLeague}名) → $tournamentMatches試合',
                  style: TextStyle(
                    fontSize: AppFontSize.caption,
                    color: themeColors.primaryAccent,
                    fontWeight: AppFontWeight.medium,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMiniStepBtn(
                  icon: Icons.remove,
                  onTap: settings.advancingCountPerLeague > 1
                      ? () {
                          AppHaptics.light();
                          notifier.updateAdvancingCount(
                            settings.advancingCountPerLeague - 1,
                          );
                        }
                      : null,
                  themeColors: themeColors,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  child: Text(
                    '${settings.advancingCountPerLeague} 名',
                    style: TextStyle(
                      fontSize: AppFontSize.bodySmall,
                      fontWeight: AppFontWeight.bold,
                      color: themeColors.textColor,
                    ),
                  ),
                ),
                _buildMiniStepBtn(
                  icon: Icons.add,
                  onTap: settings.advancingCountPerLeague < 6
                      ? () {
                          AppHaptics.light();
                          notifier.updateAdvancingCount(
                            settings.advancingCountPerLeague + 1,
                          );
                        }
                      : null,
                  themeColors: themeColors,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: advancingOptions.map((opt) {
              final isSelected = settings.advancingCountPerLeague == opt.count;
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      AppHaptics.selection();
                      notifier.updateAdvancingCount(opt.count);
                    },
                    borderRadius: AppRadius.capsule,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
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
                        opt.label,
                        style: TextStyle(
                          fontSize: AppFontSize.caption,
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
        ),
      ],
    );
  }

  Widget _buildStepperRow({
    required String label,
    required String value,
    required VoidCallback? onMinus,
    required VoidCallback? onPlus,
    required AppThemeColors themeColors,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppFontSize.bodySmall,
            fontWeight: AppFontWeight.medium,
            color: themeColors.textColor,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMiniStepBtn(
              icon: Icons.remove,
              onTap: onMinus,
              themeColors: themeColors,
            ),
            SizedBox(
              width: 76,
              child: Text(
                value,
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
              onTap: onPlus,
              themeColors: themeColors,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniStepBtn({
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
          width: 32,
          height: 32,
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
            size: 16,
            color: enabled
                ? themeColors.textColor
                : themeColors.subTextColor.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }
}
