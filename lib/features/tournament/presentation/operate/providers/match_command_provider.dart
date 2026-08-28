import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/application/usecases/match_application_service.dart';
import 'package:kendo_os/features/match/domain/match_aggregate.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_command_queue.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_snapshot_service.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/match_repository.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';
import 'match_list_provider.dart';
import 'sync_provider.dart';

export 'match_command_queue.dart';

typedef SyncAction = MatchCommandModel;

final matchCommandServiceProvider = Provider<MatchCommandService>((ref) {
  return MatchCommandService(ref);
});

final matchCommandProvider = matchCommandServiceProvider;
typedef MatchCommand = MatchCommandService;

class MatchCommandService {
  final Ref ref;
  MatchCommandService(this.ref);

  DateTime? _lastScoreTime;
  String? _lastScoreKey;

  bool _isUndoing = false;
  DateTime? _lastUndoTime;

  Future<void> completeMatchWithHantei(
    MatchModel currentMatch,
    String hanteiResult,
    String? userId,
  ) async {
    try {
      if (hanteiResult == 'red' || hanteiResult == 'white') {
        final side = hanteiResult == 'red' ? Side.red : Side.white;
        await ref
            .read(matchApplicationServiceProvider)
            .finishMatchManually(currentMatch.id, hanteiWinner: side);
      } else if (hanteiResult == 'draw') {
        await ref
            .read(matchApplicationServiceProvider)
            .finishMatchManually(currentMatch.id);
      }
    } catch (e) {
      debugPrint('🔥 [Command Error] completeMatchWithHantei: $e');
      rethrow;
    }
  }

  Future<bool> claimScorer(String matchId, String userId) async {
    return await ref
        .read(matchApplicationServiceProvider)
        .claimScorer(matchId, userId);
  }

  Future<void> releaseScorer(String matchId, String userId) async {
    await ref
        .read(matchApplicationServiceProvider)
        .releaseScorer(matchId, userId);
  }

  Future<void> forceClaimScorer(String matchId, String userId) async {
    await ref
        .read(matchApplicationServiceProvider)
        .forceClaimScorer(matchId, userId);
  }

  Future<void> deleteMatch(String matchId) async {
    // ignore: invalid_use_of_visible_for_testing_member
    if (kIsWeb || debugIsWebOverride) {
      final currentMatches = ref.read(webCurrentTournamentMatchesProvider);

      final matchToDelete = currentMatches.firstWhere(
        (m) => m.id == matchId,
        orElse: () => const MatchModel(
          id: '',
          status: '',
          matchType: '',
          redName: '',
          whiteName: '',
        ),
      );
      if (matchToDelete.id.isNotEmpty) {
        if (matchToDelete.tournamentId != null &&
            matchToDelete.tournamentId!.isNotEmpty &&
            matchToDelete.tournamentId != 'default_tournament') {
          ref.read(currentTournamentIdProvider.notifier).state =
              matchToDelete.tournamentId!;
        }
        if (matchToDelete.organizationId.isNotEmpty &&
            matchToDelete.organizationId != 'default_org') {
          ref.read(currentDojoIdProvider.notifier).state =
              matchToDelete.organizationId;
        }
      }

      final updatedMatches = currentMatches
          .where((m) => m.id != matchId)
          .toList();
      ref.read(webCurrentTournamentMatchesProvider.notifier).state =
          updatedMatches;

      await ref.read(matchRepositoryProvider).deleteMatch(matchId);
    } else {
      await ref.read(localMatchRepositoryProvider).deleteMatch(matchId);
    }
  }

  Future<void> renameTeamBulk({
    required String tournamentId,
    required String oldTeamName,
    required String newTeamName,
  }) async {
    final allMatches = ref.read(matchListProvider);
    final targetMatches = allMatches
        .where((m) => m.tournamentId == tournamentId)
        .toList();

    List<MatchModel> updatedMatches = [];

    for (var m in targetMatches) {
      bool isChanged = false;
      String rName = m.redName;
      String wName = m.whiteName;

      if (rName.contains(':')) {
        final parts = rName.split(':');
        if (parts[0].trim() == oldTeamName) {
          rName = '$newTeamName : ${parts[1].trim()}';
          isChanged = true;
        }
      } else if (rName.trim() == oldTeamName) {
        rName = newTeamName;
        isChanged = true;
      }

      if (wName.contains(':')) {
        final parts = wName.split(':');
        if (parts[0].trim() == oldTeamName) {
          wName = '$newTeamName : ${parts[1].trim()}';
          isChanged = true;
        }
      } else if (wName.trim() == oldTeamName) {
        wName = newTeamName;
        isChanged = true;
      }

      if (isChanged) {
        updatedMatches.add(
          m.copyWith(
            redName: rName,
            whiteName: wName,
            syncState: SyncState.localOnly,
            lastUpdatedAt: DateTime.now(),
          ),
        );
      }
    }

    if (updatedMatches.isNotEmpty) {
      await ref
          .read(matchApplicationServiceProvider)
          .saveMatchesBulk(updatedMatches);
      debugPrint(
        '⚡ Team Renamed Bulk: $oldTeamName -> $newTeamName (${updatedMatches.length} matches)',
      );
    }
  }

