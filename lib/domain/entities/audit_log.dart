import 'package:freezed_annotation/freezed_annotation.dart';
import '../../infrastructure/persistence/converters/json_converters.dart';

part 'audit_log.freezed.dart';
part 'audit_log.g.dart';

// ★ 改善: actionをStringからEnumに変更し、タイポを防ぎ集計・クエリを安全にする
enum AuditAction {
  @JsonValue('add_score') addScore,
  @JsonValue('undo') undo,
  @JsonValue('finish') finish,
  @JsonValue('approved') approved,
  @JsonValue('time_up') timeUp, // ★ 追加: 既存の実装で使われていたアクション
  @JsonValue('other') other,
}

@freezed
abstract class AuditLog with _$AuditLog {
  const factory AuditLog({
    required String id,
    required String matchId,
    required String userId,
    required AuditAction action, // ★ StringからEnumへ変更
    required String details,
    @TimestampConverter() required DateTime timestamp,
  }) = _AuditLog;

  factory AuditLog.fromJson(Map<String, dynamic> json) => _$AuditLogFromJson(json);
}