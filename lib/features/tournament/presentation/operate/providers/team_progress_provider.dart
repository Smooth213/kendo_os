import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/domain/team_progress_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/safe_timeline_provider.dart';

/// 選手名またはチーム名から純粋なチーム名を抽出
String extractTeamName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '自チーム';
  if (trimmed.contains(':')) {
    return trimmed.split(':').first.trim();
  }
  return trimmed;
}

/// 選手名またはチーム名から純粋な選手名を抽出
String extractPlayerName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '';
  if (trimmed.contains(':')) {
    return trimmed.split(':').last.trim();
  }
  return trimmed;
}

/// 選手名またはチーム名を分かりやすくフォーマットするヘルパー
String formatPlayerOrTeamDisplay(String name, {required bool isIndividual}) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '選手未定';

  if (!trimmed.contains(':')) {
    return trimmed;
  }

  final parts = trimmed.split(':');
  final team = parts[0].trim();
  final player = parts.length > 1 ? parts[1].trim() : '';

  if (isIndividual) {
    if (player.isNotEmpty) {
      return '$player（$team）';
    }
    return team;
  } else {
    return team.isNotEmpty ? team : player;
  }
}

/// 試合データから対戦カード名（例: 【錬成】団体戦：〇〇 vs ◯◯）を抽出
String extractTeamMatchupTitle(MatchModel match) {
  final isIndividual =
      match.matchType == '個人戦' ||
      match.matchType == '選手' ||
      match.matchType.contains('個人') ||
      (match.category != null && match.category!.contains('個人'));

  final isRensei =
      match.matchType == '錬成会' ||
      match.matchType.contains('錬成') ||
      match.note.contains('錬成') ||
      (match.category != null && match.category!.contains('錬成'));

  final isMoushiawase =
      match.matchType.contains('申し合わせ') ||
      match.matchType.contains('申合せ') ||
      match.note.contains('申し合わせ') ||
      match.note.contains('申合せ') ||
      (match.category != null &&
          (match.category!.contains('申し合わせ') ||
              match.category!.contains('申合せ')));

  String prefix = '';
  if (isRensei) {
    prefix = '【錬成】';
  } else if (isMoushiawase) {
    prefix = '【申合せ】';
  }

  final typeLabel = isIndividual ? '個人戦：' : '団体戦：';

  final rDisplay = formatPlayerOrTeamDisplay(
    match.redName,
    isIndividual: isIndividual,
  );
  final wDisplay = formatPlayerOrTeamDisplay(
    match.whiteName,
    isIndividual: isIndividual,
  );

  final matchup = '$rDisplay vs $wDisplay';

  if (prefix.isNotEmpty) {
    return '$prefix$typeLabel$matchup';
  }
  return '$typeLabel$matchup';
}

/// 試合データから「第2コート (1回戦・第4試合)」のようなコート・ラウンド・試合順の表示文字列を抽出
String extractCourtAndRoundDisplay(MatchModel match) {
  final note = match.note.trim();
  final category = match.category ?? '';
  final group = match.groupName ?? '';
  final combinedText = '$note, $category, $group';

  // 1. コート・試合場
  String? court;
  final courtMatch = RegExp(
    r'(第?\s*\d+\s*(?:コート|試合場|場)|[A-Za-z]\s*(?:コート|試合場)|部内戦コート|メインコート|サブコート)',
  ).firstMatch(combinedText);
  if (courtMatch != null) {
    court = courtMatch.group(1)!.replaceAll(' ', '');
  }

  // 2. 回戦・ラウンド
  String? round;
  final roundMatch = RegExp(
    r'(\d+回戦|準々決勝|準決勝|決勝戦|決勝|予選リーグ|[A-Za-z]リーグ|[A-Za-z]ブロック|\d+ブロック)',
  ).firstMatch(combinedText);
  if (roundMatch != null) {
    round = roundMatch.group(1)!.replaceAll(' ', '');
  }

  // 3. 試合順（何試合目）
  String? matchOrder;
  final orderMatch = RegExp(
    r'(?:第\s*(\d+)\s*試合(?!場)|(\d+)\s*試合目)',
  ).firstMatch(combinedText);
  if (orderMatch != null) {
    final num = orderMatch.group(1) ?? orderMatch.group(2);
    if (num != null) {
      matchOrder = '第$num試合';
    }
  }

  // サブ情報の結合（例: 1回戦・第4試合）
  final subInfoParts = <String>[?round, ?matchOrder];

  final subInfo = subInfoParts.isNotEmpty ? ' (${subInfoParts.join('・')})' : '';

  if (court != null) {
    return '$court$subInfo';
  } else if (subInfoParts.isNotEmpty) {
    return 'コート未指定$subInfo';
  }

  return 'コート未指定';
}

