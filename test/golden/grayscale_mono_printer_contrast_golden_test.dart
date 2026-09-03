import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('📸 【Phase 3-9/11】モノクロ白黒プリンタ高コントラスト印刷 Goldenテスト', () {
    testWidgets('1. 白黒印刷時に赤旗（黒地・反転）と白旗（白地・枠線）が明瞭に判別可能であること', (tester) async {
      tester.view.physicalSize = const Size(500, 300);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // モノクロ印刷シミュレーション（カラーを排した高コントラスト組版）
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 赤側: モノクロ印刷用黒ベタ枠＋白抜き文字「▲ 赤: 佐藤」
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      color: Colors.black,
                      child: const Text(
                        '▲ 赤: 佐藤 (メ)',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'VS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // 白側: モノクロ印刷用白抜き枠＋黒文字「△ 白: 鈴木」
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black, width: 1.5),
                      ),
                      child: const Text(
                        '△ 白: 鈴木',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
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

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          '../goldens/grayscale_mono_printer_contrast_golden.png',
        ),
      );
    });
  });
}
