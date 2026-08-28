import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/domain/court_progress_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/safe_timeline_provider.dart';
import 'package:kendo_os/shared/infrastructure/repository/team_repository.dart';

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
    // 団体戦の場合は所属チーム名
    return team.isNotEmpty ? team : player;
  }
}

/// 試合データから対戦カード名（例: 【錬成】団体戦：〇〇剣友会 vs ◯◯道場）を抽出
String extractMatchupTitle(MatchModel match) {
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

/// UUIDやシステムIDのような英数羅列かどうかを判定
bool isIdOrUuidLike(String str) {
  final trimmed = str.trim();
  if (trimmed.isEmpty) return true;
  if (trimmed == '__default__' || trimmed == 'default_org') return true;

  // 1. 一般的なUUID / システムID（英数記号10文字以上で空白なし）
  if (RegExp(r'^[a-zA-Z0-9_-]{10,}$').hasMatch(trimmed)) return true;
  if (trimmed.startsWith('group_') ||
      trimmed.startsWith('match_') ||
      trimmed.startsWith('tourney_') ||
      trimmed.startsWith('dev-')) {
    return true;
  }

  // 2. 日本語（漢字・ひらがな・カタカナ）が含まれていれば人間用見出し
  if (RegExp(r'[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FFF]').hasMatch(trimmed)) {
    return false;
  }

  // 3. 空白を含まない純粋な英数文字列はIDと判定
  if (!trimmed.contains(' ') &&
      !trimmed.contains('　') &&
      RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(trimmed)) {
    return true;
  }

  return false;
}

/// カテゴリ・部門名を抽出（1段目用）
String extractCategoryName(MatchModel match) {
  // 1. 最優先: match.category（例: 小学生の部、中学生男子）
  if (match.category != null &&
      match.category!.trim().isNotEmpty &&
      !isIdOrUuidLike(match.category!)) {
    return match.category!.trim();
  }

  // 2. note 内に明示的なコート名（例: 第1試合場、Aコート）があれば採用
  if (match.note.isNotEmpty) {
    for (final line in match.note.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.contains('試合場') ||
          trimmed.contains('コート') ||
          RegExp(r'^[A-Z]コート').hasMatch(trimmed) ||
          RegExp(r'^第[0-9]+').hasMatch(trimmed)) {
        return trimmed;
      }
    }
  }

  // 3. groupName が人間用見出し文字列なら採用
  if (match.groupName != null &&
      match.groupName!.isNotEmpty &&
      !isIdOrUuidLike(match.groupName!)) {
    return match.groupName!;
  }

  return '一般部門';
}

/// 試合詳細メモ（3段目用）を抽出（アナウンスやID文字列は完全除外）
String extractDetailNote(MatchModel match, String categoryName) {
  if (match.note.isEmpty) return '';

  final lines = match.note.split('\n').map((l) => l.trim()).where((line) {
    if (line.isEmpty) return false;
    if (line == categoryName) return false;
    if (isIdOrUuidLike(line)) return false;

    // アナウンス・お知らせ・緊急連絡等の通知文字列は除外
    final lower = line.toLowerCase();
    if (lower.contains('アナウンス') ||
        lower.contains('お知らせ') ||
        lower.contains('連絡') ||
        lower.startsWith('【本部') ||
        lower.startsWith('【緊急') ||
        lower.startsWith('【通知')) {
      return false;
    }

    return true;
  }).toList();

  if (lines.isEmpty) return '';
  return lines.join(' / ');
}

/// 試合データからカード表示用タイトル（コート名または対戦カード名）を安全に抽出
String extractCourtOrMatchupName(MatchModel match) {
  final cat = extractCategoryName(match);
  if (cat != '一般部門') return cat;
  return extractMatchupTitle(match);
}

/// グループ化用の内部キーを取得
String getGroupKey(MatchModel match) {
  if (match.groupName != null && match.groupName!.isNotEmpty) {
    return match.groupName!;
  }
  if (match.note.isNotEmpty) {
    final firstLine = match.note.split('\n').first.trim();
    if (firstLine.isNotEmpty) return firstLine;
  }
  return match.id;
}

/// 試合が「進行中（LIVE）」かどうかを厳密に判定
bool isMatchInProgress(MatchModel match) {
  if (match.status == 'finished' || match.status == 'approved') {
    return false;
  }
  if (match.status == 'in_progress') {
    return true;
  }
  if (match.timerStartedAt != null && match.timerPausedAt == null) {
    return true;
  }
  if (match.events.any((e) => !e.isCanceled)) {
    return true;
  }
  return false;
}

/// 全コートの進行ステータスリストを提供するプロバイダー
final courtProgressListProvider = Provider<List<CourtProgressStatus>>((ref) {
  final matches = ref.watch(matchListProvider);
  final ownTeams = ref.watch(customTeamNamesProvider).value ?? [];
  final players = ref.watch(timelinePlayerListProvider).value ?? [];
  final dojoName = ref.watch(currentDojoNameProvider).value?.trim() ?? '';

  final myTeamNames = <String>{
    ...ownTeams.map((t) => t.trim().toLowerCase()).where((t) => t.isNotEmpty),
    if (dojoName.isNotEmpty) dojoName.toLowerCase(),
  };

  final myPlayerNames = <String>{
    ...players
        .map((p) => p.name.trim().toLowerCase())
        .where((p) => p.isNotEmpty),
  };

  // 大会登録チーム＆選手も網羅
  if (matches.isNotEmpty) {
    final tId = matches.first.tournamentId;
    if (tId != null && tId.isNotEmpty) {
      final teams = ref.watch(registeredTeamsProvider(tId)).value ?? [];
      for (final t in teams) {
        final tName = t.teamName.trim();
        if (tName.isNotEmpty) myTeamNames.add(tName.toLowerCase());
        for (final p in t.playerNames) {
          final pName = p.trim();
          if (pName.isNotEmpty) myPlayerNames.add(pName.toLowerCase());
        }
      }
    }
  }

  return calculateCourtProgress(
    matches,
    myTeamNames: myTeamNames,
    myPlayerNames: myPlayerNames,
  );
});

