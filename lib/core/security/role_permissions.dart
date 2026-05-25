import '../../domain/entities/user_role.dart';

/// 画面ごとの権限判定の乱立を絶対禁止し、セキュリティポリシーを一元統治する集中管理クラス。
class RolePermissions {
  /// 新規大会の作成権限（Admin, Operatorのみ許可）
  static bool canCreateTournament(UserRole role) {
    return role == UserRole.admin || role == UserRole.operator;
  }

  /// 大会の完全削除権限（最高特権の Admin のみに制限）
  static bool canDeleteTournament(UserRole role) {
    return role == UserRole.admin;
  }

  /// 大会自体の構造・設定の編集権限（Adminのみ許可）
  static bool canEditTournament(UserRole role) {
    return role == UserRole.admin;
  }

  /// 選手マスタ画面へのアクセス権限（Viewer以外すべて許可）
  static bool canAccessPlayerMaster(UserRole role) {
    return role != UserRole.viewer;
  }

  /// 選手マスタの追加・編集・削除などの変更権限（Adminのみに制限し、誤編集を完全排除）
  static bool canEditPlayerMaster(UserRole role) {
    return role == UserRole.admin;
  }

  /// 個別の試合データの編集・削除権限（Admin, Operatorのみに制限）
  static bool canEditAndDeleteMatch(UserRole role) {
    return role == UserRole.admin || role == UserRole.operator;
  }

  /// 試合の新規作成、スコア入力、大会進行の操作権限
  static bool canOperateMatch(UserRole role) {
    return role != UserRole.viewer;
  }

  /// Undo（打突の取り消し）機能の利用権限
  static bool canUseUndo(UserRole role) {
    return role != UserRole.viewer;
  }

  /// アプリ設定画面へのアクセス権限（管理者への昇格や表示設定が含まれるためViewer以外に許可）
  static bool canAccessSettings(UserRole role) {
    return role != UserRole.viewer;
  }

  /// 現在のロールが完全閲覧専用の Viewer かどうかを判定
  static bool isViewer(UserRole role) {
    return role == UserRole.viewer;
  }
}