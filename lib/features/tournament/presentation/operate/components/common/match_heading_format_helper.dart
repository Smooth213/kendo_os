/// 🥋 試合場・試合順・ラウンド見出し文字列の生成・解析ヘルパー
class MatchHeadingFormatHelper {
  MatchHeadingFormatHelper._();

  /// テキストから試合場番号を抽出（例: "第1試合場, 3試合目" -> 1）
  static int? extractCourtNumber(String text) {
    if (text.isEmpty) return null;
    final match = RegExp(r'(?:第\s*(\d+)\s*(?:試合場|会場|コート))').firstMatch(text);
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }
    return null;
  }

  /// テキストから試合順番号を抽出（例: "第1試合場, 3試合目" -> 3）
  static int? extractMatchOrder(String text) {
    if (text.isEmpty) return null;
    final match = RegExp(
      r'(?:(?:第\s*(\d+)\s*試合(?!場|会場))|(\d+)\s*試合目)',
    ).firstMatch(text);
    if (match != null) {
      final numStr = match.group(1) ?? match.group(2);
      if (numStr != null) {
        return int.tryParse(numStr);
      }
    }
    return null;
  }

  /// テキストからラウンド・回戦名（1回戦、準決勝等）を抽出
  static String? extractRound(String text) {
    if (text.isEmpty) return null;
    final match = RegExp(
      r'(1回戦|2回戦|3回戦|4回戦|5回戦|準々決勝|準決勝|決勝戦|決勝|3位決定戦|予選リーグ|[A-Za-z]リーグ)',
    ).firstMatch(text);
    if (match != null) {
      return match.group(1);
    }
    return null;
  }

  /// 現在のテキストを元に、試合場・試合順・ラウンドを更新した見出し文字列を構築
  static String updateHeading({
    required String currentText,
    int? courtNumber,
    int? matchOrder,
    String? selectedRound,
  }) {
    final parts = <String>[];

    // 1. 試合場
    if (courtNumber != null && courtNumber > 0) {
      parts.add('第$courtNumber試合場');
    }

    // 2. 試合順
    if (matchOrder != null && matchOrder > 0) {
      parts.add('$matchOrder試合目');
    }

    // 3. ラウンド・回戦
    if (selectedRound != null && selectedRound.isNotEmpty) {
      parts.add(selectedRound);
    }

    // 4. その他のカスタムテキスト（カンマ区切りのうち、上記3つに該当しないものを保持）
    if (currentText.isNotEmpty) {
      final existingTokens = currentText.split(',').map((e) => e.trim());
      for (final token in existingTokens) {
        if (token.isEmpty) continue;
        final isCourt = RegExp(r'第?\s*\d+\s*(?:試合場|会場|コート)').hasMatch(token);
        final isOrder = RegExp(
          r'(?:第?\s*\d+\s*試合(?!場)|(?:\d+)\s*試合目)',
        ).hasMatch(token);
        final isRound = RegExp(
          r'(1回戦|2回戦|3回戦|4回戦|5回戦|準々決勝|準決勝|決勝戦|決勝|3位決定戦|予選リーグ|[A-Za-z]リーグ)',
        ).hasMatch(token);

        if (!isCourt && !isOrder && !isRound) {
          if (!parts.contains(token)) {
            parts.add(token);
          }
        }
      }
    }

    return parts.join(', ');
  }

  /// ラウンドチップのトグル処理
  static String toggleRound({
    required String currentText,
    required String roundPreset,
    int? courtNumber,
    int? matchOrder,
  }) {
    final tokens = currentText
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (tokens.contains(roundPreset)) {
      tokens.remove(roundPreset);
      return tokens.join(', ');
    } else {
      // 既存の他のラウンドチップがあれば置き換えるか、あるいは追加
      // ラウンドは通常1試合に1つなので、既存ラウンドを削除して新ラウンドを追加
      final roundRegex = RegExp(
        r'^(1回戦|2回戦|3回戦|4回戦|5回戦|準々決勝|準決勝|決勝戦|決勝|3位決定戦|予選リーグ|[A-Za-z]リーグ)$',
      );
      tokens.removeWhere((t) => roundRegex.hasMatch(t));
      tokens.add(roundPreset);
      return tokens.join(', ');
    }
  }

  /// 公開用・公式見出しのみを抽出（2行目以降の運営メモ・特記事項を除外）
  static String extractPublicHeading(String? note) {
    if (note == null || note.isEmpty) return '';
    final lines = note.split('\n');
    return lines.first.trim();
  }

  /// 運営メモ（内部特記事項・2行目以降）のみを抽出
  static String extractPrivateNote(String? note) {
    if (note == null || note.isEmpty) return '';
    final lines = note.split('\n');
    if (lines.length <= 1) return '';
    return lines.sublist(1).join('\n').trim();
  }
}