/// 赤または白が「自チーム側」かどうかを判定する高精度リゾルバー
bool isSideOwn({
  required String sideFullName,
  required Set<String> knownTeams,
  required Set<String> knownPlayers,
  required String myDojoName,
  String? ruleTeamName,
}) {
  final sideTeam = extractTeamName(sideFullName);
  final sidePlayer = extractPlayerName(sideFullName);

  // 1. 登録チーム名と完全一致
  if (knownTeams.contains(sideTeam)) return true;

  // 2. ルールで設定された自チーム名と一致
  if (ruleTeamName != null && ruleTeamName.trim().isNotEmpty) {
    final cleanRule = ruleTeamName.trim();
    if (sideTeam == cleanRule || sideFullName.contains(cleanRule)) {
      return true;
    }
  }

  // 3. 道場名を含む
  if (myDojoName.isNotEmpty) {
    if (sideTeam.contains(myDojoName) || sideFullName.contains(myDojoName)) {
      return true;
    }
  }

  // 4. 登録選手名（久安 智也など）が一致
  if (sidePlayer.isNotEmpty && knownPlayers.contains(sidePlayer)) return true;
  if (knownPlayers.isNotEmpty &&
      knownPlayers.any((p) => sideFullName.contains(p))) {
    return true;
  }

  return false;
}

/// チームごとの進行状況を計算するエンジン（団体戦1対戦カード＝1試合カウント）
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
    final isRedOwn = isSideOwn(
      sideFullName: match.redName,
      knownTeams: knownTeams,
      knownPlayers: knownPlayers,
      myDojoName: myDojoName,
      ruleTeamName: match.rule?.teamName,
    );
    final isWhiteOwn = isSideOwn(
      sideFullName: match.whiteName,
      knownTeams: knownTeams,
      knownPlayers: knownPlayers,
      myDojoName: myDojoName,
      ruleTeamName: match.rule?.teamName,
    );

    final redTeam = extractTeamName(match.redName);
    final whiteTeam = extractTeamName(match.whiteName);

    if (isRedOwn && !isWhiteOwn) {
      teamMatchesMap.putIfAbsent(redTeam, () => []).add(match);
    } else if (isWhiteOwn && !isRedOwn) {
      teamMatchesMap.putIfAbsent(whiteTeam, () => []).add(match);
    } else if (isRedOwn && isWhiteOwn) {
      // 部内戦などの場合は両方に登録
      teamMatchesMap.putIfAbsent(redTeam, () => []).add(match);
      if (whiteTeam != redTeam) {
        teamMatchesMap.putIfAbsent(whiteTeam, () => []).add(match);
      }
    } else {
      // どちらもマッチしない場合、ルールチーム名または赤側チーム
      final fallbackTeam = (match.rule?.teamName.isNotEmpty == true)
          ? match.rule!.teamName
          : (redTeam.isNotEmpty ? redTeam : (match.groupName ?? '自チーム'));
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
        final redTeam = extractTeamName(m.redName);
        final isRedMyTeam =
            redTeam == teamName ||
            isSideOwn(
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
    final currentCourtName = extractCourtAndRoundDisplay(representativeMatch);
    final matchupTitle = extractTeamMatchupTitle(representativeMatch);

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
