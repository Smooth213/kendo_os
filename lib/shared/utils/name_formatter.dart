class NameFormatter {
  /// 文字列から名字と名前（イニシャル用）を安全にパースします
  static Map<String, String> parse(String raw) {
    if (raw.contains('欠員')) return {'last': '', 'first': ''};
    String clean = raw.contains(':')
        ? raw.split(':').last.replaceAll(RegExp(r'[()（）]'), '').trim()
        : raw.trim();
    var parts = clean.split(RegExp(r'\s+'));
    return {'last': parts[0], 'first': parts.length > 1 ? parts[1] : ''};
  }

  /// グループ名・試合タイトルからUUIDや英数IDの羅列を除去して安全にフォーマットします
  static String formatScoreboardTitle(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '団体戦スコアボード';
    String clean = raw.trim();

    // group_xxxxxxxx-xxxx-... や xxxxxxxx-xxxx-... のようなUUID単体の場合
    final isRawId = RegExp(
      r'^(group_)?[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}',
    ).hasMatch(clean);
    if (isRawId) {
      return '団体戦スコアボード';
    }

    // 「練習試合 - 5a6a33e1-...」や「団体戦 - group_...」のようにハイフン以降にIDが付いている場合
    clean = clean.replaceAll(
      RegExp(
        r'\s*[-_]\s*(group_)?[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}.*$',
      ),
      '',
    );
    clean = clean.replaceAll(RegExp(r'\s*[-_]\s*[0-9a-fA-F]{8,}$'), '');

    if (clean.isEmpty) return '団体戦スコアボード';
    return clean;
  }
}
