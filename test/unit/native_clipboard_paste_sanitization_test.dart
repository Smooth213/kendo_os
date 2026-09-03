import 'package:flutter_test/flutter_test.dart';

/// 📋 クリップボード貼り付けサニタイザー
class ClipboardSanitizer {
  /// クリップボードの生文字列から安全なプレーンテキストを抽出
  static String sanitizePastedText(String rawClipboardContent) {
    if (rawClipboardContent.isEmpty) return '';

    // 1. HTMLタグの完全ストリップ
    String cleaned = rawClipboardContent.replaceAll(RegExp(r'<[^>]*>'), '');

    // 2. 制御文字（NULLバイト、改行連打等）の正規化
    cleaned = cleaned
        .replaceAll('\x00', '')
        .replaceAll(RegExp(r'[\r\n]+'), ' ');

    // 3. 最大文字数（100文字）での安全切り詰め
    if (cleaned.length > 100) {
      cleaned = cleaned.substring(0, 100);
    }

    return cleaned.trim();
  }
}

void main() {
  group('🌍 【Phase 8-4/7】OSクリップボード貼り付け HTML・制御文字サニタイズテスト', () {
    test('1. リッチテキストHTML（<span style=...>佐藤</span>）がプレーンテキスト「佐藤」へ変換されること', () {
      const richHtml =
          '<b style="color:red"><span onclick="evil()">佐藤 健</span></b>';
      final safeText = ClipboardSanitizer.sanitizePastedText(richHtml);

      expect(safeText, '佐藤 健');
      expect(safeText.contains('<'), isFalse);
      expect(safeText.contains('evil'), isFalse);
    });

    test('2. 改行連打やNULL文字が含まれていても単一スペース区切りの安全な文字列に変換されること', () {
      const messyPaste = '山田\r\n\r\n\x00太郎\n\n道場';
      final safeText = ClipboardSanitizer.sanitizePastedText(messyPaste);

      expect(safeText, '山田 太郎 道場');
    });
  });
}
