// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AuditLog _$AuditLogFromJson(Map<String, dynamic> json) => _AuditLog(
  id: json['id'] as String,
  matchId: json['matchId'] as String,
  userId: json['userId'] as String,
  action: json['action'] as String,
  details: json['details'] as String,
  timestamp: const TimestampConverter().fromJson(json['timestamp']),
);

Map<String, dynamic> _$AuditLogToJson(_AuditLog instance) => <String, dynamic>{
  'id': instance.id,
  'matchId': instance.matchId,
  'userId': instance.userId,
  'action': instance.action,
  'details': instance.details,
  'timestamp': const TimestampConverter().toJson(instance.timestamp),
};
