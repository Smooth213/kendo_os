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

/// チームごとの進行状況を計算するエンジン（全試合・全対戦カード完全展開対応）
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

  // 1. 全試合を「対戦カード（団体戦グループまたは個人戦試合）」ごとにグルーピング
  final Map<String, List<MatchModel>> cardGroups = {};
  for (final m in matches) {
    final key = (m.groupName != null && m.groupName!.isNotEmpty)
        ? m.groupName!
        : m.id;
    cardGroups.putIfAbsent(key, () => []).add(m);
  }

  final List<TeamProgressStatus> results = [];

  for (final entry in cardGroups.entries) {
    final cardMatches = List<MatchModel>.from(entry.value)
      ..sort((a, b) => a.order.compareTo(b.order));
    if (cardMatches.isEmpty) continue;

    final firstMatch = cardMatches.first;
    final isIndiv = TeamProgressHelper.isIndividualMatch(firstMatch);

    // 自チーム・自選手が関わっているか判定
    bool hasRedOwn = false;
    bool hasWhiteOwn = false;

    for (final m in cardMatches) {
      if (TeamProgressHelper.isSideOwn(
        sideFullName: m.redName,
        knownTeams: knownTeams,
        knownPlayers: knownPlayers,
        myDojoName: myDojoName,
        ruleTeamName: m.rule?.teamName,
      )) {
        hasRedOwn = true;
      }
      if (TeamProgressHelper.isSideOwn(
        sideFullName: m.whiteName,
        knownTeams: knownTeams,
        knownPlayers: knownPlayers,
        myDojoName: myDojoName,
        ruleTeamName: m.rule?.teamName,
      )) {
        hasWhiteOwn = true;
      }
    }

    // どちらの側を自チームとして表示するか決定
    final bool isRedPrimary;
    if (hasRedOwn && !hasWhiteOwn) {
      isRedPrimary = true;
    } else if (hasWhiteOwn && !hasRedOwn) {
      isRedPrimary = false;
    } else if (hasRedOwn && hasWhiteOwn) {
      isRedPrimary = true;
    } else {
      // どちらもマッチしない場合、登録チーム名またはルールチーム名に近ければ自チームとして扱う
      final redTeam = TeamProgressHelper.extractTeamName(firstMatch.redName);
      final whiteTeam = TeamProgressHelper.extractTeamName(
        firstMatch.whiteName,
      );
      if (knownTeams.contains(whiteTeam)) {
        isRedPrimary = false;
      } else if (knownTeams.contains(redTeam)) {
        isRedPrimary = true;
      } else {
        isRedPrimary = true;
      }
    }

    final targetFullName = isRedPrimary
        ? firstMatch.redName
        : firstMatch.whiteName;
    final teamTitle = TeamProgressHelper.resolveSideTeamTitle(
      sideFullName: targetFullName,
      knownTeams: knownTeams,
      knownPlayers: knownPlayers,
      myDojoName: myDojoName,
      isIndividual: isIndiv,
    );

    // 対戦カード内のポジション別進行状況集計
    int completedCount = 0;
    int totalCount = cardMatches.length;
    int wins = 0;
    int losses = 0;
    int draws = 0;
    int points = 0;

    MatchModel? inProgress;
    MatchModel? lastFinished;
    MatchModel? nextWaiting;

    for (final m in cardMatches) {
      final isFinished = m.status == 'finished' || m.status == 'approved';
      final isLive = m.status == 'in_progress';
      final isWaiting = m.status == 'waiting' || m.status == 'ready';

      final myScore = isRedPrimary ? m.redScore : m.whiteScore;
      final oppScore = isRedPrimary ? m.whiteScore : m.redScore;

      points += myScore;

      if (isFinished) {
        completedCount++;
        lastFinished = m;
        if (myScore > oppScore) {
          wins++;
        } else if (oppScore > myScore) {
          losses++;
        } else {
          draws++;
        }
      } else if (isLive && inProgress == null) {
        inProgress = m;
      } else if (isWaiting && nextWaiting == null && inProgress == null) {
        nextWaiting = m;
      }
    }

    if (inProgress != null && nextWaiting == null) {
      nextWaiting = cardMatches.firstWhere(
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
        inProgress ?? nextWaiting ?? lastFinished ?? firstMatch;
    final categoryName =
        representativeMatch.category ?? representativeMatch.matchType;
    final currentCourtName = TeamProgressHelper.extractCourtAndRoundDisplay(
      representativeMatch,
    );
    final matchupTitle = TeamProgressHelper.extractTeamMatchupTitle(
      representativeMatch,
    );

    final targetGroupId =
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
        teamName: teamTitle,
        categoryName: categoryName,
        currentCourtName: currentCourtName,
        matchupTitle: matchupTitle,
        targetGroupId: targetGroupId,
        tournamentId: representativeMatch.tournamentId,
        matches: cardMatches,
        inProgressMatch: inProgress,
        lastFinishedMatch: lastFinished,
        nextWaitingMatch: nextWaiting,
        completedCount: completedCount,
        totalCount: totalCount,
        waitingMatchCount: waitingCount,
        totalWins: wins,
        totalLosses: losses,
        totalDraws: draws,
        totalPoints: points,
        hasLiveMatch: inProgress != null,
      ),
    );
  }

  // ソート: 試合中（LIVE）が最上位 → 待機中 → 終了
  results.sort((a, b) {
    if (a.hasLiveMatch != b.hasLiveMatch) {
      return a.hasLiveMatch ? -1 : 1;
    }
    if (a.isAllFinished != b.isAllFinished) {
      return a.isAllFinished ? 1 : -1;
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
