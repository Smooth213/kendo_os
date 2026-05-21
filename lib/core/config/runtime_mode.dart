/// kendo_os Stage2 β完成ロードマップ（Phase 2-2）に基づく
/// アプリケーションの実行動作モード定義
enum RuntimeMode {
  /// 一般の道場、保護者、錬成会に投入される安全・シンプル化されたプロダクトモード
  stage2Beta,

  /// 開発者およびガバナンス監査官が内部デバッグ・Replay検証を行うための特権モード
  internal,
}

class RuntimeConfig {
  /// 現在のビルド環境におけるデフォルトの実行モード
  /// Stage2 β リリースでは厳格に [RuntimeMode.stage2Beta] に固定され、内部デバッグ機能を完全遮断します。
  static const RuntimeMode currentMode = RuntimeMode.stage2Beta;
}