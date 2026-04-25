// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MatchSnapshot _$MatchSnapshotFromJson(Map<String, dynamic> json) =>
    _MatchSnapshot(
      id: json['id'] as String,
      createdAt: const TimestampConverter().fromJson(json['createdAt']),
      reason: json['reason'] as String,
      events:
          (json['events'] as List<dynamic>?)
              ?.map((e) => ScoreEvent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$MatchSnapshotToJson(_MatchSnapshot instance) =>
    <String, dynamic>{
      'id': instance.id,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
      'reason': instance.reason,
      'events': instance.events.map((e) => e.toJson()).toList(),
    };

_MatchModel _$MatchModelFromJson(Map<String, dynamic> json) => _MatchModel(
  id: json['id'] as String,
  matchType: json['matchType'] as String,
  redName: json['redName'] as String,
  whiteName: json['whiteName'] as String,
  redScore: (json['redScore'] as num?)?.toInt() ?? 0,
  whiteScore: (json['whiteScore'] as num?)?.toInt() ?? 0,
  status: json['status'] as String? ?? 'waiting',
  events:
      (json['events'] as List<dynamic>?)
          ?.map((e) => ScoreEvent.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  snapshots:
      (json['snapshots'] as List<dynamic>?)
          ?.map((e) => MatchSnapshot.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  isDirty: json['isDirty'] as bool? ?? false,
  lastUpdatedAt: const TimestampConverter().fromJson(json['lastUpdatedAt']),
  refereeNames:
      (json['refereeNames'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  countForStandings: json['countForStandings'] as bool? ?? true,
  scorerId: json['scorerId'] as String?,
  lockExpiresAt: const TimestampConverter().fromJson(json['lockExpiresAt']),
  version: (json['version'] as num?)?.toInt() ?? 1,
  isAutoAssigned: json['isAutoAssigned'] as bool? ?? false,
  order: json['order'] == null
      ? 0.0
      : const DoubleConverter().fromJson(json['order']),
  source: json['source'] as String? ?? 'manual',
  tournamentId: json['tournamentId'] as String?,
  category: json['category'] as String?,
  groupName: json['groupName'] as String?,
  matchOrder: (json['matchOrder'] as num?)?.toInt(),
  matchTimeMinutes: (json['matchTimeMinutes'] as num?)?.toInt() ?? 3,
  isRunningTime: json['isRunningTime'] as bool? ?? false,
  hasExtension: json['hasExtension'] as bool? ?? false,
  extensionTimeMinutes: (json['extensionTimeMinutes'] as num?)?.toInt(),
  extensionCount: (json['extensionCount'] as num?)?.toInt(),
  hasHantei: json['hasHantei'] as bool? ?? false,
  remainingSeconds: (json['remainingSeconds'] as num?)?.toInt() ?? 180,
  timerIsRunning: json['timerIsRunning'] as bool? ?? false,
  note: json['note'] as String? ?? '',
  isKachinuki: json['isKachinuki'] as bool? ?? false,
  rule: json['rule'] == null
      ? null
      : MatchRule.fromJson(json['rule'] as Map<String, dynamic>),
  redRemaining:
      (json['redRemaining'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  whiteRemaining:
      (json['whiteRemaining'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
);

Map<String, dynamic> _$MatchModelToJson(_MatchModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'matchType': instance.matchType,
      'redName': instance.redName,
      'whiteName': instance.whiteName,
      'redScore': instance.redScore,
      'whiteScore': instance.whiteScore,
      'status': instance.status,
      'events': instance.events.map((e) => e.toJson()).toList(),
      'snapshots': instance.snapshots.map((e) => e.toJson()).toList(),
      'isDirty': instance.isDirty,
      'lastUpdatedAt': _$JsonConverterToJson<dynamic, DateTime>(
        instance.lastUpdatedAt,
        const TimestampConverter().toJson,
      ),
      'refereeNames': instance.refereeNames,
      'countForStandings': instance.countForStandings,
      'scorerId': instance.scorerId,
      'lockExpiresAt': _$JsonConverterToJson<dynamic, DateTime>(
        instance.lockExpiresAt,
        const TimestampConverter().toJson,
      ),
      'version': instance.version,
      'isAutoAssigned': instance.isAutoAssigned,
      'order': const DoubleConverter().toJson(instance.order),
      'source': instance.source,
      'tournamentId': instance.tournamentId,
      'category': instance.category,
      'groupName': instance.groupName,
      'matchOrder': instance.matchOrder,
      'matchTimeMinutes': instance.matchTimeMinutes,
      'isRunningTime': instance.isRunningTime,
      'hasExtension': instance.hasExtension,
      'extensionTimeMinutes': instance.extensionTimeMinutes,
      'extensionCount': instance.extensionCount,
      'hasHantei': instance.hasHantei,
      'remainingSeconds': instance.remainingSeconds,
      'timerIsRunning': instance.timerIsRunning,
      'note': instance.note,
      'isKachinuki': instance.isKachinuki,
      'rule': instance.rule?.toJson(),
      'redRemaining': instance.redRemaining,
      'whiteRemaining': instance.whiteRemaining,
    };

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
