import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Webブラウザ環境でユーザーがブラウザの「戻る」ボタン（History Back）やエスケープキーを押下した際、
/// 階層的に開かれたダイアログが破綻せず、LIFO（Last In First Out）順に安全にクローズされることのE2Eテスト。
void main() {
  group('[E2E] Webブラウザ極限 - ブラウザ履歴戻る/ダイアログスタック安全制御テスト', () {
    testWidgets('多重モーダルが開かれた状態でポップ操作が実行された際、最前面のダイアログから順に閉じること', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                key: const Key('open_dialog_1'),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx1) => AlertDialog(
                      title: const Text('ダイアログ1（勝敗確認）'),
                      actions: [
                        ElevatedButton(
                          key: const Key('open_dialog_2'),
                          onPressed: () {
                            showDialog(
                              context: ctx1,
                              builder: (ctx2) => const AlertDialog(
                                title: Text('ダイアログ2（反則警告詳細）'),
                              ),
                            );
                          },
                          child: const Text('詳細表示'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('第1ダイアログ起動'),
              ),
            ),
          ),
        ),
      );

      // 初期状態
      expect(find.text('第1ダイアログ起動'), findsOneWidget);

      // ダイアログ1を開く
      await tester.tap(find.byKey(const Key('open_dialog_1')));
      await tester.pumpAndSettle();
      expect(find.text('ダイアログ1（勝敗確認）'), findsOneWidget);

      // ダイアログ2を開く（多重スタック）
      await tester.tap(find.byKey(const Key('open_dialog_2')));
      await tester.pumpAndSettle();
      expect(find.text('ダイアログ2（反則警告詳細）'), findsOneWidget);
      expect(find.text('ダイアログ1（勝敗確認）'), findsOneWidget);

      // 1回目の「戻る」ナビゲーション（Pop）
      final navigatorState = tester.state<NavigatorState>(
        find.byType(Navigator),
      );
      navigatorState.pop();
      await tester.pumpAndSettle();

      // 最前面のダイアログ2のみが閉じ、ダイアログ1は保持されていること
      expect(find.text('ダイアログ2（反則警告詳細）'), findsNothing);
      expect(find.text('ダイアログ1（勝敗確認）'), findsOneWidget);

      // 2回目の「戻る」ナビゲーション（Pop）
      navigatorState.pop();
      await tester.pumpAndSettle();

      // ダイアログ1も閉じ、親画面のみが残ること
      expect(find.text('ダイアログ1（勝敗確認）'), findsNothing);
      expect(find.text('第1ダイアログ起動'), findsOneWidget);
    });
  });
}
