import 'package:freezed_annotation/freezed_annotation.dart';
import '../../infrastructure/persistence/converters/json_converters.dart';

part 'audit_log.freezed.dart';
part 'audit_log.g.dart';

// ★ 改善: actionをStringからEnumに変更し、タイポを防ぎ集計・クエリを安全にする
enum AuditAction {
  @JsonValue('add_score')
  addScore,
  @JsonValue('undo')
  undo,
  @JsonValue('finish')
  finish,
  @JsonValue('approved')
  approved,
  @JsonValue('time_up')
  timeUp, // ★ 追加: 既存の実装で使われていたアクション
  @JsonValue('other')
  other,
}

@freezed
abstract class AuditLog with _$AuditLog {
  const factory AuditLog({
    required String id,

    /// ★ 新・同期空間統治キー：監査ログおよびタイムラインが帰属する最上位道場キー
    @Default('default_org') String organizationId,
    required String matchId,
    required String userId,
    required AuditAction action,
    required String details,
    @TimestampConverter() required DateTime timestamp,

    // ==========================================
    // ★ Phase 5-Step 1: 分散同期のトレーサビリティ強化
    // ==========================================
    @Default('local_device') String deviceId, // どの端末からの操作か
    @Default(0) int logicalClock, // 操作時の論理時計（順序の証拠）
  }) = _AuditLog;

  factory AuditLog.fromJson(Map<String, dynamic> json) =>
      _$AuditLogFromJson(json);
}
