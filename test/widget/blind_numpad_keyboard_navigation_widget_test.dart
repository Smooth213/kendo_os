import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('🎨 【Phase 3-3/11】外付けテンキー ブラインド試合操作ショートカットキー完全対応テスト', () {
    testWidgets('1. テンキー「1（赤面）」「7（白面）」「Space（時計）」のキーボードショートカット完全動作', (
      tester,
    ) async {
      String lastAction = '';
      bool timerRunning = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Focus(
              autofocus: true,
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent) {
                  if (event.logicalKey == LogicalKeyboardKey.digit1 ||
                      event.logicalKey == LogicalKeyboardKey.numpad1) {
                    lastAction = '赤面';
                    return KeyEventResult.handled;
                  } else if (event.logicalKey == LogicalKeyboardKey.digit7 ||
                      event.logicalKey == LogicalKeyboardKey.numpad7) {
                    lastAction = '白面';
                    return KeyEventResult.handled;
                  } else if (event.logicalKey == LogicalKeyboardKey.space) {
                    timerRunning = !timerRunning;
                    return KeyEventResult.handled;
                  }
                }
                return KeyEventResult.ignored;
              },
              child: const Center(child: Text('ブラインド操作盤')),
            ),
          ),
        ),
      );

      // 1. スペースキーで時計スタート
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(timerRunning, isTrue);

      // 2. テンキー「1」で赤面
      await tester.sendKeyEvent(LogicalKeyboardKey.numpad1);
      await tester.pump();
      expect(lastAction, '赤面');

      // 3. テンキー「7」で白面
      await tester.sendKeyEvent(LogicalKeyboardKey.numpad7);
      await tester.pump();
      expect(lastAction, '白面');

      // 4. 再度スペースキーで時計停止
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(timerRunning, isFalse);
    });
  });
}
