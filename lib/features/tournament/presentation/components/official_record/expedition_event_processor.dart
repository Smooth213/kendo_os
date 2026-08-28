import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/expedition_stats_models.dart';

/// 遠征成績のスコアイベント（有効打突・失本数・技内訳）集計プロセッサ
class ExpeditionEventProcessor {
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

      for (final ev in m.events) {
        if (ev.isCanceled) continue;
        if (!ev.isIppon) continue;

        final bool evIsMine =
            (ev.side == Side.red && isTargetRed) ||
            (ev.side == Side.white && isTargetWhite);
        final bool evIsOpp =
            (ev.side == Side.red && isTargetWhite) ||
            (ev.side == Side.white && isTargetRed);

        if (evIsMine) {
          teamTotalScored++;
          final String myPlayer = ev.side == Side.red ? rPlayer : wPlayer;
          final pStats = playerStatsMap.putIfAbsent(
            myPlayer,
            () => DetailedPlayerStats(),
          );
          pStats.totalPoints++;

          if (isTeamMatch) {
            pStats.teamPoints++;
          } else {
            pStats.individualPoints++;
          }

          if (ev.isHansoku) {
            teamHansoku++;
            pStats.hansoku++;
          } else {
            switch (ev.strikeType) {
              case StrikeType.men:
                teamMen++;
                pStats.men++;
                break;
              case StrikeType.kote:
                teamKote++;
                pStats.kote++;
                break;
              case StrikeType.dou:
                teamDou++;
                pStats.dou++;
                break;
              case StrikeType.tsuki:
                teamTsuki++;
                pStats.tsuki++;
                break;
              case StrikeType.none:
                teamOther++;
                pStats.other++;
                break;
            }
          }
        }

        if (evIsOpp) {
          teamTotalConceded++;
          final String myPlayer = ev.side == Side.red ? wPlayer : rPlayer;
          final pStats = playerStatsMap.putIfAbsent(
            myPlayer,
            () => DetailedPlayerStats(),
          );
          pStats.concededPoints++;
          if (isTeamMatch) {
            pStats.teamConceded++;
          } else {
            pStats.individualConceded++;
          }
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
