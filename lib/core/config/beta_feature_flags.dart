/// kendo_os Stage2 β完成ロードマップ（Phase 1-1）に基づく
/// 一般ユーザー向けの「出しすぎない・迷わせない」ための機能制限管理フラグ
class BetaFeatureFlags {
  /// AI機能（将来の自動判定補助等）の完全封印
  static const bool enableAi = false;
  static const bool showAiFeatures = enableAi; // ★ ロードマップ指定名と同調

  /// AI Governance Runtime の内部メトリクス・ダッシュボードの非表示化
  static const bool enableGovernance = false;
  static const bool showGovernance = enableGovernance;

  /// 高度な Replay 解析ツール・履歴巻き戻し詳細UIの非表示化
  static const bool enableReplayTools = false;
  static const bool showReplayTools = enableReplayTools;

  /// 運営用のリアルタイム Observability メトリクス画面の非表示化
  static const bool enableObservability = false;
  static const bool showObservability = enableObservability;
  static const bool showInternalMetrics = false; // ★ UIへの内部生メトリクス露出を完全禁止

  /// 複数会場での同時オペレーター衝突判定管理UIの非表示化
  static const bool enableMultiOperator = false;
  static const bool showMultiOperator = enableMultiOperator;

  // ★ ロードマップ必須追加フラグの完全固定化
  static const bool showRuleDslEditor = false;
  static const bool showAuditTools = false;
}