import 'package:flutter/material.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// タイムライン試合グループの対戦チーム・勝敗・本数サマリー表示パーツ
class TimelineGroupScoreSummary extends StatelessWidget {
  final List<MatchModel> groupList;
  final String rTeam;
  final String wTeam;
  final List<String> ownTeams;
  final Color titleColor;
  final bool isDark;

  const TimelineGroupScoreSummary({
    super.key,
    required this.groupList,
    required this.rTeam,
    required this.wTeam,
    required this.ownTeams,
    required this.titleColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    int redWins = 0;
    int redPts = 0;
    int whiteWins = 0;
    int whitePts = 0;

    for (var m in groupList) {
      if (m.matchType == '代表戦') {
        continue;
      }
      final r = m.redScore;
      final w = m.whiteScore;
      redPts += (r as num).toInt();
      whitePts += (w as num).toInt();
      final mFinished = m.status == 'finished' || m.status == 'approved';
      if (mFinished) {
        if (r > w) {
          redWins++;
        } else if (w > r) {
          whiteWins++;
        }
      }
    }

    final ruleTeamName = groupList.firstOrNull?.rule?.teamName;
    final bool isOwnRed =
        (ruleTeamName != null && rTeam == ruleTeamName) ||
        ownTeams.contains(rTeam);
    final bool isOwnWhite =
        (ruleTeamName != null && wTeam == ruleTeamName) ||
        ownTeams.contains(wTeam);

    return Row(
      children: [
        Expanded(
          child: Text(
            rTeam,
            style: TextStyle(
              fontSize: AppFontSize.body,
              fontWeight: isOwnRed ? AppFontWeight.black : AppFontWeight.bold,
              color: isOwnRed ? const Color(0xFFD97706) : titleColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xxs,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
            borderRadius: AppRadius.sub,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$redWins',
                style: TextStyle(
                  fontSize: AppFontSize.bodySmall,
                  fontWeight: AppFontWeight.bold,
                  color: redWins > whiteWins
                      ? AppKendoColors.hansokuRed
                      : titleColor,
                ),
              ),
              Text(
                '($redPts)',
                style: TextStyle(
                  fontSize: AppFontSize.bodySmall,
                  fontWeight: AppFontWeight.bold,
                  color: redWins > whiteWins
                      ? AppKendoColors.hansokuRed
                      : titleColor,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Text(
                  '-',
                  style: TextStyle(
                    fontSize: AppFontSize.badge,
                    color: context.appColors.subTextColor,
                  ),
                ),
              ),
              Text(
                '$whiteWins',
                style: TextStyle(
                  fontSize: AppFontSize.bodySmall,
                  fontWeight: AppFontWeight.bold,
                  color: whiteWins > redWins
                      ? context.appColors.primaryAccent
                      : titleColor,
                ),
              ),
              Text(
                '($whitePts)',
                style: TextStyle(
                  fontSize: AppFontSize.bodySmall,
                  fontWeight: AppFontWeight.bold,
                  color: whiteWins > redWins
                      ? context.appColors.primaryAccent
                      : titleColor,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Text(
            wTeam,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: AppFontSize.body,
              fontWeight: isOwnWhite ? AppFontWeight.black : AppFontWeight.bold,
              color: isOwnWhite ? const Color(0xFFD97706) : titleColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
