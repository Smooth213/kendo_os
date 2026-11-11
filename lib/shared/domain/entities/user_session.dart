import 'user_role.dart';

/// 認証PINの直保存を厳格に禁止し、セッションの有効期限・対象道場・バージョンのみを
/// 決定論的にカプセル化する不変ドメインセッションエンティティ。
class UserSession {
  static const int currentSessionVersion = 2;

  final UserRole role;
  final DateTime loginAt;
  final DateTime expiresAt;
  final int sessionVersion;
  final String dojoId;
  final String? verifiedJoinPinHash;
  final String? shareToken;
  final String? sharedTournamentId;

  const UserSession({
    required this.role,
    required this.loginAt,
    required this.expiresAt,
    this.sessionVersion = currentSessionVersion, // セッション構造変更や一斉破棄に備えたバージョン管理
    this.dojoId = '',
    this.verifiedJoinPinHash,
    this.shareToken,
    this.sharedTournamentId,
  });

  /// 期限切れ判定（現在時刻が expiresAt を超えていれば true）
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// 1大会限定の共有リンク経由セッションかどうか
  bool get isShareScoped =>
      shareToken != null &&
      shareToken!.isNotEmpty &&
      sharedTournamentId != null &&
      sharedTournamentId!.isNotEmpty;

  /// 指定道場に対して正規の道場入室セッションが有効かどうか
  bool isAuthorizedForDojo(String targetDojoId) =>
      !isExpired &&
      !isShareScoped &&
      dojoId.isNotEmpty &&
      dojoId == targetDojoId;

  /// ローカルストレージ保存用のシリアライズ
  Map<String, dynamic> toJson() => {
    'role': role.name,
    'loginAt': loginAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
    'sessionVersion': sessionVersion,
    'dojoId': dojoId,
    if (verifiedJoinPinHash != null) 'verifiedJoinPinHash': verifiedJoinPinHash,
    if (shareToken != null) 'shareToken': shareToken,
    if (sharedTournamentId != null) 'sharedTournamentId': sharedTournamentId,
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
      dojoId: json['dojoId'] as String? ?? '',
      verifiedJoinPinHash: json['verifiedJoinPinHash'] as String?,
      shareToken: json['shareToken'] as String?,
      sharedTournamentId: json['sharedTournamentId'] as String?,
    );
  }
}
