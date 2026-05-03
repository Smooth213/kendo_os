// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_aggregate.dart';

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

_MatchAggregate _$MatchAggregateFromJson(Map<String, dynamic> json) =>
    _MatchAggregate(
      id: json['id'] as String,
      rule: MatchRule.fromJson(json['rule'] as Map<String, dynamic>),
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
      status: json['status'] as String? ?? 'waiting',
      redScore: (json['redScore'] as num?)?.toInt() ?? 0,
      whiteScore: (json['whiteScore'] as num?)?.toInt() ?? 0,
      remainingSeconds: (json['remainingSeconds'] as num?)?.toInt() ?? 180,
      timerIsRunning: json['timerIsRunning'] as bool? ?? false,
    );

Map<String, dynamic> _$MatchAggregateToJson(_MatchAggregate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'rule': instance.rule.toJson(),
      'events': instance.events.map((e) => e.toJson()).toList(),
      'snapshots': instance.snapshots.map((e) => e.toJson()).toList(),
      'status': instance.status,
      'redScore': instance.redScore,
      'whiteScore': instance.whiteScore,
      'remainingSeconds': instance.remainingSeconds,
      'timerIsRunning': instance.timerIsRunning,
    };
