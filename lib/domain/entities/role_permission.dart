import 'package:kendo_os/domain/entities/score_event.dart'; // ★ PermissionServiceで参照するため追加

// ★ フェーズ①: ドメイン定義（モード・役割・権限）

// ==========================================
// ★ Phase 1-Step 1: ドメインに「主体（User）」を導入
// システムのすべての変更操作において「誰が」行っているかを強制・証明するための基盤
// ==========================================
class User {
  final String id;
  final Role role;
  final String organizationId;

  const User({
    required this.id,
    required this.role,
    required this.organizationId,
  });
}

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

// ==========================================
// ★ Phase 1-Step 2: 操作単位の厳密な認可サービス (Zero Trustの関所)
// UIの表示制御ではなく、ドメインロジックの直前で操作の正当性を検証する
// ==========================================

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);
  @override
  String toString() => 'UnauthorizedException: $message';
}

class PermissionService {
  // スコア（イベント）追加の権限
  bool canAppend(User user, ScoreEvent event) {
    if (user.role == Role.viewer) return false;
    
    // 例: 取り消し(Undo)や復元イベントは記録係以上のみ
    if (event.isUndo || event.isRestore || event.isCanceled) {
      return user.role == Role.admin || user.role == Role.scorer;
    }
    
    return user.role == Role.admin || user.role == Role.scorer || user.role == Role.editor;
  }

  // 取り消しの権限
  bool canUndo(User user) {
    if (user.role == Role.viewer) return false;
    return user.role == Role.admin || user.role == Role.scorer;
  }

  // 時間切れ操作の権限
  bool canTimeUp(User user) {
    if (user.role == Role.viewer) return false;
    return user.role == Role.admin || user.role == Role.scorer || user.role == Role.editor;
  }
}