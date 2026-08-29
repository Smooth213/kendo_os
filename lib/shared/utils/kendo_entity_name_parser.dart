/// 剣道ドメインにおける道場名・チーム名・選手名パース共通ユーティリティ
class KendoEntityNameParser {
  KendoEntityNameParser._();

  /// 文字列の正規化（全角コロン・全角括弧を半角に統一し、前後の空白を除去）
  static String normalize(String raw) {
    return raw
        .replaceAll('：', ':')
        .replaceAll('（', '(')
        .replaceAll('）', ')')
        .trim();
  }

  /// チーム名（道場名）を抽出
  /// - 例: "道上剣友会A: 皿田" ➔ "道上剣友会A"
  /// - 例: "皿田 (道上剣友会)" ➔ "道上剣友会"
  /// - 例: "道上剣友会" ➔ "道上剣友会"
  static String extractTeamName(String raw) {
    final clean = normalize(raw);
    if (clean.contains(':')) {
      return clean.split(':').first.trim();
    }
    if (clean.contains('(') && clean.endsWith(')')) {
      final startIndex = clean.lastIndexOf('(');
      final endIndex = clean.lastIndexOf(')');
      if (startIndex < endIndex) {
        return clean.substring(startIndex + 1, endIndex).trim();
      }
    }
    return clean;
  }

  /// 選手名を抽出
  /// - 例: "道上剣友会A: 皿田" ➔ "皿田"
  /// - 例: "皿田 (道上剣友会)" ➔ "皿田"
  /// - 例: "皿田" ➔ "皿田"
  static String extractPlayerName(String raw) {
    final clean = normalize(raw);
    if (clean.contains(':')) {
      final namePart = clean.split(':').last.trim();
      return namePart.replaceAll(RegExp(r'[()]'), '').trim();
    }
    if (clean.contains('(')) {
      final startIndex = clean.indexOf('(');
      return clean.substring(0, startIndex).trim();
    }
    return clean;
  }

  /// 試合形式に応じた公式表示名称を生成
  /// - 団体戦: チーム名のみ（例: "道上剣友会A"）
  /// - 個人戦（所属あり）: "選手名 (所属)"（例: "皿田 (道上剣友会A)"）
  /// - 個人戦（所属なし）: "選手名"（例: "皿田"）
  static String formatDisplayName({
    required String raw,
    required bool isIndividual,
  }) {
    if (!isIndividual) {
      return extractTeamName(raw);
    }
    final player = extractPlayerName(raw);
    final team = extractTeamName(raw);
    if (team.isNotEmpty && team != player) {
      return '$player ($team)';
    }
    return player;
  }
}
