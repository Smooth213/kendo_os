import '../../domain/entities/user_role.dart';

/// 端末が現在どの道場スペースに接続し、どの権限で、どの物理デバイスとして
/// 稼働しているかを決定論的に一元保持する同期コンテキスト。
class CurrentSyncContext {
  final String organizationId;
  final UserRole role;
  final String deviceId;

  const CurrentSyncContext({
    required this.organizationId,
    required this.role,
    required this.deviceId,
  });

  /// 内部コピー用
  CurrentSyncContext copyWith({
    String? organizationId,
    UserRole? role,
    String? deviceId,
  }) {
    return CurrentSyncContext(
      organizationId: organizationId ?? this.organizationId,
      role: role ?? this.role,
      deviceId: deviceId ?? this.deviceId,
    );
  }
}