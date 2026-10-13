class NameFormatter {
  /// 文字列から名字と名前（イニシャル用）を安全にパースします
  static Map<String, String> parse(String raw) {
    if (raw.contains('欠員')) return {'last': '', 'first': ''};
    String clean = raw.contains(':')
        ? raw.split(':').last.replaceAll(RegExp(r'[()（）]'), '').trim()
        : raw.trim();

    // 形競技などのペア選手（「・」区切り）の場合、両名の苗字を「・」で連結して返す
    if (clean.contains('・')) {
      final pairList = parseKataPair(clean);
      final pairLast = pairList
          .map((p) {
            return p.initial.isNotEmpty
                ? '${p.lastName}（${p.initial}）'
                : p.lastName;
          })
          .join('・');
      return {'last': pairLast.isNotEmpty ? pairLast : clean, 'first': ''};
    }

    var parts = clean.split(RegExp(r'\s+'));
    return {'last': parts[0], 'first': parts.length > 1 ? parts[1] : ''};
  }

  /// 形競技ペア選手の解析結果（苗字と、同姓時の名前頭文字）
  static List<({String lastName, String initial})> parseKataPair(
    String raw, {
    List<String> teamPlayerNames = const [],
  }) {
    if (raw.contains('欠員')) return const [];
    String clean = raw.contains(':')
        ? raw.split(':').last.replaceAll(RegExp(r'[()（）]'), '').trim()
        : raw.trim();

    final parts = clean.split('・');
    final result = <({String lastName, String initial})>[];

    final pairLastNames = parts
        .map((p) => _extractSingleLastName(p))
        .where((s) => s.isNotEmpty)
        .toList();

    // チーム内の他選手の苗字リスト
    final otherTeamLastNames = <String>[];
    for (var n in teamPlayerNames) {
      final c = n.contains(':')
          ? n.split(':').last.replaceAll(RegExp(r'[()（）]'), '').trim()
          : n.trim();
      if (c == clean) continue;
      for (var sub in c.split('・')) {
        final ln = _extractSingleLastName(sub);
        if (ln.isNotEmpty) otherTeamLastNames.add(ln);
      }
    }

    for (var part in parts) {
      var trimmed = part
          .trim()
          .replaceFirst(RegExp(r'^(打太刀|仕太刀|掛り手|元立ち)[:\s]*'), '')
          .trim();
      var nameParts = trimmed.split(RegExp(r'\s+'));
      if (nameParts.isEmpty || nameParts[0].isEmpty) continue;
      final lastName = nameParts[0];
      final firstName = nameParts.length > 1 ? nameParts[1] : '';

      final hasInOtherTeam = otherTeamLastNames.contains(lastName);
      final inPairCount = pairLastNames.where((ln) => ln == lastName).length;
      final isDuplicate = hasInOtherTeam || inPairCount > 1;

      final initial = (isDuplicate && firstName.isNotEmpty)
          ? firstName.substring(0, 1)
          : '';

      result.add((lastName: lastName, initial: initial));
    }

    return result;
  }

  static String _extractSingleLastName(String rawPart) {
    var trimmed = rawPart.trim();
    trimmed = trimmed.replaceFirst(RegExp(r'^(打太刀|仕太刀|掛り手|元立ち)[:\s]*'), '');
    var parts = trimmed.trim().split(RegExp(r'\s+'));
    return parts.isNotEmpty ? parts[0] : '';
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
