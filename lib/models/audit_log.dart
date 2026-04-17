import 'package:freezed_annotation/freezed_annotation.dart';
import 'json_converters.dart';

part 'audit_log.freezed.dart';
part 'audit_log.g.dart';

@freezed
abstract class AuditLog with _$AuditLog {
  const factory AuditLog({
    required String id,
    required String matchId,
    required String userId, // 誰が操作したか
    required String action, // 例: 'add_score', 'undo', 'finish', 'approved'
    required String details, // 例: '赤 メ', '試合終了'
    @TimestampConverter() required DateTime timestamp,
  }) = _AuditLog;

  factory AuditLog.fromJson(Map<String, dynamic> json) => _$AuditLogFromJson(json);
}