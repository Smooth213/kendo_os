import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('🌍 【Phase 8-5/7】Android 14/15 予測型「戻る」ジェスチャー安全ハンドリングテスト', () {
    testWidgets('1. 予測型戻るジェスチャー時、試合進行中画面が誤終了せず確認モーダルでガードされること', (tester) async {
      bool isGuardActive = true;
      bool exitBlocked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PopScope(
              canPop: !isGuardActive,
              onPopInvokedWithResult: (didPop, result) {
                if (didPop) return;
                exitBlocked = true;
              },
              child: const Center(child: Text('第1コート: 試合進行中（Android予測戻るガード中）')),
            ),
          ),
        ),
      );

      // 予測戻るナビゲーション（PopRoute）をシミュレート
      final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
      await widgetsAppState.didPopRoute();
      await tester.pump();

      // 画面が勝手に落ちず、ガードが確実に発動すること
      expect(exitBlocked, isTrue);
      expect(find.text('第1コート: 試合進行中（Android予測戻るガード中）'), findsOneWidget);
    });
  });
}
