import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/domain/team_progress_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/safe_timeline_provider.dart';
import 'team_progress_helper.dart';

// 後方互換性エイリアス
String extractTeamName(String name) => TeamProgressHelper.extractTeamName(name);
String extractPlayerName(String name) =>
    TeamProgressHelper.extractPlayerName(name);
String formatPlayerOrTeamDisplay(String name, {required bool isIndividual}) =>
    TeamProgressHelper.formatPlayerOrTeamDisplay(
      name,
      isIndividual: isIndividual,
    );
bool isIndividualMatch(MatchModel match) =>
    TeamProgressHelper.isIndividualMatch(match);
bool isLeagueMatch(MatchModel match) => TeamProgressHelper.isLeagueMatch(match);
bool isKachinukiMatch(MatchModel match) =>
    TeamProgressHelper.isKachinukiMatch(match);
String extractTeamMatchupTitle(MatchModel match) =>
    TeamProgressHelper.extractTeamMatchupTitle(match);
String extractCourtAndRoundDisplay(MatchModel match) =>
    TeamProgressHelper.extractCourtAndRoundDisplay(match);
bool isSideOwn({
  required String sideFullName,
  required Set<String> knownTeams,
  required Set<String> knownPlayers,
  required String myDojoName,
  String? ruleTeamName,
}) => TeamProgressHelper.isSideOwn(
  sideFullName: sideFullName,
  knownTeams: knownTeams,
  knownPlayers: knownPlayers,
  myDojoName: myDojoName,
  ruleTeamName: ruleTeamName,
);

