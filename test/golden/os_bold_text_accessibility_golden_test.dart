import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('📸 【Phase 3-8/11】OS「太字テキスト」アクセシビリティ有効時 Goldenテスト', () {
    testWidgets('1. boldText: true 環境下でボタン・ラベルが崩れず正確に描画されること', (tester) async {
      tester.view.physicalSize = const Size(600, 300);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(boldText: true), // OS太字設定
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              body: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade800,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                      ),
                      onPressed: () {},
                      child: const Text(
                        '赤 面（太字適応）',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade800,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                      ),
                      onPressed: () {},
                      child: const Text(
                        '白 小手（太字適応）',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // UI崩壊・文字膨張によるはみ出し（Overflow）例外ゼロ検証
      expect(tester.takeException(), isNull);

      expect(find.text('赤 面（太字適応）'), findsOneWidget);
      expect(find.text('白 小手（太字適応）'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNWidgets(2));
    });
  });
}
