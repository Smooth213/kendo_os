/// 🥋 大会テキストからの日時抽出ヘルパー
abstract final class TournamentDateParser {
  /// 日時識別のキーワード
  static const List<String> dateKeywords = ['日時', '令和', '202', '平成'];

  /// 日時行のパース
  static DateTime? extractDate(String line) {
    final normalized = normalizeNumbers(line);

    // 和暦: 令和X年 / 平成X年
    final reiwaMatch = RegExp(
      r'令和\s*([0-9]+|元)\s*年\s*([0-9]{1,2})\s*月\s*([0-9]{1,2})\s*日',
    ).firstMatch(normalized);
    if (reiwaMatch != null) {
      final yearStr = reiwaMatch.group(1)!;
      final int year = yearStr == '元' ? 2019 : 2018 + int.parse(yearStr);
      final month = int.parse(reiwaMatch.group(2)!);
      final day = int.parse(reiwaMatch.group(3)!);
      return DateTime(year, month, day);
    }

    final heiseiMatch = RegExp(
      r'平成\s*([0-9]+|元)\s*年\s*([0-9]{1,2})\s*月\s*([0-9]{1,2})\s*日',
    ).firstMatch(normalized);
    if (heiseiMatch != null) {
      final yearStr = heiseiMatch.group(1)!;
      final int year = yearStr == '元' ? 1989 : 1988 + int.parse(yearStr);
      final month = int.parse(heiseiMatch.group(2)!);
      final day = int.parse(heiseiMatch.group(3)!);
      return DateTime(year, month, day);
    }

    // 西暦: 202X年X月X日
    final seirekiMatch = RegExp(
      r'(20[2-3][0-9])\s*年\s*([0-9]{1,2})\s*月\s*([0-9]{1,2})\s*日',
    ).firstMatch(normalized);
    if (seirekiMatch != null) {
      final year = int.parse(seirekiMatch.group(1)!);
      final month = int.parse(seirekiMatch.group(2)!);
      final day = int.parse(seirekiMatch.group(3)!);
      return DateTime(year, month, day);
    }

    // スラッシュ/ハイフン形式: 2026/09/20, 2026-9-20
    final slashMatch = RegExp(
      r'(20[2-3][0-9])[\/\-\.]([0-9]{1,2})[\/\-\.]([0-9]{1,2})',
    ).firstMatch(normalized);
    if (slashMatch != null) {
      final year = int.parse(slashMatch.group(1)!);
      final month = int.parse(slashMatch.group(2)!);
      final day = int.parse(slashMatch.group(3)!);
      return DateTime(year, month, day);
    }

    return null;
  }

  /// 全角数字を半角数字に正規化
  static String normalizeNumbers(String input) {
    const fullWidth = '０１２３４５６７８９';
    const halfWidth = '0123456789';
    var result = input;
    for (int i = 0; i < fullWidth.length; i++) {
      result = result.replaceAll(fullWidth[i], halfWidth[i]);
    }
    return result;
  }
}