/// 試合が自道場・自チーム（合同チーム・所属選手含む）の対戦かを厳密に判定
bool isMatchOfMyDojo(
  MatchModel match, {
  required Set<String> myTeamNames,
  required Set<String> myPlayerNames,
}) {
  final ruleTeam = match.rule?.teamName.trim().toLowerCase();
  if (ruleTeam != null &&
      ruleTeam.isNotEmpty &&
      myTeamNames.contains(ruleTeam)) {
    return true;
  }

  for (final raw in [match.redName, match.whiteName]) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) continue;
    if (trimmed.contains('自チーム')) return true;

    String teamPart = '';
    String playerPart = '';
    if (trimmed.contains(':')) {
      final parts = trimmed.split(':');
      teamPart = parts.first.trim().toLowerCase();
      playerPart = parts.last.trim().toLowerCase();
    } else {
      teamPart = trimmed.toLowerCase();
      playerPart = trimmed.toLowerCase();
    }

    // 1. チーム名が登録チーム/自チームリストに完全一致
    if (teamPart.isNotEmpty && myTeamNames.contains(teamPart)) return true;

    // 2. 選手名が道場生名簿または登録選手に一致（合同チームでも所属選手で拾い上げ！）
    if (playerPart.isNotEmpty) {
      final normalizedPlayer = playerPart.replaceAll(RegExp(r'\s+'), '');
      for (final p in myPlayerNames) {
        final normP = p.replaceAll(RegExp(r'\s+'), '');
        if (normP == normalizedPlayer ||
            normalizedPlayer.contains(normP) ||
            normP.contains(normalizedPlayer)) {
          return true;
        }
      }
    }

    // 3. 部分一致（例: 「〇〇剣友会A」が「〇〇剣友会」を含む）
    for (final own in myTeamNames) {
      if (own.length >= 2 &&
          (teamPart.contains(own) || own.contains(teamPart))) {
        return true;
      }
    }
  }

  return false;
}

/// 試合リストからコート進行ステータスを算出する純粋関数
List<CourtProgressStatus> calculateCourtProgress(
  List<MatchModel> matches, {
  String myDojoName = '',
  Set<String> myTeamNames = const {},
  Set<String> myPlayerNames = const {},
}) {
  if (matches.isEmpty) return const [];

  final allTeamNames = <String>{
    if (myDojoName.isNotEmpty) myDojoName.toLowerCase(),
    ...myTeamNames.map((k) => k.toLowerCase()),
  };
  final allPlayerNames = <String>{...myPlayerNames.map((k) => k.toLowerCase())};

  // キーワードが一切取得できない場合のみ最頻出チームをフォールバック
  if (allTeamNames.isEmpty && allPlayerNames.isEmpty) {
    final frequencyMap = <String, int>{};
    for (final m in matches) {
      for (final name in [m.redName, m.whiteName]) {
        if (name.contains(':')) {
          final team = name.split(':').first.trim().toLowerCase();
          if (team.isNotEmpty) {
            frequencyMap[team] = (frequencyMap[team] ?? 0) + 1;
          }
        }
      }
    }
    if (frequencyMap.isNotEmpty) {
      final mostFrequentTeam = frequencyMap.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      allTeamNames.add(mostFrequentTeam);
    }
  }

  final Map<String, List<MatchModel>> groupMap = {};

  for (final match in matches) {
    final key = getGroupKey(match);
    groupMap.putIfAbsent(key, () => []).add(match);
  }

  final List<CourtProgressStatus> results = [];

  for (final entry in groupMap.entries) {
    final courtMatches = List<MatchModel>.from(entry.value)
      ..sort((a, b) => a.order.compareTo(b.order));

    final firstMatch = courtMatches.first;
    final categoryName = extractCategoryName(firstMatch);
    final matchupTitle = extractMatchupTitle(firstMatch);
    final detailNote = extractDetailNote(firstMatch, categoryName);
    final courtDisplayName = extractCourtOrMatchupName(firstMatch);

    int completed = 0;
    MatchModel? inProgress;
    MatchModel? lastFinished;
    MatchModel? nextWaiting;

    for (final m in courtMatches) {
      final isDone = m.status == 'finished' || m.status == 'approved';
      if (isDone) {
        completed++;
        lastFinished = m;
      } else if (inProgress == null && isMatchInProgress(m)) {
        inProgress = m;
      } else if (nextWaiting == null && !isDone) {
        nextWaiting = m;
      }
    }

    final hasLive = inProgress != null;

    // 自道場が出場しているか（全試合を対象に厳密判定！）
    final bool hasMyDojo = courtMatches.any(
      (m) => isMatchOfMyDojo(
        m,
        myTeamNames: allTeamNames,
        myPlayerNames: allPlayerNames,
      ),
    );

    results.add(
      CourtProgressStatus(
        courtName: courtDisplayName,
        categoryName: categoryName,
        matchupTitle: matchupTitle,
        detailNote: detailNote,
        matches: courtMatches,
        inProgressMatch: inProgress,
        lastFinishedMatch: lastFinished,
        nextWaitingMatch: nextWaiting,
        completedCount: completed,
        totalCount: courtMatches.length,
        hasLiveMatch: hasLive,
        hasMyDojoMatch: hasMyDojo,
      ),
    );
  }

  // コート名順にソート
  results.sort((a, b) => a.courtName.compareTo(b.courtName));
  return results;
}
