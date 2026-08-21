import 'package:flutter/material.dart';
import 'package:kendo_os/features/match/application/mappers/match_projection_mapper.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/tournament/domain/services/bunaiksen_helper.dart';
import 'package:kendo_os/features/viewer/components/viewer_point_box_cell.dart';
import 'package:kendo_os/features/viewer/components/viewer_vertical_player_name_cell.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 部内戦公式記録・団体戦テーブルのセルおよび行ビルダー
class BunaiksenTeamScoreTableRowBuilder {
  static TableRow buildTeamRow({
    required List<MatchModel> matches,
    required bool isRed,
    required String teamName,
    required bool isDark,
  }) {
    return TableRow(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Text(
              teamName,
              style: TextStyle(
                color: isRed
                    ? (isDark
                          ? const Color(0xFFE53935)
                          : const Color(0xFFE53935))
                    : (isDark
                          ? const Color(0xFF2196F3)
                          : const Color(0xFF2196F3)),
                fontWeight: AppFontWeight.bold,
                fontSize: AppFontSize.caption,
              ),
            ),
          ),
        ),
        ...matches.map((m) {
          final name = isRed ? m.redName : m.whiteName;
          final teamLastNames = matches
              .map((x) {
                final xName = isRed ? x.redName : x.whiteName;
                return BunaiksenHelper.parseName(xName)['last']!;
              })
              .where((s) => s.isNotEmpty)
              .toList();

          return nameCell(
            name,
            isDark,
            teamLastNames,
            isDaihyo: m.matchType == '代表戦',
          );
        }),
        summaryCell(matches, isRed, isDark),
      ],
    );
  }

  static Widget nameCell(
    String rawName,
    bool isDark,
    List<String> teamLastNames, {
    bool isDaihyo = false,
  }) {
    if (rawName.contains('欠員')) {
      return Container(
        color: isDaihyo
            ? (isDark
                  ? const Color(0xFFE53935).withValues(alpha: 0.15)
                  : const Color(0xFFE53935))
            : AppKendoColors.transparent,
      );
    }

    final parsed = BunaiksenHelper.parseName(rawName);
    final showInitial =
        teamLastNames.where((n) => n == parsed['last']).length > 1 &&
        parsed['first']!.isNotEmpty;

    return Container(
      color: isDaihyo
          ? (isDark
                ? const Color(0xFFE53935).withValues(alpha: 0.15)
                : const Color(0xFFE53935))
          : AppKendoColors.transparent,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.xs,
          ),
          child: ViewerVerticalPlayerNameCell(
            text: parsed['last']!,
            initial: showInitial ? parsed['first']!.substring(0, 1) : '',
            isDark: isDark,
          ),
        ),
      ),
    );
  }

  static Widget scoreCell(MatchModel m, bool isDark, bool isSummary) {
    if (isSummary) {
      return Container(height: 70, color: AppKendoColors.transparent);
    }
    final isDone = m.status == 'finished' || m.status == 'approved';
    final rScore = (m.redScore as num).toInt();
    final wScore = (m.whiteScore as num).toInt();
    final themeColors = AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
    final cardColor = themeColors.cardBackground;

    final engine = KendoRuleEngine();
    final analysis = engine.analyzeHistory(m.events, m, m.rule);
    final proj = MatchProjectionMapper.toProjection(m, analysis);
    final bool rIsFirst = proj.firstPointSide == 'red';
    final bool wIsFirst = proj.firstPointSide == 'white';

    final rDisplays = analysis.displays[Side.red] ?? [];
    final wDisplays = analysis.displays[Side.white] ?? [];

    final redPts = <OfficialPointDisplay>[];
    for (int i = 0; i < rDisplays.length; i++) {
      redPts.add(OfficialPointDisplay(rDisplays[i].mark, i == 0 && rIsFirst));
    }
    final whitePts = <OfficialPointDisplay>[];
    for (int i = 0; i < wDisplays.length; i++) {
      whitePts.add(OfficialPointDisplay(wDisplays[i].mark, i == 0 && wIsFirst));
    }

    return Container(
      height: 70,
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Divider(
            color: isDark
                ? const Color(0xFFFFFFFF).withValues(alpha: 0.10)
                : const Color(0x33000000),
            thickness: 1,
            height: 0,
          ),
          if (isDone && rScore == wScore)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
              color: cardColor,
              child: Text(
                '✕',
                style: TextStyle(
                  fontSize: AppFontSize.subhead,
                  fontWeight: AppFontWeight.black,
                  color: isDark
                      ? const Color(0xFFFFFFFF)
                      : const Color(0x8A000000),
                ),
              ),
            ),
          Column(
            children: [
              Expanded(
                child: ViewerPointBoxCell(
                  pts: redPts,
                  isWinner: isDone && rScore > wScore,
                  isRed: true,
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: ViewerPointBoxCell(
                  pts: whitePts,
                  isWinner: isDone && wScore > rScore,
                  isRed: false,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget teamResultCell(String winner, bool isDark, bool allFinished) {
    final textColor = isDark
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF000000);
    final dividerColor = isDark
        ? const Color(0xFF38383A)
        : const Color(0x33000000);

    return Container(
      height: 70,
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (winner != 'draw' || !allFinished)
            Divider(color: dividerColor, thickness: 1, height: 0),
          if (allFinished) ...[
            if (winner == 'draw')
              Center(
                child: ViewerVerticalPlayerNameCell(
                  text: '引き分け',
                  initial: '',
                  isDark: isDark,
                ),
              )
            else
              Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        winner == 'red' ? '勝' : '負',
                        style: TextStyle(
                          fontSize: AppFontSize.body,
                          fontWeight: AppFontWeight.bold,
                          color: winner == 'red'
                              ? const Color(0xFFE53935)
                              : textColor,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        winner == 'white' ? '勝' : '負',
                        style: TextStyle(
                          fontSize: AppFontSize.body,
                          fontWeight: AppFontWeight.bold,
                          color: winner == 'white'
                              ? const Color(0xFF2196F3)
                              : textColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }

  static Widget summaryCell(List<MatchModel> ms, bool isRed, bool isDark) {
    int wins = 0, pts = 0;
    for (var m in ms) {
      if (m.matchType == '代表戦') continue;
      final r = (m.redScore as num).toInt();
      final w = (m.whiteScore as num).toInt();
      pts += isRed ? r : w;
      if (isRed && r > w) {
        wins++;
      } else if (!isRed && w > r) {
        wins++;
      }
    }
    return Center(
      child: Text(
        '$pts\n--\n$wins',
        style: TextStyle(
          fontWeight: AppFontWeight.bold,
          fontSize: AppFontSize.small,
          color: isDark ? const Color(0xFFFFFFFF) : const Color(0xDE000000),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
