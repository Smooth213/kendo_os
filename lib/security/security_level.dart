/// 大会運用環境全体の防衛フェーズ（セキュリティレベル）を定義する列挙型。
enum SecurityLevel {
  /// OPEN: 全端末編集可能（道場・練習・部内戦向け）
  open,

  /// EVENT: 推奨設定（通常大会・Viewer共有・安全運用）
  event,

  /// LOCKED: 完全閲覧専用（一般公開・観覧専用）
  locked,
}
