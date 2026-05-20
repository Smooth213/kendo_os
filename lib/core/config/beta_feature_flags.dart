/// kendo_os Stage2 β完成ロードマップ（Phase 0-3）に基づく
/// 一般ユーザー向けの「出しすぎない・迷わせない」ための機能制限管理フラグ
class BetaFeatureFlags {
  /// AI機能（将来の自動判定補助等）の完全封印
  static const bool enableAi = false;

  /// AI Governance Runtime の内部メトリクス・ダッシュボードの非表示化
  static const bool enableGovernance = false;

  /// 高度な Replay 解析ツール・履歴巻き戻し詳細UIの非表示化
  static const bool enableReplayTools = false;

  /// 運営用のリアルタイム Observability メトリクス画面の非表示化
  static const bool enableObservability = false;

  /// 複数会場での同時オペレーター衝突判定管理UIの非表示化
  static const bool enableMultiOperator = false;
}