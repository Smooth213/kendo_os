import 'package:flutter/material.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/domain/team_progress_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/court_status/team_status_member_order_row.dart';
import 'package:kendo_os/shared/presentation/utils/match_calculator_helper.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 🥋 チーム試合状況カードの各セクションUIヘルパー
class TeamStatusCardSections {
  TeamStatusCardSections._();

  static String _extractTeam(String fullName) {
    if (fullName.contains(':')) {
      return fullName.split(':').first.trim();
    }
    return '';
  }

  static String _extractPlayer(String fullName) {
    if (fullName.contains(':')) {
      return fullName.split(':').last.trim();
    }
    return fullName.trim();
  }

  /// 進行中試合セクション
  static Widget buildLiveMatchSection(
    BuildContext context,
    MatchModel match,
    bool isDark,
  ) {
    final redTeam = _extractTeam(match.redName);
    final redPlayer = _extractPlayer(match.redName);
    final whiteTeam = _extractTeam(match.whiteName);
    final whitePlayer = _extractPlayer(match.whiteName);

    final points = MatchCalculatorHelper.extractPointsFromModel(match);
    final redPoints = points['red'] ?? [];
    final whitePoints = points['white'] ?? [];
    final isDraw =
        (match.status == 'finished' || match.status == 'approved') &&
        match.redScore == match.whiteScore;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF9FAFB),
        borderRadius: AppRadius.medium,
        border: Border.all(
          color: AppKendoColors.hansokuRed.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '【${match.matchType}】',
                style: TextStyle(
                  fontSize: AppFontSize.bodySmall,
                  fontWeight: AppFontWeight.bold,
                  color: context.appColors.textColor,
                ),
              ),
              const Text(
                'タップして記録を開く 👉',
                style: TextStyle(
                  fontSize: AppFontSize.caption,
                  fontWeight: AppFontWeight.medium,
                  color: AppKendoColors.indigo,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          TeamStatusMemberOrderRow(
            redTeam: redTeam,
            redPlayer: redPlayer,
            whiteTeam: whiteTeam,
            whitePlayer: whitePlayer,
            redPoints: redPoints,
            whitePoints: whitePoints,
            isDraw: isDraw,
            isFinished:
                match.status == 'finished' || match.status == 'approved',
            redScore: match.redScore,
            whiteScore: match.whiteScore,
          ),
        ],
      ),
    );
  }

  /// 待機中試合セクション
  static Widget buildWaitingMatchSection(
    BuildContext context,
    MatchModel nextMatch,
    bool isDark,
  ) {
    final redTeam = _extractTeam(nextMatch.redName);
    final redPlayer = _extractPlayer(nextMatch.redName);
    final whiteTeam = _extractTeam(nextMatch.whiteName);
    final whitePlayer = _extractPlayer(nextMatch.whiteName);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF9FAFB),
        borderRadius: AppRadius.medium,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppKendoColors.indigo.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.schedule,
              size: 16,
              color: AppKendoColors.indigo,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '次の対戦予定: 【${nextMatch.matchType}】',
                  style: TextStyle(
                    fontSize: AppFontSize.bodySmall,
                    fontWeight: AppFontWeight.bold,
                    color: context.appColors.textColor,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        redTeam.isNotEmpty ? '$redPlayer（$redTeam）' : redPlayer,
                        style: TextStyle(
                          fontSize: AppFontSize.caption,
                          color: context.appColors.subTextColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                      ),
                      child: Text(
                        'vs',
                        style: TextStyle(
                          fontSize: AppFontSize.caption,
                          fontWeight: AppFontWeight.bold,
                          color: context.appColors.subTextColor,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        whiteTeam.isNotEmpty
                            ? '$whitePlayer（$whiteTeam）'
                            : whitePlayer,
                        style: TextStyle(
                          fontSize: AppFontSize.caption,
                          color: context.appColors.subTextColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 終了試合セクション
  static Widget buildFinishedMatchSection(
    BuildContext context,
    MatchModel lastMatch,
    bool isDark,
  ) {
    final redTeam = _extractTeam(lastMatch.redName);
    final redPlayer = _extractPlayer(lastMatch.redName);
    final whiteTeam = _extractTeam(lastMatch.whiteName);
    final whitePlayer = _extractPlayer(lastMatch.whiteName);

    final points = MatchCalculatorHelper.extractPointsFromModel(lastMatch);
    final redPoints = points['red'] ?? [];
    final whitePoints = points['white'] ?? [];
    final isDraw = lastMatch.redScore == lastMatch.whiteScore;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF9FAFB),
        borderRadius: AppRadius.medium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 16,
                color: AppKendoColors.indigo,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '直前の結果: 【${lastMatch.matchType}】',
                style: TextStyle(
                  fontSize: AppFontSize.caption,
                  fontWeight: AppFontWeight.bold,
                  color: context.appColors.subTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          TeamStatusMemberOrderRow(
            redTeam: redTeam,
            redPlayer: redPlayer,
            whiteTeam: whiteTeam,
            whitePlayer: whitePlayer,
            redPoints: redPoints,
            whitePoints: whitePoints,
            isDraw: isDraw,
            isFinished: true,
            redScore: lastMatch.redScore,
            whiteScore: lastMatch.whiteScore,
          ),
        ],
      ),
    );
  }

  /// フッタースタッツ
  static Widget buildFooterStats(
    BuildContext context,
    TeamProgressStatus status,
    bool isDark,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              '通算: ',
              style: TextStyle(
                fontSize: AppFontSize.caption,
                color: context.appColors.subTextColor,
              ),
            ),
            Text(
              '${status.totalWins}勝 ${status.totalLosses}敗 ${status.totalDraws}分',
              style: TextStyle(
                fontSize: AppFontSize.bodySmall,
                fontWeight: AppFontWeight.bold,
                color: context.appColors.textColor,
              ),
            ),
            if (status.totalPoints > 0) ...[
              const SizedBox(width: AppSpacing.xs),
              Text(
                '(${status.totalPoints}本)',
                style: TextStyle(
                  fontSize: AppFontSize.caption,
                  fontWeight: AppFontWeight.medium,
                  color: context.appColors.primaryAccent,
                ),
              ),
            ],
          ],
        ),
        Row(
          children: [
            Text(
              '進行: ${status.completedCount}/${status.totalCount} 試合',
              style: TextStyle(
                fontSize: AppFontSize.caption,
                color: context.appColors.subTextColor,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            SizedBox(
              width: 48,
              child: ClipRRect(
                borderRadius: AppRadius.capsule,
                child: LinearProgressIndicator(
                  value: status.progressRatio,
                  backgroundColor: isDark
                      ? const Color(0xFF3A3A3C)
                      : const Color(0xFFE5E5EA),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppKendoColors.indigo,
                  ),
                  minHeight: 4,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
