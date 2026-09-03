import 'package:flutter_test/flutter_test.dart';

/// 🥋 剣道名札・ゼッケン縦書き組版エンジン
class VerticalTypesetter {
  /// 縦書きテキスト行への分割（縦中横判定）
  static List<String> typeset(String name) {
    if (name.isEmpty) return [];

    final result = <String>[];
    final buffer = StringBuffer();

    for (int i = 0; i < name.length; i++) {
      final char = name[i];

      // アルファベット・ウムラウト・アポストロフィ・記号の場合
      if (RegExp(r'[a-zA-Z0-9üöäéèàáçÜÖÄÉÈ\-_.\x27]').hasMatch(char)) {
        buffer.write(char);
      } else {
        // 漢字やスペースの場合
        if (buffer.isNotEmpty) {
          result.add(buffer.toString());
          buffer.clear();
        }
        if (char.trim().isNotEmpty) {
          result.add(char);
        }
      }
    }

    if (buffer.isNotEmpty) {
      result.add(buffer.toString());
    }

    return result;
  }
}

void main() {
  group('🌐 【Phase 4-11/11】国際外国人選手名（Smith, Müller等）縦書き縦中横組版テスト', () {
    test('1. アルファベット名（Smith）が1文字ずつバラバラにならず単語ブロックとして保持されること', () {
      final blocks = VerticalTypesetter.typeset('Smith');
      expect(blocks, ['Smith']);
    });

    test('2. ドイツ語ウムラウト（Müller）やフランス語（D\'Artagnan）が欠損せず組版されること', () {
      final germanBlocks = VerticalTypesetter.typeset('Müller');
      expect(germanBlocks, ['Müller']);

      final frenchBlocks = VerticalTypesetter.typeset("D'Artagnan");
      expect(frenchBlocks, ["D'Artagnan"]);
    });

    test('3. 漢字とアルファベットの混在（例: 剣士 Smith）が正しく縦書き分離されること', () {
      final mixedBlocks = VerticalTypesetter.typeset('剣士 Smith');
      expect(mixedBlocks, ['剣', '士', 'Smith']);
    });
  });
}
