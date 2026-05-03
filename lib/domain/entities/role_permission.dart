// ★ フェーズ①: ドメイン定義（モード・役割・権限）

// ① OperationMode: アプリの動作モード
enum OperationMode {
  tournament, // 大会モード（複数人でのクラウド共有・権限ガチガチ）
  local,      // ローカルモード（個人道場や練習試合での簡易利用）
}

// ② Role: ユーザーの役割
enum Role {
  admin,  // 大会管理者（全権限）
  scorer, // 記録係（担当試合のスコア入力のみ）
  editor, // ローカル用編集者（簡易操作）
  viewer, // 閲覧者（Web/QR参加者、入力不可）
}

// ③ Permissions: 役割に紐づく具体的な権限の塊
class Permissions {
  final bool canEditScore;
  final bool canUndo;
  final bool canCreateMatch;
  final bool canLockMatch;
  final bool isReadOnly;

  const Permissions({
    required this.canEditScore,
    required this.canUndo,
    required this.canCreateMatch,
    required this.canLockMatch,
    required this.isReadOnly,
  });
}

// ④ PermissionFactory: RoleからPermissionを生成する工場
class PermissionFactory {
  static Permissions from(Role role) {
    switch (role) {
      case Role.admin:
        return const Permissions(
          canEditScore: true,
          canUndo: true,
          canCreateMatch: true,
          canLockMatch: true,
          isReadOnly: false,
        );
      case Role.scorer:
      case Role.editor:
        return const Permissions(
          canEditScore: true,
          canUndo: true,
          canCreateMatch: false,
          canLockMatch: true,
          isReadOnly: false,
        );
      case Role.viewer:
        return const Permissions(
          canEditScore: false,
          canUndo: false,
          canCreateMatch: false,
          canLockMatch: false,
          isReadOnly: true,
        );
    }
  }
}