import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 水滴の誤認タップや手の震えによる超高速連打（50ms間隔の急峻なタップバースト）に対する
/// Mutex / Debounce 防護機構の検証テスト。
void main() {
  group('[Widget] 物理環境防護 - 水滴誤認・手の震えによる高速連打Mutex防護テスト', () {
    testWidgets('100ms以内に連続して発生した20回のタップが単一のアクションとして処理され多重実行されないこと', (
      tester,
    ) async {
      int actionCounter = 0;
      bool isProcessing = false;
      DateTime? lastActionTime;
      DateTime simulatedNow = DateTime(2026, 10, 2, 10, 0, 0);

      // 現場の防護付きボタン（Mutex / 300ms Debounce 実装）
      Future<void> handleTap() async {
        if (isProcessing) return;
        if (lastActionTime != null &&
            simulatedNow.difference(lastActionTime!) <
                const Duration(milliseconds: 300)) {
          return;
        }
        isProcessing = true;
        lastActionTime = simulatedNow;
        actionCounter++;
        await Future.delayed(const Duration(milliseconds: 50));
        isProcessing = false;
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ElevatedButton(
                key: const Key('protected_button'),
                onPressed: handleTap,
                child: const Text('一本確定'),
              ),
            ),
          ),
        ),
      );

      final buttonFinder = find.byKey(const Key('protected_button'));
      expect(buttonFinder, findsOneWidget);

      // 5msごとに20回の連打（水滴落下バーストシミュレーション、合計100ms）
      for (int i = 0; i < 20; i++) {
        await tester.tap(buttonFinder);
        simulatedNow = simulatedNow.add(const Duration(milliseconds: 5));
        await tester.pump(const Duration(milliseconds: 5));
      }

      await tester.pumpAndSettle();

      // 最初の1回のみが有効化され、後続19回はMutex/Debounceにより無効化されること
      expect(actionCounter, equals(1));
    });

    testWidgets('正規のインターバル（400ms以上）を空けたタップは正常に複数回受容されること', (tester) async {
      int actionCounter = 0;
      bool isProcessing = false;
      DateTime? lastActionTime;
      DateTime simulatedNow = DateTime(2026, 10, 2, 10, 0, 0);

      Future<void> handleTap() async {
        if (isProcessing) return;
        if (lastActionTime != null &&
            simulatedNow.difference(lastActionTime!) <
                const Duration(milliseconds: 300)) {
          return;
        }
        isProcessing = true;
        lastActionTime = simulatedNow;
        actionCounter++;
        isProcessing = false;
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ElevatedButton(
                key: const Key('protected_button_regular'),
                onPressed: handleTap,
                child: const Text('一本確定'),
              ),
            ),
          ),
        ),
      );

      final buttonFinder = find.byKey(const Key('protected_button_regular'));

      // 1回目の正当なタップ
      await tester.tap(buttonFinder);
      await tester.pump();

      // 400ms 時間進行
      simulatedNow = simulatedNow.add(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      // 2回目の正当なタップ
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      expect(actionCounter, equals(2));
    });
  });
}
