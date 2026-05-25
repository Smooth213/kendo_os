import 'user_role.dart';

/// Firestore上の organizations/{dojoId}/members/{uid} にマッピングされ、
/// 端末/ユーザーの操作権限をクラウド統治するための不変メンバーモデル。
class MemberRoleModel {
  final String uid;
  final UserRole role;
  final String displayName;
  final DateTime updatedAt;

  const MemberRoleModel({
    required this.uid,
    required this.role,
    required this.displayName,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'role': role.name,
    'displayName': displayName,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory MemberRoleModel.fromJson(String uid, Map<String, dynamic> json) {
    return MemberRoleModel(
      uid: uid,
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.viewer,
      ),
      displayName: json['displayName'] as String? ?? '操作端末',
      updatedAt: DateTime.parse(json['updatedAt'] as String? ?? DateTime.now().toIso8601String()),
    );
  }
}