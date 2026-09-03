import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('📸 【Phase 3-7/11】iPad Split View（1/3極小幅 320px）マルチタスク Goldenテスト', () {
    testWidgets('1. 横幅320pxの極小分割画面でもスコア・タイマーがoverflowせず美しく収まること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            appBar: AppBar(
              title: const Text(
                'Kendo OS - Split',
                style: TextStyle(fontSize: 16),
              ),
            ),
            body: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  // スコアボード極小表示
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text(
                          '佐藤 (赤)',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '1 - 0',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '鈴木 (白)',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text(
                      '残り 120 秒',
                      style: TextStyle(fontSize: 18, color: Colors.amber),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('1 - 0'), findsOneWidget);
      expect(find.text('残り 120 秒'), findsOneWidget);

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('../goldens/ipad_split_view_multitasking_golden.png'),
      );
    });
  });
}
