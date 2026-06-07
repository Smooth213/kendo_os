// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_aggregate.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MatchSnapshot _$MatchSnapshotFromJson(Map<String, dynamic> json) =>
    _MatchSnapshot(
      id: json['id'] as String,
      matchId: json['matchId'] as String? ?? '',
      version: (json['version'] as num?)?.toInt() ?? 0,
      state: MatchModel.fromJson(json['state'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
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
      'matchId': instance.matchId,
      'version': instance.version,
      'state': instance.state.toJson(),
      'createdAt': instance.createdAt.toIso8601String(),
      'reason': instance.reason,
      'events': instance.events.map((e) => e.toJson()).toList(),
    };

_MatchAggregate _$MatchAggregateFromJson(Map<String, dynamic> json) =>
    _MatchAggregate(
      id: json['id'] as String,
      events:
          (json['events'] as List<dynamic>?)
              ?.map((e) => ScoreEvent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      version: (json['version'] as num?)?.toInt() ?? 0,
      status: json['status'] as String,
      timerStartedAt: const TimestampConverter().fromJson(
        json['timerStartedAt'],
      ),
      accumulatedPauseDurationMs:
          (json['accumulatedPauseDurationMs'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$MatchAggregateToJson(_MatchAggregate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'events': instance.events.map((e) => e.toJson()).toList(),
      'version': instance.version,
      'status': instance.status,
      'timerStartedAt': _$JsonConverterToJson<dynamic, DateTime>(
        instance.timerStartedAt,
        const TimestampConverter().toJson,
      ),
      'accumulatedPauseDurationMs': instance.accumulatedPauseDurationMs,
    };

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
