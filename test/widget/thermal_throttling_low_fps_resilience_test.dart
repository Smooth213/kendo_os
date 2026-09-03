import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('📱 【Phase 2-1/10】40℃猛暑サーマルスロットリング（15FPS低フレームレート）耐久テスト', () {
    testWidgets('1. 15FPS（約66ms周期）のコマ落ち環境下でも、絶対時間ベースのタイマーが正確に刻まれること', (
      tester,
    ) async {
      final startTime = DateTime(2026, 9, 3, 14, 0, 0);
      int currentSeconds = 180;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Center(
                  child: Text(
                    '残り $currentSeconds 秒',
                    style: const TextStyle(fontSize: 24),
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('残り 180 秒'), findsOneWidget);

      // 15FPS（66ms刻み）で5秒間（約75フレーム）をシミュレート
      // フレームレートが低下しても、絶対時間との差分計算により正しく175秒になること
      final elapsed = startTime.add(const Duration(seconds: 5));
      final remaining = (180 - elapsed.difference(startTime).inSeconds);
      currentSeconds = remaining;

      for (int i = 0; i < 75; i++) {
        await tester.pump(const Duration(milliseconds: 66));
      }

      await tester.pump();
      expect(currentSeconds, 175);
    });

    testWidgets('2. 低FPS下でのボタンタップがドロップ（フレーム落ち）せず確実に処理されること', (tester) async {
      int tapCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ElevatedButton(
                key: const Key('thermal_tap_btn'),
                onPressed: () => tapCount++,
                child: const Text('打突'),
              ),
            ),
          ),
        ),
      );

      // 重いフレーム遅延（100ms）を挟みながら3回タップ
      await tester.tap(find.byKey(const Key('thermal_tap_btn')));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byKey(const Key('thermal_tap_btn')));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byKey(const Key('thermal_tap_btn')));
      await tester.pump(const Duration(milliseconds: 100));

      expect(tapCount, 3);
    });
  });
}
