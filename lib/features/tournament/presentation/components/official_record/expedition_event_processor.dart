import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/expedition_stats_models.dart';

/// 遠征成績のスコアイベント（有効打突・失本数・技内訳）集計プロセッサ
class ExpeditionEventProcessor {
  /// 試合の有効スコア（赤・白の取得本数）をイベント履歴（Undo/相殺対応）またはMatchModelから算出
  static ({int red, int white}) getEffectiveScores(MatchModel match) {
    if (match.events.isNotEmpty) {
      final bool hasAnyScoreOrUndo = match.events.any(
        (e) =>
            e.isIppon ||
            e.isHansoku ||
            e.isFusen ||
            e.isKataJudge ||
            e.isHantei ||
            e.isUndo ||
            e.type == PointType.undo,
      );
      if (hasAnyScoreOrUndo) {
        final analysis = KendoRuleEngine().analyzeHistory(
          match.events,
          match,
          match.rule,
        );
        return (
          red: analysis.context.redIppon,
          white: analysis.context.whiteIppon,
        );
      }
    }
    return (red: match.redScore, white: match.whiteScore);
  }

  static ({
    int teamMen,
    int teamKote,
    int teamDou,
    int teamTsuki,
    int teamHansoku,
    int teamOther,
    int teamTotalScored,
    int teamTotalConceded,
  })
  processEvents({
    required List<MatchModel> matches,
    required String selectedSummaryTeam,
    required bool Function(String) isMyTeam,
    required bool Function(String, String) isMyPlayer,
    required bool Function(MatchModel) isMatchPlayed,
    required Map<String, DetailedPlayerStats> playerStatsMap,
  }) {
    int teamMen = 0;
    int teamKote = 0;
    int teamDou = 0;
    int teamTsuki = 0;
    int teamHansoku = 0;
    int teamOther = 0;
    int teamTotalScored = 0;
    int teamTotalConceded = 0;

    for (final m in matches) {
      if (!isMatchPlayed(m)) continue;

      final rTeam = m.redName.contains(':')
          ? m.redName.split(':').first.trim()
          : m.redName.trim();
      final wTeam = m.whiteName.contains(':')
          ? m.whiteName.split(':').first.trim()
          : m.whiteName.trim();
      final rPlayer = m.redName.contains(':')
          ? m.redName.split(':').last.trim()
          : m.redName.trim();
      final wPlayer = m.whiteName.contains(':')
          ? m.whiteName.split(':').last.trim()
          : m.whiteName.trim();

      final bool rIsMine = isMyTeam(rTeam) || isMyPlayer(rPlayer, rTeam);
      final bool wIsMine = isMyTeam(wTeam) || isMyPlayer(wPlayer, wTeam);
      if (!rIsMine && !wIsMine) continue;

      final bool isTargetRed =
          (selectedSummaryTeam == '全体' && rIsMine) ||
          (selectedSummaryTeam == rTeam);
      final bool isTargetWhite =
          (selectedSummaryTeam == '全体' && wIsMine) ||
          (selectedSummaryTeam == wTeam);
      if (!isTargetRed && !isTargetWhite) continue;

      final bool isTeamMatch =
          (m.groupName != null && m.groupName!.isNotEmpty) ||
          m.isKachinuki ||
          m.matchType.contains('団体') ||
          m.matchType == '先鋒' ||
          m.matchType == '次鋒' ||
          m.matchType == '中堅' ||
          m.matchType == '副将' ||
          m.matchType == '大将' ||
          m.matchType == '代表戦';

      final effectiveScores = getEffectiveScores(m);
      final int redScoreActual = effectiveScores.red;
      final int whiteScoreActual = effectiveScores.white;

      // ★ KendoRuleEngineのfilterActiveEventsを通してUndo取り消しイベントを安全に除外
      final activeEvents = KendoRuleEngine().filterActiveEvents(m.events);

      int rMen = 0, rKote = 0, rDou = 0, rTsuki = 0, rHansoku = 0, rOther = 0;
      int wMen = 0, wKote = 0, wDou = 0, wTsuki = 0, wHansoku = 0, wOther = 0;

      for (final ev in activeEvents) {
        if (!ev.isIppon) continue;

        if (ev.side == Side.red) {
          if (ev.isHansoku) {
            rHansoku++;
          } else {
            switch (ev.strikeType) {
              case StrikeType.men:
                rMen++;
                break;
              case StrikeType.kote:
                rKote++;
                break;
              case StrikeType.dou:
                rDou++;
                break;
              case StrikeType.tsuki:
                rTsuki++;
                break;
              case StrikeType.none:
                rOther++;
                break;
            }
          }
        } else if (ev.side == Side.white) {
          if (ev.isHansoku) {
            wHansoku++;
          } else {
            switch (ev.strikeType) {
              case StrikeType.men:
                wMen++;
                break;
              case StrikeType.kote:
                wKote++;
                break;
              case StrikeType.dou:
                wDou++;
                break;
              case StrikeType.tsuki:
                wTsuki++;
                break;
              case StrikeType.none:
                wOther++;
                break;
            }
          }
        }
      }

      final int rActiveTotal = rMen + rKote + rDou + rTsuki + rHansoku + rOther;
      if (redScoreActual > rActiveTotal) {
        rOther += (redScoreActual - rActiveTotal);
      }
      final int wActiveTotal = wMen + wKote + wDou + wTsuki + wHansoku + wOther;
      if (whiteScoreActual > wActiveTotal) {
        wOther += (whiteScoreActual - wActiveTotal);
      }

      final int rTotal = redScoreActual > rActiveTotal
          ? redScoreActual
          : rActiveTotal;
      final int wTotal = whiteScoreActual > wActiveTotal
          ? whiteScoreActual
          : wActiveTotal;

      if (isTargetRed) {
        teamTotalScored += rTotal;
        teamTotalConceded += wTotal;
        teamMen += rMen;
        teamKote += rKote;
        teamDou += rDou;
        teamTsuki += rTsuki;
        teamHansoku += rHansoku;
        teamOther += rOther;

        if (rPlayer.isNotEmpty && isMyPlayer(rPlayer, rTeam)) {
          final pStats = playerStatsMap.putIfAbsent(
            rPlayer,
            () => DetailedPlayerStats(),
          );
          pStats.totalPoints += rTotal;
          pStats.concededPoints += wTotal;
          if (isTeamMatch) {
            pStats.teamPoints += rTotal;
            pStats.teamConceded += wTotal;
          } else {
            pStats.individualPoints += rTotal;
            pStats.individualConceded += wTotal;
          }
          pStats.men += rMen;
          pStats.kote += rKote;
          pStats.dou += rDou;
          pStats.tsuki += rTsuki;
          pStats.hansoku += rHansoku;
          pStats.other += rOther;
        }
      }

      if (isTargetWhite) {
        teamTotalScored += wTotal;
        teamTotalConceded += rTotal;
        teamMen += wMen;
        teamKote += wKote;
        teamDou += wDou;
        teamTsuki += wTsuki;
        teamHansoku += wHansoku;
        teamOther += wOther;

        if (wPlayer.isNotEmpty && isMyPlayer(wPlayer, wTeam)) {
          final pStats = playerStatsMap.putIfAbsent(
            wPlayer,
            () => DetailedPlayerStats(),
          );
          pStats.totalPoints += wTotal;
          pStats.concededPoints += rTotal;
          if (isTeamMatch) {
            pStats.teamPoints += wTotal;
            pStats.teamConceded += rTotal;
          } else {
            pStats.individualPoints += wTotal;
            pStats.individualConceded += rTotal;
          }
          pStats.men += wMen;
          pStats.kote += wKote;
          pStats.dou += wDou;
          pStats.tsuki += wTsuki;
          pStats.hansoku += wHansoku;
          pStats.other += wOther;
        }
      }
    }

    return (
      teamMen: teamMen,
      teamKote: teamKote,
      teamDou: teamDou,
      teamTsuki: teamTsuki,
      teamHansoku: teamHansoku,
      teamOther: teamOther,
      teamTotalScored: teamTotalScored,
      teamTotalConceded: teamTotalConceded,
    );
  }
}
