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

  // 2. 各対戦カードの解析用中間モデル
  final List<_CardAnalysis> analyzedCards = [];

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

    MatchModel? inProgress;
    MatchModel? lastFinished;
    MatchModel? nextWaiting;

    int myMatchWins = 0;
    int oppMatchWins = 0;
    int myCardPoints = 0;
    int oppCardPoints = 0;

    for (final m in cardMatches) {
      final isFinished = m.status == 'finished' || m.status == 'approved';
      final isLive = m.status == 'in_progress';
      final isWaiting = m.status == 'waiting' || m.status == 'ready';

      final myScore = isRedPrimary ? m.redScore : m.whiteScore;
      final oppScore = isRedPrimary ? m.whiteScore : m.redScore;

      myCardPoints += myScore;
      oppCardPoints += oppScore;

      if (isFinished) {
        lastFinished = m;
        if (myScore > oppScore) {
          myMatchWins++;
        } else if (oppScore > myScore) {
          oppMatchWins++;
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

    final isCardCompleted = cardMatches.every(
      (m) => m.status == 'finished' || m.status == 'approved',
    );

    analyzedCards.add(
      _CardAnalysis(
        teamTitle: teamTitle,
        categoryName: categoryName,
        currentCourtName: currentCourtName,
        matchupTitle: matchupTitle,
        targetGroupId: targetGroupId,
        tournamentId: representativeMatch.tournamentId,
        cardMatches: cardMatches,
        inProgressMatch: inProgress,
        lastFinishedMatch: lastFinished,
        nextWaitingMatch: nextWaiting,
        isCardCompleted: isCardCompleted,
        isIndividual: isIndiv,
        myMatchWins: myMatchWins,
        oppMatchWins: oppMatchWins,
        myPoints: myCardPoints,
        oppPoints: oppCardPoints,
      ),
    );
  }

  // 3. 同一チーム・同一カテゴリ（teamKey）ごとに本日の全対戦数と通算成績（団体戦1勝=1）を集計
  final Map<String, _TeamDailyStats> dailyStatsMap = {};
  for (final card in analyzedCards) {
    final teamKey = '${card.teamTitle}::${card.categoryName}';
    final stats = dailyStatsMap.putIfAbsent(teamKey, () => _TeamDailyStats());
    stats.totalCards++;

    if (card.isCardCompleted) {
      stats.completedCards++;
      if (card.isIndividual) {
        // 個人戦: その試合のスコア判定
        if (card.myPoints > card.oppPoints) {
          stats.totalWins++;
        } else if (card.oppPoints > card.myPoints) {
          stats.totalLosses++;
        } else {
          stats.totalDraws++;
        }
      } else {
        // 団体戦: チーム勝敗判定（勝者本数または勝星数）
        if (card.myMatchWins > card.oppMatchWins ||
            (card.myMatchWins == card.oppMatchWins &&
                card.myPoints > card.oppPoints)) {
          stats.totalWins++;
        } else if (card.oppMatchWins > card.myMatchWins ||
            (card.myMatchWins == card.oppMatchWins &&
                card.oppPoints > card.myPoints)) {
          stats.totalLosses++;
        } else {
          stats.totalDraws++;
        }
      }
    }
    stats.totalPoints += card.myPoints;
  }

  // 4. 各対戦カードの TeamProgressStatus を生成
  final List<TeamProgressStatus> results = [];

  for (final card in analyzedCards) {
    final teamKey = '${card.teamTitle}::${card.categoryName}';
    final stats = dailyStatsMap[teamKey] ?? _TeamDailyStats();

    int waitingCount = 0;
    if (card.nextWaitingMatch != null && card.inProgressMatch == null) {
      waitingCount = 1;
    }

    results.add(
      TeamProgressStatus(
        teamName: card.teamTitle,
        categoryName: card.categoryName,
        currentCourtName: card.currentCourtName,
        matchupTitle: card.matchupTitle,
        targetGroupId: card.targetGroupId,
        tournamentId: card.tournamentId,
        matches: card.cardMatches,
        inProgressMatch: card.inProgressMatch,
        lastFinishedMatch: card.lastFinishedMatch,
        nextWaitingMatch: card.nextWaitingMatch,
        completedCount: stats.completedCards,
        totalCount: stats.totalCards,
        waitingMatchCount: waitingCount,
        totalWins: stats.totalWins,
        totalLosses: stats.totalLosses,
        totalDraws: stats.totalDraws,
        totalPoints: stats.totalPoints,
        hasLiveMatch: card.inProgressMatch != null,
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

class _CardAnalysis {
  final String teamTitle;
  final String categoryName;
  final String currentCourtName;
  final String matchupTitle;
  final String? targetGroupId;
  final String? tournamentId;
  final List<MatchModel> cardMatches;
  final MatchModel? inProgressMatch;
  final MatchModel? lastFinishedMatch;
  final MatchModel? nextWaitingMatch;
  final bool isCardCompleted;
  final bool isIndividual;
  final int myMatchWins;
  final int oppMatchWins;
  final int myPoints;
  final int oppPoints;

  const _CardAnalysis({
    required this.teamTitle,
    required this.categoryName,
    required this.currentCourtName,
    required this.matchupTitle,
    this.targetGroupId,
    this.tournamentId,
    required this.cardMatches,
    this.inProgressMatch,
    this.lastFinishedMatch,
    this.nextWaitingMatch,
    required this.isCardCompleted,
    required this.isIndividual,
    required this.myMatchWins,
    required this.oppMatchWins,
    required this.myPoints,
    required this.oppPoints,
  });
}

class _TeamDailyStats {
  int totalCards = 0;
  int completedCards = 0;
  int totalWins = 0;
  int totalLosses = 0;
  int totalDraws = 0;
  int totalPoints = 0;
}
