// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AuditLog _$AuditLogFromJson(Map<String, dynamic> json) => _AuditLog(
  id: json['id'] as String,
  matchId: json['matchId'] as String,
  userId: json['userId'] as String,
  action: $enumDecode(_$AuditActionEnumMap, json['action']),
  details: json['details'] as String,
  timestamp: const TimestampConverter().fromJson(json['timestamp']),
  deviceId: json['deviceId'] as String? ?? 'local_device',
  logicalClock: (json['logicalClock'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$AuditLogToJson(_AuditLog instance) => <String, dynamic>{
  'id': instance.id,
  'matchId': instance.matchId,
  'userId': instance.userId,
  'action': _$AuditActionEnumMap[instance.action]!,
  'details': instance.details,
  'timestamp': const TimestampConverter().toJson(instance.timestamp),
  'deviceId': instance.deviceId,
  'logicalClock': instance.logicalClock,
};

const _$AuditActionEnumMap = {
  AuditAction.addScore: 'add_score',
  AuditAction.undo: 'undo',
  AuditAction.finish: 'finish',
  AuditAction.approved: 'approved',
  AuditAction.timeUp: 'time_up',
  AuditAction.other: 'other',
};
