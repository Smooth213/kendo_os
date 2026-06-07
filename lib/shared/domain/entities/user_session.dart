import 'user_role.dart';

/// 認証PINの直保存を厳格に禁止し、セッションの有効期限とバージョンのみを
/// 決定論的にカプセル化する不変ドメインセッションエンティティ。
class UserSession {
  final UserRole role;
  final DateTime loginAt;
  final DateTime expiresAt;
  final int sessionVersion;

  const UserSession({
    required this.role,
    required this.loginAt,
    required this.expiresAt,
    this.sessionVersion = 1, // セッション構造変更や一斉破棄に備えたバージョン管理
  });

  /// 期限切れ判定（現在時刻が expiresAt を超えていれば true）
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// ローカルストレージ保存用のシリアライズ
  Map<String, dynamic> toJson() => {
    'role': role.name,
    'loginAt': loginAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
    'sessionVersion': sessionVersion,
  };

  /// ローカルストレージ復元用のデシリアライズ
  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.viewer,
      ),
      loginAt: DateTime.parse(json['loginAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      sessionVersion: json['sessionVersion'] as int? ?? 1,
    );
  }
}
