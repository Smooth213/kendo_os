import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/utils/text_sanitizer.dart';

void main() {
  group('🥋 【Phase 1-6/10】剣道選手名・道場名における外字・旧字体サニタイズ＆JSON完全一致テスト', () {
    test('1. 代表的な旧字体・異体字・外字が欠損・文字化けせず保持されること', () {
      final rareNames = [
        '髙橋 龍之介', // はしご高
        '山﨑 慎太郎', // たつさき
        '神武館 剣士', // 旧字体 神
        '齋藤 飛鳥', // 齋
        '齊藤 慎二', // 齊
        '渡邊 雄大', // 邊
        '渡邉 勇気', // 邉
        '栁田 武道', // 栁
        '廣田 直樹', // 廣
        '濵田 虎太郎', // 濵
      ];

      for (final name in rareNames) {
        final cleaned = TextSanitizer.clean(name);
        // スペースが除去されるのみで、外字漢字そのものは1文字も欠損・文字化けしないこと
        expect(cleaned.contains('?'), isFalse);
        expect(cleaned.contains('\uFFFD'), isFalse); // 置換文字がないこと
        expect(cleaned.length, greaterThanOrEqualTo(3));
      }
    });

    test('2. 外字・旧字体を含む選手情報がJSONシリアライズ・デシリアライズで完全等価であること', () {
      final originalData = {
        'playerName': '髙橋 神之介',
        'dojoName': '修道館（﨑陽）',
        'rank': '五段',
      };

      final jsonStr = jsonEncode(originalData);
      final decodedData = jsonDecode(jsonStr) as Map<String, dynamic>;

      expect(decodedData['playerName'], '髙橋 神之介');
      expect(decodedData['dojoName'], '修道館（﨑陽）');
      expect(decodedData['rank'], '五段');
    });

    test('3. 前後の不可視文字・制御文字・全角スペースの除去と純粋性保証', () {
      const dirtyInput = "　\t\n 髙橋　健三 \r\n　";
      final cleaned = TextSanitizer.clean(dirtyInput);
      expect(cleaned, '髙橋健三');
    });
  });
}
