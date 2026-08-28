import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/application/services/line_summary_formatter.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/expedition_active_summaries.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/expedition_detail_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/expedition_player_stats_section.dart';
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
  final Future<void> Function(String text, String subject, Rect? origin)?
  onShare;

  const OfficialRecordExpeditionSummaryCard({
    super.key,
    required this.matches,
    required this.isDark,
    required this.registeredTeamNames,
    required this.registeredPlayerNames,
    this.onShare,
  });

  @override
  State<OfficialRecordExpeditionSummaryCard> createState() =>
      _OfficialRecordExpeditionSummaryCardState();
}

class _OfficialRecordExpeditionSummaryCardState
    extends State<OfficialRecordExpeditionSummaryCard> {
  String _selectedSummaryTeam = '全体';
  bool _isPlayerStatsExpanded = false;

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
          // 1行目: タイトル（左）と LINE用コピー（右）
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
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
              Builder(
                builder: (buttonContext) {
                  return InkWell(
                    onTap: () async {
                      final title = _selectedSummaryTeam == '全体'
                          ? '遠征・試合'
                          : _selectedSummaryTeam;
                      final text = LineSummaryFormatter.formatExpeditionSummary(
                        title: title,
                        matches: widget.matches,
                      );

                      // iPad/タブレット等でのクラッシュを防ぐための sharePositionOrigin 算出（非同期の前に取得）
                      final box =
                          buttonContext.findRenderObject() as RenderBox?;
                      final origin = box != null
                          ? box.localToGlobal(Offset.zero) & box.size
                          : null;

                      // クリップボードにも先回りして自動格納
                      await Clipboard.setData(ClipboardData(text: text));

                      // OS標準の共有シート（LINE、メッセージ、メール等）を起動
                      if (widget.onShare != null) {
                        await widget.onShare!(text, '【$title 結果速報】', origin);
                      } else {
                        await SharePlus.instance.share(
                          ShareParams(
                            text: text,
                            subject: '【$title 結果速報】',
                            sharePositionOrigin: origin,
                          ),
                        );
                      }
                    },
                    borderRadius: AppRadius.round,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF06C755).withValues(alpha: 0.15),
                        borderRadius: AppRadius.round,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.share_rounded,
                            size: 13,
                            color: Color(0xFF06C755),
                          ),
                          SizedBox(width: AppSpacing.xxs),
                          Text(
                            'LINE・共有',
                            style: TextStyle(
                              fontSize: AppFontSize.caption,
                              fontWeight: AppFontWeight.bold,
                              color: Color(0xFF06C755),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // 2行目: 詳細分析（左/中央）と チーム選択ドロップダウン
          Wrap(
            alignment: WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
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
    );
  }
}
