import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// 🥋 外付けHIDデバイス（フットスイッチ・テンキー）チャタリング防止ガード
class HidChatteringGuard {
  static const int debounceThresholdMs = 300;
  final Map<LogicalKeyboardKey, int> _lastKeyPressTimes = {};

  bool shouldProcess(LogicalKeyboardKey key, int eventTimeMs) {
    final lastTime = _lastKeyPressTimes[key] ?? 0;
    if (eventTimeMs - lastTime < debounceThresholdMs) {
      return false; // チャタリング・連打暴走遮断
    }
    _lastKeyPressTimes[key] = eventTimeMs;
    return true;
  }
}

void main() {
  group('📱 【Phase 2-5/10】Bluetooth HID フットスイッチ チャタリング暴走防止テスト', () {
    test('1. フットスイッチ接点不良による10ms間隔の連続5回バウンス入力を1回に抑止すること', () {
      final guard = HidChatteringGuard();
      const key = LogicalKeyboardKey.keyM; // 'M' = 面

      int processedCount = 0;
      int baseTime = 1000;

      // 10ms間隔で5回連続チャタリング入力
      for (int i = 0; i < 5; i++) {
        if (guard.shouldProcess(key, baseTime + (i * 10))) {
          processedCount++;
        }
      }

      // 最初の1回のみ処理され、残りの4回は確実にブロックされること
      expect(processedCount, 1);
    });

    test('2. 正常なインターバル（500ms後）の意図的入力は正常に受領されること', () {
      final guard = HidChatteringGuard();
      const key = LogicalKeyboardKey.space; // スペース = 時計トグル

      expect(guard.shouldProcess(key, 1000), isTrue); // 1回目
      expect(guard.shouldProcess(key, 1050), isFalse); // 50ms後（チャタリング遮断）
      expect(guard.shouldProcess(key, 1500), isTrue); // 500ms後（正当な再操作）
    });

    testWidgets(
      '3. RawKeyboardListener / KeyboardListener でのハードウェアキー入力防衛Widgetテスト',
      (tester) async {
        int scoreRecorded = 0;
        final guard = HidChatteringGuard();
        int simulatedTime = 1000;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Focus(
                autofocus: true,
                onKeyEvent: (node, event) {
                  if (event is KeyDownEvent &&
                      event.logicalKey == LogicalKeyboardKey.keyM) {
                    if (guard.shouldProcess(event.logicalKey, simulatedTime)) {
                      scoreRecorded++;
                    }
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: const Text('HID試合画面'),
              ),
            ),
          ),
        );

        // 1回目のキー押下
        simulatedTime = 1000;
        await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
        await tester.pump();
        expect(scoreRecorded, 1);

        // チャタリング発生（50ms後の偽入力）
        simulatedTime = 1050;
        await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
        await tester.pump();
        expect(scoreRecorded, 1); // 増えていないこと！
      },
    );
  });
}
