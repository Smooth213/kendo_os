import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('🌐 【Phase 4-1/11】ブラウザ「戻る」ボタン誤押下 PopScope 画面離脱阻止テスト', () {
    testWidgets('1. 試合進行中にブラウザの戻る操作が起きても PopScope が離脱を阻止すること', (tester) async {
      bool confirmDialogShown = false;
      bool isMatchInProgress = true;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PopScope(
              canPop: !isMatchInProgress,
              onPopInvokedWithResult: (didPop, result) {
                if (didPop) return;
                confirmDialogShown = true;
              },
              child: const Center(child: Text('第1コート 試合進行中')),
            ),
          ),
        ),
      );

      expect(find.text('第1コート 試合進行中'), findsOneWidget);

      // ブラウザの戻るボタン（PopRoute）をシミュレート
      final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
      await widgetsAppState.didPopRoute();
      await tester.pump();

      // 画面が閉じず、確認ダイアログのトリガーが引かれたこと
      expect(confirmDialogShown, isTrue);
      expect(find.text('第1コート 試合進行中'), findsOneWidget);
    });

    testWidgets('2. 試合終了後（isMatchInProgress: false）は安全に戻ることができること', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          initialRoute: '/',
          routes: {
            '/': (context) => Scaffold(
              body: ElevatedButton(
                key: const Key('go_match_btn'),
                onPressed: () => Navigator.pushNamed(context, '/match'),
                child: const Text('試合画面へ'),
              ),
            ),
            '/match': (context) => const Scaffold(
              body: PopScope(
                canPop: true, // 試合終了後は離脱許可
                child: Text('試合終了・結果確定'),
              ),
            ),
          },
        ),
      );

      // 試合画面へ遷移
      await tester.tap(find.byKey(const Key('go_match_btn')));
      await tester.pumpAndSettle();
      expect(find.text('試合終了・結果確定'), findsOneWidget);

      // 戻る操作を実行
      final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
      await widgetsAppState.didPopRoute();
      await tester.pumpAndSettle();

      // 前の画面へ安全に戻れていること
      expect(find.text('試合画面へ'), findsOneWidget);
    });
  });
}
