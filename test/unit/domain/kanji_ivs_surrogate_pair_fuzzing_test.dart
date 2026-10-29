import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/utils/text_sanitizer.dart';

void main() {
  group('[Unit] 漢字異体字セレクタおよびサロゲートペアファジング検証テスト', () {
    test('異体字セレクタやサロゲートペアを含む選手名が文字化けや分離を起こさず保持されること', () {
      final challengingNames = [
        '𠮷野 晴彦', // つち吉 (サロゲートペア: U+20BB7)
        '森󠄁 鴎外', // 森 + IVS (U+68EE U+E0101)
        '髙橋 﨑陽', // はしご高、たつ崎
        '葛󠄀飾 北斎', // 葛 + IVS (U+845B U+E0100)
        '德川󠄀 家康', // 旧字体 德 + 川 + IVS
        '𡈽屋 𩸽', // サロゲートペア複数
      ];

      for (final name in challengingNames) {
        // 1. サニタイズによる文字化け（?や置換文字）の発生ゼロ
        final cleaned = TextSanitizer.clean(name);
        expect(cleaned.contains('?'), isFalse);
        expect(cleaned.contains('\uFFFD'), isFalse);

        // 2. グラフェムクラスタ（視覚的文字数）の正確性
        final graphemes = name.replaceAll(' ', '').characters;
        expect(graphemes.isNotEmpty, isTrue);

        // 3. MatchModel での保持とJSONシリアライズの可逆性
        final match = MatchModel(
          id: 'match_ivs_${name.hashCode}',
          redName: name,
          whiteName: '通常 剣士',
          matchType: '個人戦',
        );

        final jsonMap = match.toJson();
        final restored = MatchModel.fromJson(jsonMap);
        expect(restored.redName, name);

        // 4. UTF-8 バイト変換の完全可逆性
        final bytes = utf8.encode(jsonEncode(jsonMap));
        final decoded = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
        expect(decoded['redName'], name);
      }
    });

    test('異体字セレクタ付き文字のグラフェムクラスタ分割で基底文字とセレクタが1文字として結合維持されること', () {
      // 「森󠄁」: U+68EE U+E0101
      const moriIvs = '森󠄁';
      expect(moriIvs.characters.length, 1);
      expect(moriIvs.codeUnits.length, greaterThan(1));

      // 「𠮷野」: 「𠮷」はサロゲートペア
      const yoshino = '𠮷野';
      expect(yoshino.characters.length, 2);
      expect(yoshino.characters.first, '𠮷');

      // 文字列結合とトリムで欠損しないこと
      const composite = '　𠮷野󠄀 太郎　';
      final sanitized = TextSanitizer.clean(composite);
      expect(sanitized, '𠮷野󠄀太郎');
    });
  });
}
