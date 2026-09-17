import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/domain/match_calculator/match_calculation_models.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/calculator/match_calculator_league_time_section.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/calculator/match_calculator_start_time_section.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_time_stepper_tile.dart';
import 'package:kendo_os/features/tournament/presentation/providers/match_calculator_provider.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/utils/app_haptics.dart';

/// 🥋 試合時間詳細（個別設定）・インターバル・開始時刻設定コンポーネント
class MatchCalculatorTimeSettings extends StatelessWidget {
  final CalculatorSettings settings;
  final MatchCalculatorNotifier notifier;

  const MatchCalculatorTimeSettings({
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
    final isPrelimWithTournament =
        settings.format == MatchFormatType.prelimLeagueAndTournament;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 複数リーグ時のみ: 一括か個別かの切替タブ
        if (isMultiLeague) ...[
          _buildModeSelector(themeColors),
          const SizedBox(height: AppSpacing.sm),
        ],

        // リーグ別個別設定モード時の詳細時間設定
        if (settings.useCustomLeagueMatchDurations && isMultiLeague) ...[
          MatchCalculatorLeagueTimeSection(
            settings: settings,
            notifier: notifier,
            themeColors: themeColors,
            isPrelimWithTournament: isPrelimWithTournament,
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),
        ],

        // インターバル時間（カプセルステッパー＆クイック選択）
        CategoryTimeStepperTile(
          title: 'インターバル',
          subtitle: '試合間の交代・整列待機時間（30秒単位）',
          value: settings.intervalDurationMinutes,
          minValue: 0.0,
          maxValue: 5.0,
          step: 0.5,
          primaryColor: primaryAccent,
          onChanged: (val) {
            AppHaptics.selection();
            notifier.updateIntervalDuration(val);
          },
        ),
        const SizedBox(height: AppSpacing.xs),
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.xs),
          child: Text(
            'インターバル クイック選択',
            style: TextStyle(
              fontSize: AppFontSize.caption,
              fontWeight: AppFontWeight.bold,
              color: themeColors.subTextColor,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [0.0, 0.5, 1.0, 1.5, 2.0].map((t) {
            final isSelected =
                (settings.intervalDurationMinutes - t).abs() < 0.01;
            final label = t == 0.0
                ? 'なし(0秒)'
                : CategoryTimeStepperTile.formatMinutes(t);
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  AppHaptics.selection();
                  notifier.updateIntervalDuration(t);
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
                    label,
                    style: TextStyle(
                      fontSize: AppFontSize.caption,
                      fontWeight: isSelected
                          ? AppFontWeight.bold
                          : AppFontWeight.medium,
                      color: isSelected
                          ? themeColors.onPrimaryAccent
                          : themeColors.textColor,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: AppSpacing.md),
        const Divider(height: 1),
        const SizedBox(height: AppSpacing.sm),

        // 開始時刻設定（インラインステッパー＆クイック選択カプセル）
        MatchCalculatorStartTimeSection(
          settings: settings,
          notifier: notifier,
          themeColors: themeColors,
          isDark: isDark,
        ),
      ],
    );
  }

  /// 一括／個別の切り替えタブ
  Widget _buildModeSelector(AppThemeColors themeColors) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxs),
      decoration: BoxDecoration(
        color: themeColors.subTextColor.withValues(alpha: 0.08),
        borderRadius: AppRadius.capsule,
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildModeTab(
              label: '一括設定 (全リーグ共通)',
              icon: Icons.layers_rounded,
              isSelected: !settings.useCustomLeagueMatchDurations,
              onTap: () {
                AppHaptics.selection();
                notifier.setUseCustomLeagueMatchDurations(false);
              },
              themeColors: themeColors,
            ),
          ),
          Expanded(
            child: _buildModeTab(
              label: 'リーグ別に個別設定',
              icon: Icons.tune_rounded,
              isSelected: settings.useCustomLeagueMatchDurations,
              onTap: () {
                AppHaptics.selection();
                notifier.setUseCustomLeagueMatchDurations(true);
              },
              themeColors: themeColors,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required AppThemeColors themeColors,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.capsule,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
            horizontal: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: isSelected ? themeColors.surface : Colors.transparent,
            borderRadius: AppRadius.capsule,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppKendoColors.pureBlack.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected
                    ? themeColors.primaryAccent
                    : themeColors.subTextColor,
              ),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: AppFontSize.caption - 0.5,
                    fontWeight: isSelected
                        ? AppFontWeight.bold
                        : AppFontWeight.medium,
                    color: isSelected
                        ? themeColors.textColor
                        : themeColors.subTextColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
