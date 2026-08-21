import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:kendo_os/features/match/application/mappers/score_event_legacy_adapter.dart';
import 'package:kendo_os/features/match/application/usecases/match_application_service.dart';
import 'package:kendo_os/features/match/application/usecases/match_usecases.dart';

import 'package:kendo_os/features/match/domain/match_aggregate.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/presentation/providers/match_rule_provider.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'match_list_provider.dart';

/// 試合スナップショット（バックアップ・復元・再構築）ヘルパー
class MatchSnapshotService {
  static Future<void> rebuildMatchSnapshot({
    required Ref ref,
    required String matchId,
  }) async {
    final match = ref
        .read(matchListProvider)
        .where((m) => m.id == matchId)
        .firstOrNull;
    if (match == null) return;

    final rule = ref.read(matchRuleProvider);
    final rebuiltMatch = ref
        .read(rebuildMatchFromEventsUseCaseProvider)
        .execute(match, rule);

    await ref.read(matchApplicationServiceProvider).saveMatch(rebuiltMatch);
  }

  static Future<MatchModel?> takeSnapshot({
    required Ref ref,
    required String matchId,
    required String reason,
  }) async {
    final match =
        await ref.read(localMatchRepositoryProvider).getMatch(matchId) ??
        ref.read(matchListProvider).where((m) => m.id == matchId).firstOrNull;
    if (match == null) return null;

    final snapshot = MatchSnapshot(
      id: const Uuid().v4(),
      matchId: match.id,
      version: match.events.length,
      state: match,
      createdAt: DateTime.now(),
      reason: reason,
      events: List.from(match.events),
    );

    final newSnapshots = [...match.snapshots, snapshot];
    if (newSnapshots.length > 20) {
      newSnapshots.removeRange(0, newSnapshots.length - 20);
    }

    final updatedMatch = match.copyWith(snapshots: newSnapshots);
    await ref.read(matchApplicationServiceProvider).saveMatch(updatedMatch);
    return updatedMatch;
  }

  static Future<void> restoreFromSnapshot({
    required Ref ref,
    required String matchId,
    required MatchSnapshot snapshot,
  }) async {
    final match = ref
        .read(matchListProvider)
        .where((m) => m.id == matchId)
        .firstOrNull;
    if (match == null) return;

    final restoreEvent = ScoreEventLegacyAdapter.fromLegacy(
      id: const Uuid().v4(),
      side: Side.none,
      type: PointType.restore,
      timestamp: DateTime.now(),
      userId: match.scorerId,
      sequence: match.events.isEmpty ? 1 : match.events.last.sequence + 1,
    );

    final newEvents = [...snapshot.events, restoreEvent];

    await ref
        .read(matchApplicationServiceProvider)
        .saveMatch(match.copyWith(events: newEvents));
    await rebuildMatchSnapshot(ref: ref, matchId: matchId);

    await takeSnapshot(
      ref: ref,
      matchId: matchId,
      reason: '【復元】${snapshot.reason} の時点',
    );
  }
}
