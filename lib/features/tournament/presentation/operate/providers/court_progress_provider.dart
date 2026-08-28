import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/domain/court_progress_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';

/// 試合データからコート名を安全に抽出するヘルパー
String extractCourtName(MatchModel match) {
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
  if (match.category != null && match.category!.contains('コート')) {
    return match.category!;
  }
  if (match.groupName != null && match.groupName!.isNotEmpty) {
    return match.groupName!;
  }
  return 'メイン試合場';
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

  final Map<String, List<MatchModel>> courtMap = {};

  for (final match in matches) {
    final court = extractCourtName(match);
    courtMap.putIfAbsent(court, () => []).add(match);
  }

  final List<CourtProgressStatus> results = [];

  for (final entry in courtMap.entries) {
    final courtName = entry.key;
    final courtMatches = List<MatchModel>.from(entry.value)
      ..sort((a, b) => a.order.compareTo(b.order));

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
        courtName: courtName,
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
