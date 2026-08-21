import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/shared/utils/text_sanitizer.dart';
import 'package:uuid/uuid.dart';

/// オーダー編成画面における試合データ生成ヘルパー
class OrderSetupMatchGenerator {
  /// 選択された選手・オーダー情報から一括保存用の MatchModel リストを生成
  static List<MatchModel> generateMatches({
    required String tournamentId,
    required MatchRule rule,
    required List<String> positions,
    required Map<int, String> selectedPlayers,
    required Map<int, String> opponentPlayers,
    required String opponentTeamInput,
    required bool isOwnTeamRed,
    required List<String> leagueParticipants,
    required Map<String, List<String>> leagueTeamOrders,
    required String matchType,
    required bool isStartNow,
    required double baseOrder,
  }) {
    final List<MatchModel> matchesToSave = [];

    // リーグ戦であることを明示するタグ
    final String saveNote = rule.isLeague
        ? '[リーグ戦] ${rule.note}'.trim()
        : rule.note;
    // リーグ全体を1つのアコーディオンにまとめるための共通ID
    final String leagueGroupId = rule.isLeague ? const Uuid().v4() : '';

    final List<List<String>> pairings = [];
    final String myTeamName = rule.teamName.isNotEmpty ? rule.teamName : '自チーム';
    String opTeamName = TextSanitizer.clean(opponentTeamInput);
    if (opTeamName.isEmpty) opTeamName = '対戦相手';

    if (rule.isLeague) {
      // リーグ戦の総当たりペアを生成
      for (int i = 0; i < leagueParticipants.length; i++) {
        for (int j = i + 1; j < leagueParticipants.length; j++) {
          pairings.add([leagueParticipants[i], leagueParticipants[j]]);
        }
      }
    } else {
      if (isOwnTeamRed) {
        pairings.add([myTeamName, opTeamName]);
      } else {
        pairings.add([opTeamName, myTeamName]);
      }
    }

    for (int pIndex = 0; pIndex < pairings.length; pIndex++) {
      final pair = pairings[pIndex];
      final String teamGroupId = rule.isLeague
          ? leagueGroupId
          : const Uuid().v4();

      if (rule.isKachinuki) {
        final List<String> redFull = [];
        final List<String> whiteFull = [];

        for (int i = 0; i < positions.length; i++) {
          String myP = selectedPlayers[i] ?? '未定';
          if (myP.isEmpty) myP = '未定';
          String opP = opponentPlayers[i]?.trim() ?? '';
          if (opP.isEmpty) opP = '選手';
          final String myFull = '$myTeamName : $myP';
          final String opFull = '$opTeamName : $opP';
          String rN, wN;
          if (rule.isLeague) {
            final String rTeam = pair[0];
            final String wTeam = pair[1];
            String rPlayer = (rTeam == '自チーム')
                ? myP
                : (leagueTeamOrders[rTeam]?[i] ?? '選手');
            if (rPlayer.isEmpty) rPlayer = '選手';
            String wPlayer = (wTeam == '自チーム')
                ? myP
                : (leagueTeamOrders[wTeam]?[i] ?? '選手');
            if (wPlayer.isEmpty) wPlayer = '選手';

            rN = (rTeam == '自チーム') ? myFull : '$rTeam : $rPlayer';
            wN = (wTeam == '自チーム') ? myFull : '$wTeam : $wPlayer';
          } else {
            rN = isOwnTeamRed ? myFull : opFull;
            wN = isOwnTeamRed ? opFull : myFull;
          }
          redFull.add(rN);
          whiteFull.add(wN);
        }

        final matchId = const Uuid().v4();
        final newMatch = MatchModel(
          id: matchId,
          tournamentId: tournamentId,
          category: rule.category.isNotEmpty ? rule.category : null,
          groupName: teamGroupId,
          matchType: positions[0],
          whiteName: whiteFull[0],
          redName: redFull[0],
          status: (isStartNow && pIndex == 0) ? 'in_progress' : 'waiting',
          refereeNames: [],
          matchTimeMinutes: rule.matchTimeMinutes,
          isRunningTime: rule.isRunningTime,
          hasExtension: rule.enchoTimeMinutes > 0 || rule.isEnchoUnlimited,
          extensionTimeMinutes: rule.enchoTimeMinutes,
          extensionCount: rule.enchoCount,
          hasHantei: rule.hasHantei,
          order: baseOrder + (pIndex * 10),
          note: saveNote,
          isKachinuki: true,
          matchScene: rule.matchScene != 'honsen'
              ? rule.matchScene
              : (rule.isRenseikai ? 'renseikai' : 'honsen'),
          rule: rule,
          redRemaining: redFull.length > 1 ? redFull.sublist(1) : [],
          whiteRemaining: whiteFull.length > 1 ? whiteFull.sublist(1) : [],
        );
        matchesToSave.add(newMatch);
      } else {
        for (int i = 0; i < positions.length; i++) {
          final String matchId = const Uuid().v4();
          final posName = positions[i];
          String myP = selectedPlayers[i] ?? '未定';
          if (myP.isEmpty) myP = '未定';
          String opP = opponentPlayers[i]?.trim() ?? '';
          if (opP.isEmpty) opP = '選手';
          final String myFull = '$myTeamName : $myP';
          final String opFull = '$opTeamName : $opP';
          String rName, wName;
          if (rule.isLeague) {
            final String rTeam = pair[0];
            final String wTeam = pair[1];
            String rPlayer = (rTeam == '自チーム')
                ? myP
                : (leagueTeamOrders[rTeam]?[i] ?? '選手');
            if (rPlayer.isEmpty) rPlayer = '選手';
            String wPlayer = (wTeam == '自チーム')
                ? myP
                : (leagueTeamOrders[wTeam]?[i] ?? '選手');
            if (wPlayer.isEmpty) wPlayer = '選手';

            if (matchType.contains('個人戦')) {
              rName = (rTeam == '自チーム') ? myFull : rTeam;
              wName = (wTeam == '自チーム') ? myFull : wTeam;
            } else {
              rName = (rTeam == '自チーム') ? myFull : '$rTeam : $rPlayer';
              wName = (wTeam == '自チーム') ? myFull : '$wTeam : $wPlayer';
            }
          } else {
            rName = isOwnTeamRed ? myFull : opFull;
            wName = isOwnTeamRed ? opFull : myFull;
          }
          final bool isFirstMatchOfAll = (pIndex == 0 && i == 0);
          final newMatch = MatchModel(
            id: matchId,
            tournamentId: tournamentId,
            category: rule.category.isNotEmpty ? rule.category : null,
            groupName: teamGroupId,
            matchType: posName,
            redName: rName,
            whiteName: wName,
            status: (isStartNow && isFirstMatchOfAll)
                ? 'in_progress'
                : 'waiting',
            refereeNames: [],
            matchTimeMinutes: rule.matchTimeMinutes,
            isRunningTime: rule.isRunningTime,
            hasExtension:
                rule.enchoTimeMinutes > 0 ||
                rule.isEnchoUnlimited ||
                posName.contains('代表'),
            extensionTimeMinutes: rule.enchoTimeMinutes,
            extensionCount: rule.enchoCount,
            hasHantei: rule.hasHantei,
            order: baseOrder + (pIndex * 10) + i,
            note: saveNote,
            matchScene: rule.matchScene != 'honsen'
                ? rule.matchScene
                : (rule.isRenseikai ? 'renseikai' : 'honsen'),
            rule: rule,
          );
          matchesToSave.add(newMatch);
        }
      }
    }

    return matchesToSave;
  }
}
