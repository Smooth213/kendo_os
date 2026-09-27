import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/expedition_detail_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/expedition_stats_models.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 遠征サマリーカード内の詳細分析ボタンおよびチーム選択ドロップダウン
class ExpeditionSummaryToolbar extends StatelessWidget {
  final bool isDark;
  final AppThemeColors themeColors;
  final String selectedSummaryTeam;
  final List<String> teamsList;
  final ExpeditionSummaryData summaryData;
  final ValueChanged<String> onTeamChanged;

  const ExpeditionSummaryToolbar({
    super.key,
    required this.isDark,
    required this.themeColors,
    required this.selectedSummaryTeam,
    required this.teamsList,
    required this.summaryData,
    required this.onTeamChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
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
              teamName: selectedSummaryTeam,
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
              color: isDark ? const Color(0xFF38383A) : themeColors.softAccent,
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
                    : context.appColors.primaryAccent.withValues(alpha: 0.3),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: teamsList.contains(selectedSummaryTeam)
                    ? selectedSummaryTeam
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
                    onTeamChanged(val);
                  }
                },
              ),
            ),
          ),
        ],
      ],
    );
  }
}
