import 'package:flutter/material.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 観客席画面用 グループマッチカードのヘッダー側スコアサマリー行
class ViewerGroupMatchScoreSummary extends StatelessWidget {
  final List<MatchModel> groupList;
  final String rTeam;
  final String wTeam;
  final List<String> ownTeams;
  final Color titleColor;

  const ViewerGroupMatchScoreSummary({
    super.key,
    required this.groupList,
    required this.rTeam,
    required this.wTeam,
    required this.ownTeams,
    required this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    int redWins = 0;
    int redPts = 0;
    int whiteWins = 0;
    int whitePts = 0;
    for (var m in groupList) {
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
    final isRedOwn =
        ownTeams.contains(rTeam) ||
        (ruleTeamName?.isNotEmpty == true && rTeam == ruleTeamName);
    final isWhiteOwn =
        ownTeams.contains(wTeam) ||
        (ruleTeamName?.isNotEmpty == true && wTeam == ruleTeamName);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            rTeam,
            style: TextStyle(
              fontSize: AppFontSize.bodyMedium,
              fontWeight: isRedOwn ? AppFontWeight.black : AppFontWeight.bold,
              color: isRedOwn ? const Color(0xFFFFB300) : titleColor,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$redWins',
                style: const TextStyle(
                  fontSize: AppFontSize.subhead,
                  fontWeight: AppFontWeight.bold,
                  color: Color(0xFFE53935),
                ),
              ),
              Text(
                '($redPts)',
                style: const TextStyle(
                  fontSize: AppFontSize.caption,
                  color: Color(0x8A000000),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.subValue),
                child: Text(
                  'ー',
                  style: TextStyle(
                    fontSize: AppFontSize.body,
                    color: Color(0x8A000000),
                    fontWeight: AppFontWeight.bold,
                  ),
                ),
              ),
              Text(
                '$whiteWins',
                style: TextStyle(
                  fontSize: AppFontSize.subhead,
                  fontWeight: AppFontWeight.bold,
                  color: context.appColors.textColor,
                ),
              ),
              Text(
                '($whitePts)',
                style: TextStyle(
                  fontSize: AppFontSize.caption,
                  color: context.appColors.subTextColor,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Text(
            wTeam,
            style: TextStyle(
              fontSize: AppFontSize.bodyMedium,
              fontWeight: isWhiteOwn ? AppFontWeight.black : AppFontWeight.bold,
              color: isWhiteOwn ? const Color(0xFFFFB300) : titleColor,
            ),
            textAlign: TextAlign.start,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
