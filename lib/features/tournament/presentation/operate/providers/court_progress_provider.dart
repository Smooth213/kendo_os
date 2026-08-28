import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/domain/court_progress_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';

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

/// 試合データから対戦カード名（例: 道上剣友会 vs ◯◯道場）を抽出
String extractMatchupTitle(MatchModel match) {
  final isIndividual =
      match.matchType == '個人戦' ||
      match.matchType == '選手' ||
      match.matchType.contains('個人') ||
      (match.category != null && match.category!.contains('個人'));

  final rDisplay = formatPlayerOrTeamDisplay(
    match.redName,
    isIndividual: isIndividual,
  );
  final wDisplay = formatPlayerOrTeamDisplay(
    match.whiteName,
    isIndividual: isIndividual,
  );

  return '$rDisplay vs $wDisplay';
}

/// UUIDのような英数羅列かどうかを判定
bool isUuidLike(String str) {
  return RegExp(r'^[0-9a-fA-F-]{16,}$').hasMatch(str.trim());
}

/// 試合データからカード表示用タイトル（コート名または対戦カード名）を安全に抽出
String extractCourtOrMatchupName(MatchModel match) {
  // 1. note 内に明示的なコート名（第1試合場、Aコート等）があれば優先
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

  // 2. note 内に進行見出し（2回戦, Bリーグ 等）があれば利用（UUIDは除外）
  if (match.note.isNotEmpty) {
    final firstLine = match.note.split('\n').first.trim();
    if (firstLine.isNotEmpty && !isUuidLike(firstLine)) {
      return firstLine;
    }
  }

  // 3. category にコート名があれば利用
  if (match.category != null &&
      match.category!.isNotEmpty &&
      !isUuidLike(match.category!)) {
    return match.category!;
  }

  // 4. groupName が人間が読める文字列なら利用（UUIDは除外）
  if (match.groupName != null &&
      match.groupName!.isNotEmpty &&
      !isUuidLike(match.groupName!)) {
    return match.groupName!;
  }

  // 5. 英数ID(UUID)や未設定の場合は、対戦カード名（例: 道上剣友会 vs ◯◯道場）を返す！
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
  final dojoId = ref.watch(currentDojoIdProvider).trim().toLowerCase();

  return calculateCourtProgress(matches, myDojoName: dojoId);
});

/// 試合リストからコート進行ステータスを算出する純粋関数
List<CourtProgressStatus> calculateCourtProgress(
  List<MatchModel> matches, {
  String myDojoName = '',
}) {
  if (matches.isEmpty) return const [];

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

    bool hasMyDojo = false;
    if (myDojoName.isNotEmpty) {
      if (inProgress != null) {
        final rName = inProgress.redName.toLowerCase();
        final wName = inProgress.whiteName.toLowerCase();
        if (rName.contains(myDojoName) || wName.contains(myDojoName)) {
          hasMyDojo = true;
        }
      }
    }

    results.add(
      CourtProgressStatus(
        courtName: courtDisplayName,
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
