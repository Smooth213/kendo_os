/// kendo_os Stage2 β完成ロードマップ（Phase 1-1）に基づく
/// 一般ユーザー向けの「出しすぎない・迷わせない」ための機能制限管理フラグ
class BetaFeatureFlags {
  /// --- Stage2 Beta Public Features ---
  static const bool enableViewer = true;
  static const bool enableScoreInput = true;
  static const bool enableUndo = true;
  static const bool enableTimeline = true;
  static const bool enablePdfExport = true;
  static const bool enableCsvExport = true;
  static const bool enableLocalStorage = true;
  static const bool enableViewerShare = true;

  /// --- Hidden Features (Stage3 以降へ完全秘匿) ---
  static const bool enableAiGovernance = false;
  static const bool showAiFeatures = enableAiGovernance;

  static const bool enableRuleDslEditor = false;
  static const bool showRuleDslEditor = enableRuleDslEditor;

  static const bool enableTemplateCustomizer = false;
  static const bool showAuditTools = enableTemplateCustomizer;

  static const bool enableObservabilityDashboard = false;
  static const bool showObservability = enableObservabilityDashboard;

  static const bool enableReplayManagement = false;
  static const bool showReplayTools = enableReplayManagement;

  static const bool enableInternalMetrics = false;
  static const bool showInternalMetrics = enableInternalMetrics;

  static const bool enableMultiOperator = false;
  static const bool showMultiOperator = enableMultiOperator;
}
