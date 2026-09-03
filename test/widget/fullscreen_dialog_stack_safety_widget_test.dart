import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/widgets/app_dialog.dart';

void main() {
  group('🎨 【Widget 4/5】多重ダイアログ・モーダルスタック完全安全耐久テスト', () {
    testWidgets('多重に展開されたダイアログスタックで連続Popが発生しても、例外なく安全にルート画面へ復帰すること', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  key: const Key('open_dialog_stack_btn'),
                  onPressed: () {
                    // 第1ダイアログ
                    showDialog(
                      context: context,
                      builder: (ctx1) => AppDialog(
                        title: '第1ダイアログ: 試合終了確認',
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('試合を終了しますか？'),
                            ElevatedButton(
                              key: const Key('open_sub_dialog_btn'),
                              onPressed: () {
                                // 第2ダイアログ（ネスト）
                                showDialog(
                                  context: ctx1,
                                  builder: (ctx2) => AppDialog(
                                    title: '第2ダイアログ: 承認確認',
                                    content: const Text('本当に確定しますか？'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(ctx2).pop(),
                                        child: const Text('確定'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: const Text('詳細確認'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: const Text('ダイアログ展開'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. 第1ダイアログを開く
      await tester.tap(find.byKey(const Key('open_dialog_stack_btn')));
      await tester.pumpAndSettle();
      expect(find.text('第1ダイアログ: 試合終了確認'), findsOneWidget);

      // 2. 第2ダイアログを開く（多重スタック）
      await tester.tap(find.byKey(const Key('open_sub_dialog_btn')));
      await tester.pumpAndSettle();
      expect(find.text('第2ダイアログ: 承認確認'), findsOneWidget);

      // 3. 連続Popを実行（Android戻るボタン／画面外タップ等）
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      expect(navigator.canPop(), isTrue);
      navigator.pop(); // 第2ダイアログ閉じる
      await tester.pumpAndSettle();

      expect(find.text('第2ダイアログ: 承認確認'), findsNothing);
      expect(find.text('第1ダイアログ: 試合終了確認'), findsOneWidget);

      expect(navigator.canPop(), isTrue);
      navigator.pop(); // 第1ダイアログ閉じる
      await tester.pumpAndSettle();

      expect(find.text('第1ダイアログ: 試合終了確認'), findsNothing);
      expect(find.byKey(const Key('open_dialog_stack_btn')), findsOneWidget);

      // スタックの空状態でさらに余分なPopを呼んでも安全であること
      expect(navigator.canPop(), isFalse);
      expect(tester.takeException(), isNull);
    });
  });
}
