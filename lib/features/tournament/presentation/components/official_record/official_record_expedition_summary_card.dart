import 'package:flutter/material.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/expedition_active_summaries.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/expedition_player_stats_section.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/expedition_stats_calculator.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/expedition_summary_header.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/expedition_summary_toolbar.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

export 'expedition_stats_models.dart';
export 'expedition_stats_calculator.dart';
export 'expedition_detail_bottom_sheet.dart';
export 'expedition_summary_header.dart';
export 'expedition_summary_toolbar.dart';

/// 🥋 大会公式記録 遠征・戦績集計サマリーカード
class OfficialRecordExpeditionSummaryCard extends StatefulWidget {
  final List<MatchModel> matches;
  final bool isDark;
  final Set<String> registeredTeamNames;
  final Set<String> registeredPlayerNames;
  final Future<void> Function(String text, String subject, Rect? origin)?
  onShare;
  final bool initiallyExpanded;

  const OfficialRecordExpeditionSummaryCard({
    super.key,
    required this.matches,
    required this.isDark,
    required this.registeredTeamNames,
    required this.registeredPlayerNames,
    this.onShare,
    this.initiallyExpanded = false,
  });

  @override
  State<OfficialRecordExpeditionSummaryCard> createState() =>
      _OfficialRecordExpeditionSummaryCardState();
}

class _OfficialRecordExpeditionSummaryCardState
    extends State<OfficialRecordExpeditionSummaryCard> {
  late bool _isCardExpanded;
  String _selectedSummaryTeam = '全体';
  bool _isPlayerStatsExpanded = false;

  @override
  void initState() {
    super.initState();
    _isCardExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.matches.isEmpty) return const SizedBox.shrink();

    final isDark = widget.isDark;
    final summaryData = ExpeditionStatsCalculator.calculate(
      matches: widget.matches,
      registeredTeamNames: widget.registeredTeamNames,
      registeredPlayerNames: widget.registeredPlayerNames,
      selectedSummaryTeam: _selectedSummaryTeam,
    );

    final teamsList = summaryData.teamsList;
    final playerStatsMap = summaryData.playerStatsMap;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.roundValue,
        bottom: AppSpacing.xs,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: _isCardExpanded ? AppSpacing.lg : AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFFFFFFF),
        borderRadius: AppRadius.large,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1行目: ヘッダー（タイトル、LINE共有、開閉トグル）
          ExpeditionSummaryHeader(
            isCardExpanded: _isCardExpanded,
            isDark: isDark,
            themeColors: themeColors,
            selectedSummaryTeam: _selectedSummaryTeam,
            matches: widget.matches,
            onToggleExpand: () =>
                setState(() => _isCardExpanded = !_isCardExpanded),
            onShare: widget.onShare,
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.sm),
                // 2行目: 詳細分析（左/中央）と チーム選択ドロップダウン
                ExpeditionSummaryToolbar(
                  isDark: isDark,
                  themeColors: themeColors,
                  selectedSummaryTeam: _selectedSummaryTeam,
                  teamsList: teamsList,
                  summaryData: summaryData,
                  onTeamChanged: (val) =>
                      setState(() => _selectedSummaryTeam = val),
                ),
                const Divider(height: 20),
                // 勝敗サマリー（実施されたもののみ表示）
                ExpeditionActiveSummaries(summaryData: summaryData),
                if (playerStatsMap.isNotEmpty) ...[
                  const Divider(height: 20),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isPlayerStatsExpanded = !_isPlayerStatsExpanded;
                      });
                    },
                    borderRadius: AppRadius.medium,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xxs,
                        horizontal: AppSpacing.xxs,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 16,
                            color: isDark
                                ? const Color(0xFFCCCCCC)
                                : AppKendoColors.grey,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            '選手別成績 (${playerStatsMap.length}名)',
                            style: TextStyle(
                              fontWeight: AppFontWeight.bold,
                              fontSize: AppFontSize.bodySmall,
                              color: isDark
                                  ? const Color(0xFFCCCCCC)
                                  : AppKendoColors.grey,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF38383A)
                                  : themeColors.softAccent,
                              borderRadius: AppRadius.round,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _isPlayerStatsExpanded ? '閉じる' : '表示する',
                                  style: TextStyle(
                                    fontSize: AppFontSize.caption,
                                    fontWeight: AppFontWeight.bold,
                                    color: isDark
                                        ? const Color(0xFFFFFFFF)
                                        : context.appColors.primaryAccent,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  _isPlayerStatsExpanded
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  size: 16,
                                  color: isDark
                                      ? const Color(0xFFFFFFFF)
                                      : context.appColors.primaryAccent,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: ExpeditionPlayerStatsSection(
                      playerStatsMap: playerStatsMap,
                      isDark: isDark,
                    ),
                    crossFadeState: _isPlayerStatsExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 200),
                  ),
                ],
              ],
            ),
            crossFadeState: _isCardExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }
}
