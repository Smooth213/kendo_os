import 'package:flutter_test/flutter_test.dart';

/// 🛡️ XSS・HTMLインジェクション・BiDi制御文字サニタイザー
class XssSanitizer {
  static String sanitize(String input) {
    if (input.isEmpty) return '';

    String cleaned = input;

    // 1. 危険なHTML特殊文字のエスケープ
    cleaned = cleaned
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;');

    // 2. javascript: URI スキーム無効化
    cleaned = cleaned.replaceAll(
      RegExp(r'javascript:', caseSensitive: false),
      'blocked:',
    );

    // 3. 右横書き・左横書き反転等の有害なUnicode BiDi制御文字（U+202E等）の除去
    cleaned = cleaned.replaceAll(RegExp(r'[\u202A-\u202E\u2066-\u2069]'), '');

    return cleaned;
  }
}

void main() {
  group('🌐 【Phase 4-6/11】XSS・HTML/スクリプトインジェクション・BiDi文字無害化テスト', () {
    test('1. <script>alert("XSS")</script> が安全にエスケープされること', () {
      const maliciousName = '<script>alert("XSS")</script>';
      final safeName = XssSanitizer.sanitize(maliciousName);

      expect(safeName.contains('<script>'), isFalse);
      expect(safeName.contains('&lt;script&gt;'), isTrue);
      expect(safeName.contains('&quot;XSS&quot;'), isTrue);
    });

    test('2. 偽装リンク javascript:evil() が無害化されること', () {
      const evilPayload = 'javascript:document.cookie';
      final safePayload = XssSanitizer.sanitize(evilPayload);

      expect(safePayload.startsWith('blocked:'), isTrue);
    });

    test('3. テキスト反転Unicodeスプーフィング文字が除去されること', () {
      // U+202E: Right-to-Left Override
      const spoofedName = '選手A\u202E反転攻撃';
      final cleanedName = XssSanitizer.sanitize(spoofedName);

      expect(cleanedName.contains('\u202E'), isFalse);
      expect(cleanedName, '選手A反転攻撃');
    });
  });
}