  Future<void> addScoreEvent(String matchId, Side side, PointType type) async {
    final now = DateTime.now();
    final currentKey = '$matchId-$side-$type';

    if (_lastScoreTime != null &&
        now.difference(_lastScoreTime!) < const Duration(milliseconds: 500) &&
        _lastScoreKey == currentKey) {
      ref.read(matchCommandErrorProvider.notifier).state =
          '🛡️ 連打防止：${type.name}をブロックしました';
      return;
    }

    _lastScoreTime = now;
    _lastScoreKey = currentKey;

    if (ref.read(isMatchCommandProcessingProvider)) return;
    ref.read(isMatchCommandProcessingProvider.notifier).state = true;

    try {
      if (type == PointType.undo) {
        await ref.read(matchApplicationServiceProvider).undo(matchId);
      } else {
        await ref
            .read(matchApplicationServiceProvider)
            .addIppon(matchId, side, type);
      }
    } catch (e) {
      debugPrint('🔥 [Command Error] addScoreEvent: $e');
    } finally {
      ref.read(isMatchCommandProcessingProvider.notifier).state = false;
    }
  }

  Future<void> undoLastEvent(String matchId) async {
    debugPrint('🔙 [Undo Start] matchId=$matchId');
    final now = DateTime.now();

    if (_lastUndoTime != null &&
        now.difference(_lastUndoTime!) < const Duration(milliseconds: 300)) {
      ref.read(matchCommandErrorProvider.notifier).state =
          '🛡️ 履歴保護：過度な連続Undoをブロックしました';
      return;
    }
    _lastUndoTime = now;

    if (_isUndoing) return;
    if (ref.read(isMatchCommandProcessingProvider)) return;

    _isUndoing = true;
    ref.read(isMatchCommandProcessingProvider.notifier).state = true;

    try {
      await ref.read(matchApplicationServiceProvider).undo(matchId);
    } catch (e) {
      debugPrint('🔥 [Command Error] undoLastEvent: $e');
      ref.read(matchCommandErrorProvider.notifier).state = '履歴の取り消しに失敗しました: $e';
    } finally {
      _isUndoing = false;
      ref.read(isMatchCommandProcessingProvider.notifier).state = false;
    }
  }

  Future<void> addMatch(MatchModel newMatch) async {
    await ref.read(matchApplicationServiceProvider).saveMatch(newMatch);
  }

  /// 【Phase 2: 現場救済】試合の赤白（選手・スコア・反則・履歴）を即座に反転
  Future<void> swapRedAndWhite(String matchId) async {
    final match = _getMatch(matchId);
    if (match == null) return;
    final swapped = match.swapRedAndWhite();
    await ref.read(matchApplicationServiceProvider).saveMatch(swapped);
  }

  Future<void> bulkUpdateMatchRules({
    required List<String> targetMatchIds,
    required MatchRule newRule,
  }) async {
    if (targetMatchIds.isEmpty) return;

    ref.read(isMatchCommandProcessingProvider.notifier).state = true;
    ref.read(matchCommandErrorProvider.notifier).state = null;

    try {
      final appService = ref.read(matchApplicationServiceProvider);

      final List<MatchModel> updatedMatches = [];
      for (final matchId in targetMatchIds) {
        final match = _getMatch(matchId);
        if (match != null) {
          final existingRule = match.rule;
          final mergedRule = newRule.copyWith(
            teamName: (existingRule?.teamName.isNotEmpty == true)
                ? existingRule!.teamName
                : newRule.teamName,
            category: (existingRule?.category.isNotEmpty == true)
                ? existingRule!.category
                : newRule.category,
          );
          final updatedMatch = match.copyWith(
            matchTimeMinutes: mergedRule.matchTimeMinutes,
            hasExtension:
                mergedRule.enchoTimeMinutes > 0 || mergedRule.isEnchoUnlimited,
            extensionTimeMinutes: mergedRule.enchoTimeMinutes,
            hasHantei: mergedRule.hasHantei,
            rule: mergedRule,
          );
          updatedMatches.add(updatedMatch);
        }
      }

      if (updatedMatches.isNotEmpty) {
        await appService.saveMatchesBulk(updatedMatches);
        ref.read(syncEngineProvider).syncNow();
      }
    } catch (e) {
      debugPrint('🔥 [Command Error] bulkUpdateMatchRules: $e');
      ref.read(matchCommandErrorProvider.notifier).state =
          'ルールの表示・一括更新に失敗しました: $e';
      rethrow;
    } finally {
      ref.read(isMatchCommandProcessingProvider.notifier).state = false;
    }
  }

  Future<void> rebuildMatchSnapshot(String matchId) async {
    await MatchSnapshotService.rebuildMatchSnapshot(ref: ref, matchId: matchId);
  }

  Future<MatchModel?> takeSnapshot(String matchId, String reason) async {
    return await MatchSnapshotService.takeSnapshot(
      ref: ref,
      matchId: matchId,
      reason: reason,
    );
  }

  Future<void> restoreFromSnapshot(
    String matchId,
    MatchSnapshot snapshot,
  ) async {
    await MatchSnapshotService.restoreFromSnapshot(
      ref: ref,
      matchId: matchId,
      snapshot: snapshot,
    );
  }

  MatchModel? _getMatch(String id) {
    return ref.read(matchListProvider).where((m) => m.id == id).firstOrNull;
  }
}
