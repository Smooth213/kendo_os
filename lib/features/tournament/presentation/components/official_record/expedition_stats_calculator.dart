import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/expedition_event_processor.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/expedition_stats_models.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/expedition_team_match_processor.dart';

/// 遠征・公式記録の成績集計エンジン
class ExpeditionStatsCalculator {
  static ExpeditionSummaryData calculate({
    required List<MatchModel> matches,
    required Set<String> registeredTeamNames,
    required Set<String> registeredPlayerNames,
    required String selectedSummaryTeam,
  }) {
    // 1. 自チーム名の確定
    final List<String> teamsList;
    if (registeredTeamNames.isNotEmpty) {
      teamsList = registeredTeamNames.toList()..sort();
    } else {
      final teamsSet = <String>{};
      for (final m in matches) {
        if (m.redName.isNotEmpty) {
          final rTeam = m.redName.contains(':')
              ? m.redName.split(':').first.trim()
              : m.redName.trim();
          if (rTeam.isNotEmpty) teamsSet.add(rTeam);
        }
        if (m.whiteName.isNotEmpty) {
          final wTeam = m.whiteName.contains(':')
              ? m.whiteName.split(':').first.trim()
              : m.whiteName.trim();
          if (wTeam.isNotEmpty) teamsSet.add(wTeam);
        }
      }
      teamsList = teamsSet.toList()..sort();
    }

    bool isMyTeam(String teamName) {
      if (registeredTeamNames.isNotEmpty) {
        return registeredTeamNames.contains(teamName);
      }
      return teamsList.isNotEmpty && teamsList.first == teamName;
    }

    bool isMyPlayer(String playerName, String teamName) {
      if (registeredPlayerNames.isNotEmpty) {
        return registeredPlayerNames.contains(playerName);
      }
      return isMyTeam(teamName);
    }

    bool isMatchPlayed(MatchModel m) {
      return m.status == 'finished' || m.status == 'approved';
    }

    int renseikaiWin = 0, renseikaiLoss = 0, renseikaiDraw = 0;
    int honsenWin = 0, honsenLoss = 0, honsenDraw = 0;
    int moushiawaseWin = 0, moushiawaseLoss = 0, moushiawaseDraw = 0;

    final Map<String, DetailedPlayerStats> playerStatsMap = {};
    final List<ExpeditionCardResult> cardResults = [];

    // 団体戦・勝ち抜き戦（groupNameごと）
    final Map<String, List<MatchModel>> groupMap = {};
    for (final m in matches) {
      final key = (m.groupName != null && m.groupName!.isNotEmpty)
          ? m.groupName!
          : m.id;
      groupMap.putIfAbsent(key, () => []).add(m);
    }

    ExpeditionTeamMatchProcessor.processTeamMatches(
      groupMap: groupMap,
      selectedSummaryTeam: selectedSummaryTeam,
      isMyTeam: isMyTeam,
      isMyPlayer: isMyPlayer,
      isMatchPlayed: isMatchPlayed,
      playerStatsMap: playerStatsMap,
      cardResults: cardResults,
      onRecordSceneResult: (scene, isWin, isDraw) {
        if (scene == 'renseikai') {
          if (isDraw) {
            renseikaiDraw++;
          } else if (isWin) {
            renseikaiWin++;
          } else {
            renseikaiLoss++;
          }
        } else if (scene == 'moushiawase') {
          if (isDraw) {
            moushiawaseDraw++;
          } else if (isWin) {
            moushiawaseWin++;
          } else {
            moushiawaseLoss++;
          }
        } else {
          if (isDraw) {
            honsenDraw++;
          } else if (isWin) {
            honsenWin++;
          } else {
            honsenLoss++;
          }
        }
      },
    );

    final eventStats = ExpeditionEventProcessor.processEvents(
      matches: matches,
      selectedSummaryTeam: selectedSummaryTeam,
      isMyTeam: isMyTeam,
      isMyPlayer: isMyPlayer,
      isMatchPlayed: isMatchPlayed,
      playerStatsMap: playerStatsMap,
    );

    return ExpeditionSummaryData(
      teamsList: teamsList,
      renseikaiWin: renseikaiWin,
      renseikaiLoss: renseikaiLoss,
      renseikaiDraw: renseikaiDraw,
      honsenWin: honsenWin,
      honsenLoss: honsenLoss,
      honsenDraw: honsenDraw,
      moushiawaseWin: moushiawaseWin,
      moushiawaseLoss: moushiawaseLoss,
      moushiawaseDraw: moushiawaseDraw,
      teamMen: eventStats.teamMen,
      teamKote: eventStats.teamKote,
      teamDou: eventStats.teamDou,
      teamTsuki: eventStats.teamTsuki,
      teamHansoku: eventStats.teamHansoku,
      teamOther: eventStats.teamOther,
      teamTotalScored: eventStats.teamTotalScored,
      teamTotalConceded: eventStats.teamTotalConceded,
      playerStatsMap: playerStatsMap,
      cardResults: cardResults,
    );
  }
}
