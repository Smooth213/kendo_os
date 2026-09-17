import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/domain/match_calculator/match_calculation_models.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/calculator/match_calculator_accordion_card.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/calculator/match_calculator_basic_settings_card.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/calculator/match_calculator_league_advanced_settings.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/calculator/match_calculator_pattern_selector.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/calculator/match_calculator_time_settings.dart';
import 'package:kendo_os/features/tournament/presentation/providers/match_calculator_provider.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 🥋 試合数計算・シミュレーション用入力フォームセクション
/// 基本設定カード ＋ 洗練された詳細アコーディオン群で構成
class MatchCalculatorInputSection extends StatelessWidget {
  final CalculatorSettings settings;
  final MatchCalculatorNotifier notifier;

  const MatchCalculatorInputSection({
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
    final isTournament = settings.format == MatchFormatType.tournament;
    final isPrelimWithTournament =
        settings.format == MatchFormatType.prelimLeagueAndTournament;

    final hasAdvancedLeagueSection =
        isMultiLeague || isTournament || isPrelimWithTournament;

    // 時間設定のサマリーバッジ生成
    final startHourStr = settings.startTime.hour.toString().padLeft(2, '0');
    final startMinStr = settings.startTime.minute.toString().padLeft(2, '0');
    final intervalStr = settings.intervalDurationMinutes == 0
        ? '休憩なし'
        : '休憩${CalculatorSettings.formatMinutes(settings.intervalDurationMinutes)}';
    final customTimeSuffix =
        (settings.useCustomLeagueMatchDurations && isMultiLeague)
        ? ' / 個別時間'
        : '';
    final timeBadge =
        '$startHourStr:$startMinStr開始 / $intervalStr$customTimeSuffix';

    // リーグ詳細設定のサマリーバッジ生成
    String leagueBadge = '';
    if (isPrelimWithTournament) {
      leagueBadge =
          '${settings.leagueCount}L / 上位${settings.advancingCountPerLeague}名進出';
    } else if (isMultiLeague) {
      leagueBadge =
          '${settings.leagueCount}リーグ (${settings.effectiveParticipantCount}名)';
    } else if (isTournament) {
      leagueBadge = '3決: ${settings.hasThirdPlaceMatch ? 'あり' : 'なし'}';
    }

    // コート割り振りパターンのサマリーバッジ生成
    final patternBadge = settings.pattern.shortTitle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. 基本設定カード（形式・規模・コート数・基本時間）
        MatchCalculatorBasicSettingsCard(
          settings: settings,
          notifier: notifier,
        ),

        const SizedBox(height: AppSpacing.md),

        // セクションヘッダー：詳細設定アコーディオン
        _buildSectionHeader(
          '詳細設定・調整 (タップで展開)',
          Icons.tune_rounded,
          themeColors,
        ),
        const SizedBox(height: AppSpacing.xs),

        // アコーディオン 1: ⏱️ 開始予定時刻 ＆ 時間詳細設定
        MatchCalculatorAccordionCard(
          icon: Icons.timer_outlined,
          leadingIcon: Icon(
            Icons.timer_outlined,
            size: 16,
            color: themeColors.primaryAccent,
          ),
          title: '開始予定時刻 ＆ 時間詳細',
          badgeText: timeBadge,
          child: MatchCalculatorTimeSettings(
            settings: settings,
            notifier: notifier,
          ),
        ),

        // アコーディオン 2: 👥 リーグ人数配分 ＆ 決勝進出枠（複数L or トーナメント時）
        if (hasAdvancedLeagueSection) ...[
          const SizedBox(height: AppSpacing.sm),
          MatchCalculatorAccordionCard(
            icon: isTournament
                ? Icons.account_tree_rounded
                : Icons.groups_rounded,
            title: isTournament ? 'トーナメント詳細設定' : 'リーグ人数配分 ＆ 進出枠',
            badgeText: leagueBadge,
            child: MatchCalculatorLeagueAdvancedSettings(
              settings: settings,
              notifier: notifier,
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.sm),

        // アコーディオン 3: 🔀 コート割り振りパターン
        MatchCalculatorAccordionCard(
          icon: Icons.alt_route_rounded,
          title: 'コート割り振りパターン',
          badgeText: patternBadge,
          child: MatchCalculatorPatternSelector(
            settings: settings,
            notifier: notifier,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
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
            fontSize: AppFontSize.caption,
            fontWeight: AppFontWeight.bold,
            color: themeColors.subTextColor,
          ),
        ),
      ],
    );
  }
}
