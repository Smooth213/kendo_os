/// 大会・遠征・部内戦運営システムにおける役割（ロール）ベースのアクセス権限定義。
enum UserRole {
  /// 代表・管理者: 道場代表・指導者。全機能アクセス、選手マスター・PIN設定を含む全権限を保持
  admin,

  /// 監督・引率責任者: 監督・引率リーダー。対戦作成、試合進行、プログラム共有ペン等を担当
  operator,

  /// スコア・記録係: 引率保護者・生徒。スコア速報入力、ルール編集を担当（削除不可）
  recorder,

  /// 応援・保護者・選手: 一般保護者・選手。リアルタイム速報閲覧、個人ペンメモ（PIN不要）
  viewer;

  String get displayName {
    switch (this) {
      case UserRole.admin:
        return '代表・管理者 (Admin)';
      case UserRole.operator:
        return '監督・引率責任者 (Operator)';
      case UserRole.recorder:
        return 'スコア・記録係 (Recorder)';
      case UserRole.viewer:
        return '応援・保護者・選手 (Viewer)';
    }
  }

  String get shortDisplayName {
    switch (this) {
      case UserRole.admin:
        return '代表・管理者';
      case UserRole.operator:
        return '監督・引率責任者';
      case UserRole.recorder:
        return 'スコア・記録係';
      case UserRole.viewer:
        return '応援・保護者・選手';
    }
  }
}
