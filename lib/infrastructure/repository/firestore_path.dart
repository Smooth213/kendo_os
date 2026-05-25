/// Firestore上のすべてのコレクション・ドキュメントパスを「1道場 = 1同期空間」の
/// ネスト構造へ完全強制・統一するための決定論的パスファクトリ。
class FirestorePath {
  /// ルート直下の組織（道場）ドキュメントパス
  static String organization(String dojoId) => 'organizations/$dojoId';

  /// 組織直下の選手マスタコレクションパス
  static String players(String dojoId) => 'organizations/$dojoId/players';
  static String player(String dojoId, String playerId) => 'organizations/$dojoId/players/$playerId';

  /// 組織直下の試合データコレクションパス
  static String matches(String dojoId) => 'organizations/$dojoId/matches';
  static String match(String dojoId, String matchId) => 'organizations/$dojoId/matches/$matchId';

  /// 組織直下の大会データコレクションパス
  static String tournaments(String dojoId) => 'organizations/$dojoId/tournaments';
  static String tournament(String dojoId, String tournamentId) => 'organizations/$dojoId/tournaments/$tournamentId';

  /// 組織直下のシステム環境設定ドキュメントパス
  static String settings(String dojoId) => 'organizations/$dojoId/settings/config';

  /// 組織直下の監査ログコレクションパス
  static String auditLogs(String dojoId) => 'organizations/$dojoId/auditLogs';
}