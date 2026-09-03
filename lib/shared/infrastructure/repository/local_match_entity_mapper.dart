import 'dart:convert';
import 'package:kendo_os/features/match/application/mappers/score_event_legacy_adapter.dart';
import 'package:kendo_os/features/match/domain/match_aggregate.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/shared/infrastructure/persistence/models/match_entity.dart';

/// Isar の [MatchEntity] とドメイン層の [MatchModel] の相互変換ヘルパー
class LocalMatchEntityMapper {
  const LocalMatchEntityMapper._();

  static ScoreEventEntity eventToEntity(ScoreEvent e) {
    return ScoreEventEntity()
      ..id = e.id
      ..side = e.side
      ..type = e.type
      ..timestamp = e.timestamp
      ..userId = e.userId
      ..sequence = e.sequence
      ..isCanceled = e.isCanceled
      ..isUndo = e.isUndo
      ..isRestore = e.isRestore
      ..deviceId = e.deviceId
      ..logicalClock = e.logicalClock
      ..signature = e.signature;
  }

  static MatchEntity toEntity(MatchModel model) {
    return MatchEntity()
      ..firestoreId = model.id
      ..matchType = model.matchType
      ..redName = model.redName
      ..whiteName = model.whiteName
      ..redScore = model.redScore
      ..whiteScore = model.whiteScore
      ..status = model.status
      ..events = model.events.map<ScoreEventEntity>(eventToEntity).toList()
      ..snapshots = model.snapshots
          .map(
            (s) => MatchSnapshotEntity()
              ..id = s.id
              ..createdAt = s.createdAt
              ..reason = s.reason
              ..events = s.events.map<ScoreEventEntity>(eventToEntity).toList(),
          )
          .toList()
      ..syncState = model.syncState
      ..pendingEvents = model.pendingEvents
          .map<ScoreEventEntity>(eventToEntity)
          .toList()
      ..lastUpdatedAt = model.lastUpdatedAt
      ..refereeNames = model.refereeNames
      ..countForStandings = model.countForStandings
      ..scorerId = model.scorerId
      ..version = model.version
      ..isAutoAssigned = model.isAutoAssigned
      ..order = model.order
      ..source = model.source
      ..tournamentId = model.tournamentId
      ..category = model.category
      ..groupName = model.groupName
      ..matchOrder = model.matchOrder
      ..matchTimeMinutes = model.matchTimeMinutes
      ..isRunningTime = model.isRunningTime
      ..hasExtension = model.hasExtension
      ..extensionTimeMinutes = model.extensionTimeMinutes
      ..extensionCount = model.extensionCount
      ..hasHantei = model.hasHantei
      ..timerStartedAt = model.timerStartedAt
      ..timerPausedAt = model.timerPausedAt
      ..accumulatedPauseDurationMs = model.accumulatedPauseDurationMs
      ..note = model.note
      ..isKachinuki = model.isKachinuki
      ..ruleJson = model.rule != null ? jsonEncode(model.rule!.toJson()) : null
      ..redRemaining = model.redRemaining
      ..whiteRemaining = model.whiteRemaining;
  }

  static ScoreEvent entityToEvent(ScoreEventEntity e) {
    return ScoreEventLegacyAdapter.fromLegacy(
      id: e.id ?? '',
      side: e.side,
      type: e.type,
      timestamp: e.timestamp ?? DateTime.now(),
      userId: e.userId,
      sequence: e.sequence,
      isCanceled: e.isCanceled,
    ).copyWith(
      isUndo: e.isUndo,
      isRestore: e.isRestore,
      deviceId: e.deviceId,
      logicalClock: e.logicalClock,
      signature: e.signature,
    );
  }

  static MatchModel toModel(MatchEntity entity) {
    return MatchModel(
      id: entity.firestoreId,
      matchType: entity.matchType,
      redName: entity.redName,
      whiteName: entity.whiteName,
      redScore: entity.redScore,
      whiteScore: entity.whiteScore,
      status: entity.status,
      syncState: entity.syncState,
      pendingEvents: entity.pendingEvents.map(entityToEvent).toList(),
      events: entity.events.map(entityToEvent).toList(),
      snapshots: entity.snapshots
          .map(
            (s) => MatchSnapshot(
              id: s.id ?? '',
              matchId: entity.firestoreId,
              version: s.events.length,
              state: MatchModel(
                id: entity.firestoreId,
                matchType: entity.matchType,
                redName: entity.redName,
                whiteName: entity.whiteName,
              ),
              createdAt: s.createdAt ?? DateTime.now(),
              reason: s.reason ?? '',
              events: s.events.map(entityToEvent).toList(),
            ),
          )
          .toList(),
      lastUpdatedAt: entity.lastUpdatedAt,
      refereeNames: entity.refereeNames,
      countForStandings: entity.countForStandings,
      scorerId: entity.scorerId,
      version: entity.version,
      isAutoAssigned: entity.isAutoAssigned,
      order: entity.order,
      source: entity.source,
      tournamentId: entity.tournamentId,
      category: entity.category,
      groupName: entity.groupName,
      matchOrder: entity.matchOrder,
      matchTimeMinutes: entity.matchTimeMinutes,
      isRunningTime: entity.isRunningTime,
      hasExtension: entity.hasExtension,
      extensionTimeMinutes: entity.extensionTimeMinutes,
      extensionCount: entity.extensionCount,
      hasHantei: entity.hasHantei,
      timerStartedAt: entity.timerStartedAt,
      timerPausedAt: entity.timerPausedAt,
      accumulatedPauseDurationMs: (entity.accumulatedPauseDurationMs < 0)
          ? 0
          : entity.accumulatedPauseDurationMs,
      note: entity.note,
      isKachinuki: entity.isKachinuki,
      rule: entity.ruleJson != null
          ? MatchRule.fromJson(
              jsonDecode(entity.ruleJson!) as Map<String, dynamic>,
            )
          : null,
      redRemaining: entity.redRemaining,
      whiteRemaining: entity.whiteRemaining,
    );
  }
}
