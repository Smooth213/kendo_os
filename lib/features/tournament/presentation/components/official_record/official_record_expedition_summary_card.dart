import 'package:flutter/material.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/expedition_detail_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/expedition_stats_calculator.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

export 'expedition_stats_models.dart';
export 'expedition_stats_calculator.dart';
export 'expedition_detail_bottom_sheet.dart';

/// 🥋 大会公式記録 遠征・戦績集計サマリーカード
class OfficialRecordExpeditionSummaryCard extends StatefulWidget {
  final List<MatchModel> matches;
  final bool isDark;
  final Set<String> registeredTeamNames;
  final Set<String> registeredPlayerNames;

  const OfficialRecordExpeditionSummaryCard({
    super.key,
    required this.matches,
    required this.isDark,
    required this.registeredTeamNames,
    required this.registeredPlayerNames,
  });

  @override
  State<OfficialRecordExpeditionSummaryCard> createState() =>
      _OfficialRecordExpeditionSummaryCardState();
}

class _OfficialRecordExpeditionSummaryCardState
    extends State<OfficialRecordExpeditionSummaryCard> {
  String _selectedSummaryTeam = '全体';

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

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
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
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.analytics_outlined,
                    color: AppKendoColors.indigo,
                    size: 20,
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Text(
                    '成績サマリー',
                    style: TextStyle(
                      fontWeight: AppFontWeight.bold,
                      fontSize: AppFontSize.bodyMedium,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () {
                      ExpeditionDetailBottomSheet.show(
                        context: context,
                        isDark: isDark,
                        teamName: _selectedSummaryTeam,
                        teamMen: summaryData.teamMen,
                        teamKote: summaryData.teamKote,
                        teamDou: summaryData.teamDou,
                        teamTsuki: summaryData.teamTsuki,
                        teamHansoku: summaryData.teamHansoku,
                        teamOther: summaryData.teamOther,
                        totalScored: summaryData.teamTotalScored,
                        totalConceded: summaryData.teamTotalConceded,
                        cardResults: summaryData.cardResults,
                      );
                    },
                    borderRadius: AppRadius.round,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xxs,
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
                          Icon(
                            Icons.bar_chart,
                            size: 14,
                            color: isDark
                                ? const Color(0xFFFFFFFF)
                                : context.appColors.primaryAccent,
                          ),
                          const SizedBox(width: AppSpacing.xxs),
                          Text(
                            '詳細分析 ›',
                            style: TextStyle(
                              fontSize: AppFontSize.caption,
                              fontWeight: AppFontWeight.bold,
                              color: isDark
                                  ? const Color(0xFFFFFFFF)
                                  : context.appColors.primaryAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (teamsList.length > 1) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.compact,
                        vertical: AppSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF3F51B5).withValues(alpha: 0.3)
                            : const Color(0xFFEEF2FF),
                        borderRadius: AppRadius.round,
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF3F51B5)
                              : context.appColors.primaryAccent.withValues(
                                  alpha: 0.3,
                                ),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: teamsList.contains(_selectedSummaryTeam)
                              ? _selectedSummaryTeam
                              : '全体',
                          isDense: true,
                          dropdownColor: isDark
                              ? const Color(0xFF2C2C2E)
                              : const Color(0xFFFFFFFF),
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: isDark
                                ? const Color(0xFFFFFFFF)
                                : context.appColors.primaryAccent,
                            size: 20,
                          ),
                          style: TextStyle(
                            fontWeight: AppFontWeight.bold,
                            fontSize: AppFontSize.bodySmall,
                            color: isDark
                                ? const Color(0xFFFFFFFF)
                                : context.appColors.primaryAccent,
                          ),
                          items: ['全体', ...teamsList].map((t) {
                            return DropdownMenuItem<String>(
                              value: t,
                              child: Text(
                                t == '全体' ? '全チーム合計' : t,
                                style: TextStyle(
                                  color: isDark
                                      ? const Color(0xFFFFFFFF)
                                      : context.appColors.textColor,
                                  fontWeight: AppFontWeight.bold,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedSummaryTeam = val;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                '⚔️ 錬成会',
                summaryData.renseikaiWin,
                summaryData.renseikaiLoss,
                summaryData.renseikaiDraw,
                const Color(0xFFD97706),
              ),
              _buildSummaryItem(
                '🏆 本戦',
                summaryData.honsenWin,
                summaryData.honsenLoss,
                summaryData.honsenDraw,
                const Color(0xFF3F51B5),
              ),
              _buildSummaryItem(
                '🤝 申し合わせ',
                summaryData.moushiawaseWin,
                summaryData.moushiawaseLoss,
                summaryData.moushiawaseDraw,
                const Color(0xFF009688),
              ),
            ],
          ),
          if (playerStatsMap.isNotEmpty) ...[
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  '👤 選手別成績（タップでカルテ表示）',
                  style: TextStyle(
                    fontWeight: AppFontWeight.bold,
                    fontSize: AppFontSize.bodySmall,
                    color: AppKendoColors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: playerStatsMap.entries.map((entry) {
                final pName = entry.key;
                final st = entry.value;
                return InkWell(
                  onTap: () {
                    ExpeditionDetailBottomSheet.showPlayerDetail(
                      context: context,
                      isDark: isDark,
                      playerName: pName,
                      stats: st,
                    );
                  },
                  borderRadius: AppRadius.medium,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2C2C2E)
                          : const Color(0xFFF2F2F7),
                      borderRadius: AppRadius.medium,
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFFFFFFFF).withValues(alpha: 0.15)
                            : const Color(0xFF000000).withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$pName: ${st.win}勝${st.loss}敗${st.draw > 0 ? "${st.draw}分" : ""}',
                          style: TextStyle(
                            fontSize: AppFontSize.small,
                            fontWeight: AppFontWeight.bold,
                            color: context.appColors.textColor,
                          ),
                        ),
                        if (st.totalPoints > 0) ...[
                          const SizedBox(width: AppSpacing.xxs),
                          Text(
                            '(${st.totalPoints}本)',
                            style: const TextStyle(
                              fontSize: AppFontSize.caption,
                              fontWeight: AppFontWeight.bold,
                              color: AppKendoColors.indigo,
                            ),
                          ),
                        ],
                        const SizedBox(width: 2),
                        Icon(
                          Icons.chevron_right,
                          size: 14,
                          color: AppKendoColors.grey.withValues(alpha: 0.7),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String title,
    int win,
    int loss,
    int draw,
    Color color,
  ) {
    final total = win + loss + draw;
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: AppFontWeight.bold,
            fontSize: AppFontSize.bodySmall,
            color: color,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          total > 0 ? '$win勝 $loss敗 ${draw > 0 ? "$draw分" : ""}' : '未実施',
          style: const TextStyle(
            fontSize: AppFontSize.body,
            fontWeight: AppFontWeight.semiBold,
          ),
        ),
        if (total > 0)
          Text(
            '（計$total試合）',
            style: const TextStyle(
              fontSize: AppFontSize.caption,
              color: AppKendoColors.grey,
            ),
          ),
      ],
    );
  }
}
