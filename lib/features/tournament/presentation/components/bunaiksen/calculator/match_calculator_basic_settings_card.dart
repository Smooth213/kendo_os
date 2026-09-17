import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/domain/match_calculator/match_calculation_models.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/calculator/match_calculator_format_selector.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_time_stepper_tile.dart';
import 'package:kendo_os/features/tournament/presentation/providers/match_calculator_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_haptics.dart';

/// 🥋 計算機シート用 基本設定カード（ファーストビュー用）
/// 試合形式・参加人数・コート面数・基本試合時間をスッキリ1枚に集約
class MatchCalculatorBasicSettingsCard extends StatelessWidget {
  final CalculatorSettings settings;
  final MatchCalculatorNotifier notifier;

  const MatchCalculatorBasicSettingsCard({
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
    final primaryAccent = themeColors.primaryAccent;

    final isMultiLeague =
        settings.format == MatchFormatType.multiLeague ||
        settings.format == MatchFormatType.prelimLeagueAndTournament;

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
          // 1. 試合形式選択
          _buildFieldLabel('試合形式', Icons.category_rounded, themeColors),
          const SizedBox(height: AppSpacing.xs),
          MatchCalculatorFormatSelector(settings: settings, notifier: notifier),

          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),

          // 2. 参加人数 & コート面数
          _buildFieldLabel('規模・コート設定', Icons.groups_rounded, themeColors),
          const SizedBox(height: AppSpacing.xs),
          _buildStepperRow(
            label: isMultiLeague ? '合計参加人数' : '参加人数',
            value: '${settings.effectiveParticipantCount} 名',
            onMinus:
                settings.effectiveParticipantCount >
                    (isMultiLeague ? settings.leagueCount * 2 : 2)
                ? () {
                    AppHaptics.light();
                    notifier.updateParticipantCount(
                      settings.effectiveParticipantCount - 1,
                    );
                  }
                : null,
            onPlus: () {
              AppHaptics.light();
              notifier.updateParticipantCount(
                settings.effectiveParticipantCount + 1,
              );
            },
            themeColors: themeColors,
          ),
          const SizedBox(height: AppSpacing.xs),
          _buildStepperRow(
            label: 'コート面数',
            value: '${settings.courtCount} 面',
            onMinus: settings.courtCount > 1
                ? () {
                    AppHaptics.light();
                    notifier.updateCourtCount(settings.courtCount - 1);
                  }
                : null,
            onPlus: settings.courtCount < 8
                ? () {
                    AppHaptics.light();
                    notifier.updateCourtCount(settings.courtCount + 1);
                  }
                : null,
            themeColors: themeColors,
          ),

          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),

          // 3. 1試合の時間（ステッパー ＆ クイックチップ）
          _buildFieldLabel('基本試合時間', Icons.timer_outlined, themeColors),
          const SizedBox(height: AppSpacing.xs),
          CategoryTimeStepperTile(
            title: '1試合の時間',
            subtitle: '30秒単位で自由に増減できます',
            value: settings.matchDurationMinutes,
            minValue: 0.5,
            maxValue: 15.0,
            step: 0.5,
            primaryColor: primaryAccent,
            onChanged: (val) {
              AppHaptics.selection();
              notifier.updateMatchDuration(val);
            },
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [1.0, 2.0, 3.0, 4.0, 5.0].map((t) {
              final isSelected =
                  (settings.matchDurationMinutes - t).abs() < 0.01;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    AppHaptics.selection();
                    notifier.updateMatchDuration(t);
                  },
                  borderRadius: AppRadius.capsule,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? primaryAccent : themeColors.surface,
                      borderRadius: AppRadius.capsule,
                      border: Border.all(
                        color: isSelected
                            ? primaryAccent
                            : themeColors.subTextColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      CategoryTimeStepperTile.formatMinutes(t),
                      style: TextStyle(
                        fontSize: AppFontSize.caption,
                        fontWeight: isSelected
                            ? AppFontWeight.bold
                            : AppFontWeight.medium,
                        color: isSelected
                            ? AppKendoColors.pureWhite
                            : themeColors.textColor,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(
    String title,
    IconData icon,
    AppThemeColors themeColors,
  ) {
    return Row(
      children: [
        Icon(icon, size: 15, color: themeColors.primaryAccent),
        const SizedBox(width: AppSpacing.xs),
        Text(
          title,
          style: TextStyle(
            fontSize: AppFontSize.bodySmall,
            fontWeight: AppFontWeight.bold,
            color: themeColors.textColor,
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
