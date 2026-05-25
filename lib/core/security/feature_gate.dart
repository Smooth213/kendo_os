import '../../domain/entities/user_role.dart';
import 'security_level.dart';
import 'role_permissions.dart';

/// Stage2 β環境における、すべての内部機能・操作権限の可否を中央一元統治するゲートウェイ。
class FeatureGate {
  /// 既存防衛線：未公開コードの実行ブロック
  static void ensure(bool enabled) {
    if (!enabled) {
      throw UnsupportedError('🔒 Feature disabled in Stage2 beta');
    }
  }

  // =========================================================================
  // 🌟 Phase 11 要件：一般ユーザーへ絶対露出させない内部特権機能ガード (Admin専用)
  // =========================================================================

  /// AIによる試合分析・統計の利用権限
  static bool canUseAI(UserRole role) => role == UserRole.admin;

  /// 試合のビデオReplay・履歴巻き戻し管理権限
  static bool canManageReplay(UserRole role) => role == UserRole.admin;

  /// Observability（システムログ監視ダッシュボード）へのアクセス権限
  static bool canAccessObservability(UserRole role) => role == UserRole.admin;

  /// 内部Metrics（システムパフォーマンス・エラー計測）の閲覧権限
  static bool canAccessMetrics(UserRole role) => role == UserRole.admin;

  /// ガバナンス監査・アクセスログ監査の実行権限
  static bool canExecuteGovernance(UserRole role) => role == UserRole.admin;


  // =========================================================================
  // 🌟 各画面・入力操作権限マトリクス（SecurityLevelとの複合判定）
  // =========================================================================

  /// 新規大会の作成権限
  static bool canCreateMatch(UserRole role, SecurityLevel level) {
    if (level == SecurityLevel.locked) return false;
    return RolePermissions.canCreateTournament(role);
  }

  /// 試合の入力・スコア記録・Undoの操作権限
  static bool canOperateMatch(UserRole role, SecurityLevel level) {
    if (level == SecurityLevel.locked) return false;
    if (level == SecurityLevel.open) return true; // 緊急全開放
    return RolePermissions.canOperateMatch(role);
  }

  /// 選手登録や大会設定などのマスター管理、データ削除権限
  static bool canManageMaster(UserRole role, SecurityLevel level) {
    if (level == SecurityLevel.locked) return false;
    return RolePermissions.canEditPlayerMaster(role);
  }
}