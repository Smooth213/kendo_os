import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 🛡️ 未成年選手プライバシー保護・マスキングエンジン
class MinorPrivacyFormatter {
  static String formatName({
    required String fullName,
    required bool isPrivacyProtected,
    bool maskSurnameOnly = false,
  }) {
    if (!isPrivacyProtected || fullName.trim().isEmpty) {
      return fullName;
    }

    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (maskSurnameOnly) {
      // 名字＋選手（例: 佐藤 健 ➔ 佐藤 選手）
      return '${parts.first} 選手';
    } else {
      // 名字の頭文字または伏せ字（例: 佐藤 健 ➔ 佐〇 選手）
      final surname = parts.first;
      if (surname.length <= 1) return '$surname〇 選手';
      return '${surname[0]}〇 選手';
    }
  }
}

void main() {
  group('🎨 【Phase 3-11/11】未成年選手実名保護プライバシーマスキング Widgetテスト', () {
    testWidgets('1. プライバシー保護モード有効時、フルネームが隠蔽され実名が画面上に一切漏洩しないこと', (tester) async {
      const realNameRed = '佐藤 健太郎';
      const realNameWhite = '鈴木 一朗太';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    MinorPrivacyFormatter.formatName(
                      fullName: realNameRed,
                      isPrivacyProtected: true,
                    ),
                    key: const Key('red_masked_name'),
                  ),
                  const Text(' VS '),
                  Text(
                    MinorPrivacyFormatter.formatName(
                      fullName: realNameWhite,
                      isPrivacyProtected: true,
                    ),
                    key: const Key('white_masked_name'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // マスキングされた名前が表示される
      expect(find.text('佐〇 選手'), findsOneWidget);
      expect(find.text('鈴〇 選手'), findsOneWidget);

      // 実名（フルネーム）が画面上に一切存在しないこと！
      expect(find.text(realNameRed), findsNothing);
      expect(find.text(realNameWhite), findsNothing);
      expect(find.text('健太郎'), findsNothing);
      expect(find.text('一朗太'), findsNothing);
    });

    testWidgets('2. 保護モード無効時は通常の実名が表示されること', (tester) async {
      const realName = '宮本 武蔵';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Text(
              MinorPrivacyFormatter.formatName(
                fullName: realName,
                isPrivacyProtected: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('宮本 武蔵'), findsOneWidget);
    });
  });
}
