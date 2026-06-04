import '../../domain/entities/user_role.dart';
import 'feature_gate.dart';

/// 開発画面やダッシュボードへの進入をパケットレベル・UIレベルで水際ブロックする防衛ガード。
class InternalOnlyGuard {
  /// 指定されたロールが内部特権（Admin）を満たしているかチェックする
  static bool check(UserRole role) {
    return FeatureGate.canExecuteGovernance(role);
  }
}