/// チームごとの進行状況を計算するエンジン（個人戦・リーグ戦・勝ち抜き戦・団体戦完全対応）
List<TeamProgressStatus> calculateTeamProgress(
  List<MatchModel> matches, {
  String myDojoName = '',
  List<String> registeredTeamNames = const [],
  List<String> registeredPlayerNames = const [],
}) {
  if (matches.isEmpty) return [];

  final knownTeams = <String>{
    ...registeredTeamNames.where((t) => t.trim().isNotEmpty),
    if (myDojoName.trim().isNotEmpty) myDojoName.trim(),
  };

  final knownPlayers = <String>{
    ...registeredPlayerNames.where((p) => p.trim().isNotEmpty),
  };

  // 1. 試合を「自チーム名」ごとにグルーピング
  final Map<String, List<MatchModel>> teamMatchesMap = {};

  for (final match in matches) {
    final isIndiv = TeamProgressHelper.isIndividualMatch(match);

    final isRedOwn = TeamProgressHelper.isSideOwn(
      sideFullName: match.redName,
      knownTeams: knownTeams,
      knownPlayers: knownPlayers,
      myDojoName: myDojoName,
      ruleTeamName: match.rule?.teamName,
    );
    final isWhiteOwn = TeamProgressHelper.isSideOwn(
      sideFullName: match.whiteName,
      knownTeams: knownTeams,
      knownPlayers: knownPlayers,
      myDojoName: myDojoName,
      ruleTeamName: match.rule?.teamName,
    );

    final redTeamTitle = TeamProgressHelper.resolveSideTeamTitle(
      sideFullName: match.redName,
      knownTeams: knownTeams,
      knownPlayers: knownPlayers,
      myDojoName: myDojoName,
      isIndividual: isIndiv,
    );
    final whiteTeamTitle = TeamProgressHelper.resolveSideTeamTitle(
      sideFullName: match.whiteName,
      knownTeams: knownTeams,
      knownPlayers: knownPlayers,
      myDojoName: myDojoName,
      isIndividual: isIndiv,
    );

    if (isRedOwn && !isWhiteOwn) {
      teamMatchesMap.putIfAbsent(redTeamTitle, () => []).add(match);
    } else if (isWhiteOwn && !isRedOwn) {
      teamMatchesMap.putIfAbsent(whiteTeamTitle, () => []).add(match);
    } else if (isRedOwn && isWhiteOwn) {
      // 部内戦などの場合は両方に登録
      teamMatchesMap.putIfAbsent(redTeamTitle, () => []).add(match);
      if (whiteTeamTitle != redTeamTitle) {
        teamMatchesMap.putIfAbsent(whiteTeamTitle, () => []).add(match);
      }
    } else {
      // どちらもマッチしない場合、ルールチーム名または赤側チーム
      final fallbackTeam = (match.rule?.teamName.isNotEmpty == true)
          ? match.rule!.teamName
          : (redTeamTitle.isNotEmpty
                ? redTeamTitle
                : (match.groupName ?? '自チーム'));
      teamMatchesMap.putIfAbsent(fallbackTeam, () => []).add(match);
    }
  }

  final List<TeamProgressStatus> results = [];

  for (final entry in teamMatchesMap.entries) {
    final teamName = entry.key;
    final teamMatches = List<MatchModel>.from(entry.value)
      ..sort((a, b) => a.order.compareTo(b.order));

    // 2. チーム内の試合を「対戦カード（団体戦グループまたは個人戦）」単位でグルーピング
    final Map<String, List<MatchModel>> cardGroups = {};
    for (final m in teamMatches) {
      final key = (m.groupName != null && m.groupName!.isNotEmpty)
          ? m.groupName!
          : m.id;
      cardGroups.putIfAbsent(key, () => []).add(m);
    }

    int completedCards = 0;
    int totalCards = cardGroups.length;
    int wins = 0;
    int losses = 0;
    int draws = 0;
    int points = 0;

    MatchModel? inProgress;
    MatchModel? lastFinished;
    MatchModel? nextWaiting;
    String? targetGroupId;

    for (final cardEntry in cardGroups.entries) {
      final cardMatches = cardEntry.value;
      final isCardAllFinished = cardMatches.every(
        (m) => m.status == 'finished' || m.status == 'approved',
      );
      final hasCardLive = cardMatches.any((m) => m.status == 'in_progress');
      final isCardWaiting = cardMatches.every(
        (m) => m.status == 'waiting' || m.status == 'ready',
      );

      // 対戦カード内の勝敗集計
      int cardMyWins = 0;
      int cardOppWins = 0;
      int cardMyPoints = 0;
      int cardOppPoints = 0;

      for (final m in cardMatches) {
        final redTeam = TeamProgressHelper.extractTeamName(m.redName);
        final isRedMyTeam =
            redTeam == teamName ||
            TeamProgressHelper.isSideOwn(
              sideFullName: m.redName,
              knownTeams: knownTeams,
              knownPlayers: knownPlayers,
              myDojoName: myDojoName,
              ruleTeamName: m.rule?.teamName,
            );

        final myScore = isRedMyTeam ? m.redScore : m.whiteScore;
        final oppScore = isRedMyTeam ? m.whiteScore : m.redScore;

        cardMyPoints += myScore;
        cardOppPoints += oppScore;
        if (myScore > oppScore) cardMyWins++;
        if (oppScore > myScore) cardOppWins++;

        if (m.status == 'in_progress' && inProgress == null) {
          inProgress = m;
        }
      }

      points += cardMyPoints;

      if (isCardAllFinished) {
        completedCards++;
        lastFinished = cardMatches.last;
        if (cardMatches.first.groupName != null &&
            cardMatches.first.groupName!.isNotEmpty) {
          targetGroupId = cardMatches.first.groupName;
        }

        if (cardMyWins > cardOppWins) {
          wins++;
        } else if (cardOppWins > cardMyWins) {
          losses++;
        } else {
          if (cardMyPoints > cardOppPoints) {
            wins++;
          } else if (cardOppPoints > cardMyPoints) {
            losses++;
          } else {
            draws++;
          }
        }
      } else if (hasCardLive) {
        if (targetGroupId == null &&
            cardMatches.first.groupName != null &&
            cardMatches.first.groupName!.isNotEmpty) {
          targetGroupId = cardMatches.first.groupName;
        }
      } else if (isCardWaiting && nextWaiting == null && inProgress == null) {
        nextWaiting = cardMatches.first;
      }
    }

    if (inProgress != null && nextWaiting == null) {
      nextWaiting = teamMatches.firstWhere(
        (m) =>
            (m.status == 'waiting' || m.status == 'ready') &&
            m.order > inProgress!.order,
        orElse: () => inProgress!,
      );
      if (nextWaiting.id == inProgress.id) {
        nextWaiting = null;
      }
    }

    final representativeMatch =
        inProgress ?? nextWaiting ?? lastFinished ?? teamMatches.first;
    final categoryName =
        representativeMatch.category ?? representativeMatch.matchType;
    final currentCourtName = TeamProgressHelper.extractCourtAndRoundDisplay(
      representativeMatch,
    );
    final matchupTitle = TeamProgressHelper.extractTeamMatchupTitle(
      representativeMatch,
    );

    targetGroupId ??=
        (representativeMatch.groupName != null &&
            representativeMatch.groupName!.isNotEmpty)
        ? representativeMatch.groupName
        : null;

    int waitingCount = 0;
    if (nextWaiting != null && inProgress == null) {
      waitingCount = 1;
    }

    results.add(
      TeamProgressStatus(
        teamName: teamName,
        categoryName: categoryName,
        currentCourtName: currentCourtName,
        matchupTitle: matchupTitle,
        targetGroupId: targetGroupId,
        tournamentId: representativeMatch.tournamentId,
        matches: teamMatches,
        inProgressMatch: inProgress,
        lastFinishedMatch: lastFinished,
        nextWaitingMatch: nextWaiting,
        completedCount: completedCards,
        totalCount: totalCards,
        waitingMatchCount: waitingCount,
        totalWins: wins,
        totalLosses: losses,
        totalDraws: draws,
        totalPoints: points,
        hasLiveMatch: inProgress != null,
      ),
    );
  }

  results.sort((a, b) {
    if (a.hasLiveMatch != b.hasLiveMatch) {
      return a.hasLiveMatch ? -1 : 1;
    }
    return a.teamName.compareTo(b.teamName);
  });

  return results;
}

/// 🥋 チーム進行状況リストを提供するRiverpodプロバイダー
final teamProgressListProvider = Provider<List<TeamProgressStatus>>((ref) {
  final matches = ref.watch(matchListProvider);
  final myDojoAsync = ref.watch(currentDojoNameProvider);
  final myDojoName = myDojoAsync.value ?? '';

  final teamsAsync = ref.watch(customTeamNamesProvider);
  final registeredTeams = teamsAsync.value ?? [];

  final playersAsync = ref.watch(timelinePlayerListProvider);
  final registeredPlayers = (playersAsync.value ?? [])
      .map((p) => p.name.trim())
      .where((n) => n.isNotEmpty)
      .toList();

  return calculateTeamProgress(
    matches,
    myDojoName: myDojoName,
    registeredTeamNames: registeredTeams,
    registeredPlayerNames: registeredPlayers,
  );
});
