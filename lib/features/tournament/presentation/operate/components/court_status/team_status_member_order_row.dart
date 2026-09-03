import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/cards/match_score_line.dart';
import 'package:kendo_os/shared/widgets/match_tables/point_mark_badge.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// チーム試合状況カード内の対戦選手・スコア表示行Widget
class TeamStatusMemberOrderRow extends StatelessWidget {
  final String redTeam;
  final String redPlayer;
  final String whiteTeam;
  final String whitePlayer;
  final List<PointMark> redPoints;
  final List<PointMark> whitePoints;
  final bool isDraw;
  final bool isFinished;
  final int redScore;
  final int whiteScore;

  const TeamStatusMemberOrderRow({
    super.key,
    required this.redTeam,
    required this.redPlayer,
    required this.whiteTeam,
    required this.whitePlayer,
    required this.redPoints,
    required this.whitePoints,
    required this.isDraw,
    this.isFinished = false,
    this.redScore = 0,
    this.whiteScore = 0,
  });

  @override
  Widget build(BuildContext context) {
    final redWon = isFinished && redScore > whiteScore;
    final whiteWon = isFinished && whiteScore > redScore;

    return Row(
      children: [
        // 赤側（道場名上・選手名下）
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (redTeam.isNotEmpty)
                Text(
                  redTeam,
                  style: TextStyle(
                    fontSize: AppFontSize.badge,
                    color: context.appColors.subTextColor,
                    fontWeight: AppFontWeight.medium,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              Text(
                redPlayer.isNotEmpty ? redPlayer : '選手未定',
                style: TextStyle(
                  fontSize: isFinished
                      ? AppFontSize.bodySmall
                      : AppFontSize.subhead,
                  fontWeight: AppFontWeight.bold,
                  color: redWon
                      ? AppKendoColors.hansokuRed
                      : (isFinished
                            ? context.appColors.textColor
                            : AppKendoColors.hansokuRed),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        // 中央：取得部位（技マークライン）
        MatchScoreLine(
          redPoints: redPoints,
          whitePoints: whitePoints,
          isDraw: isDraw,
          redColor: AppKendoColors.hansokuRed,
          whiteTextColor: context.appColors.textColor,
          dividerTextColor: context.appColors.subTextColor,
        ),

        // 白側（道場名上・選手名下）
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (whiteTeam.isNotEmpty)
                Text(
                  whiteTeam,
                  style: TextStyle(
                    fontSize: AppFontSize.badge,
                    color: context.appColors.subTextColor,
                    fontWeight: AppFontWeight.medium,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              Text(
                whitePlayer.isNotEmpty ? whitePlayer : '選手未定',
                style: TextStyle(
                  fontSize: isFinished
                      ? AppFontSize.bodySmall
                      : AppFontSize.subhead,
                  fontWeight: AppFontWeight.bold,
                  color: whiteWon
                      ? AppKendoColors.hansokuRed
                      : context.appColors.textColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
