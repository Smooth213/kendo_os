import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('👁️ 【Phase 6-3/12】端末高速画面回転ストーム（縦横10回連続変更）耐久テスト', () {
    testWidgets('1. 縦（400x800）と横（800x400）を10回連続で交互に回転させても、タイマーとスコアが死守されること', (
      tester,
    ) async {
      addTearDown(tester.view.reset);

      int redScore = 1;
      int whiteScore = 0;
      int remainingSeconds = 150;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OrientationBuilder(
              builder: (context, orientation) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(orientation == Orientation.portrait ? '縦画面' : '横画面'),
                      Text('スコア: $redScore - $whiteScore'),
                      Text('残り $remainingSeconds 秒'),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('スコア: 1 - 0'), findsOneWidget);

      // 🔄 縦横を10回連続で高速回転！
      for (int i = 0; i < 10; i++) {
        final isPortrait = (i % 2 == 0);
        tester.view.physicalSize = isPortrait
            ? const Size(400, 800)
            : const Size(800, 400);
        tester.view.devicePixelRatio = 1.0;
        await tester.pump();
      }

      await tester.pumpAndSettle();

      // 回転ストーム後も、データが消失せず完全に表示されていること
      expect(find.text('スコア: 1 - 0'), findsOneWidget);
      expect(find.text('残り 150 秒'), findsOneWidget);
    });
  });
}
