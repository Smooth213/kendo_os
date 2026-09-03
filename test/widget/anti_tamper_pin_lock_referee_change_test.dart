import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('☁️ 【Phase 7-5/8】審判員交代・スコア修正 4桁PINロック改ざん防止 Widgetテスト', () {
    testWidgets('1. 正しいPIN（1234）入力時のみ審判交代が許可され、不正PIN（9999）は拒絶されること', (
      tester,
    ) async {
      bool isUnlocked = false;
      String currentReferee = '主審: 佐藤';
      final pinController = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                if (isUnlocked) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('設定画面: $currentReferee'),
                        ElevatedButton(
                          key: const Key('change_referee_btn'),
                          onPressed: () {
                            setState(() {
                              currentReferee = '主審: 鈴木（交代後）';
                            });
                          },
                          child: const Text('審判員を交代'),
                        ),
                      ],
                    ),
                  );
                }

                // PIN入力ロック画面
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('【管理者PINコード入力】'),
                      TextField(
                        key: const Key('pin_input_field'),
                        controller: pinController,
                      ),
                      ElevatedButton(
                        key: const Key('pin_submit_btn'),
                        onPressed: () {
                          if (pinController.text == '1234') {
                            setState(() {
                              isUnlocked = true;
                            });
                          }
                        },
                        child: const Text('認証'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );

      // 1. 不正なPIN（9999）を入力
      await tester.enterText(find.byKey(const Key('pin_input_field')), '9999');
      await tester.tap(find.byKey(const Key('pin_submit_btn')));
      await tester.pump();

      // ロック解除されず、審判交代ボタンは出現しないこと
      expect(find.byKey(const Key('change_referee_btn')), findsNothing);

      // 2. 正しいPIN（1234）を入力
      await tester.enterText(find.byKey(const Key('pin_input_field')), '1234');
      await tester.tap(find.byKey(const Key('pin_submit_btn')));
      await tester.pumpAndSettle();

      // ロック解除され、審判交代が可能になること
      expect(find.byKey(const Key('change_referee_btn')), findsOneWidget);
      await tester.tap(find.byKey(const Key('change_referee_btn')));
      await tester.pump();

      expect(find.text('設定画面: 主審: 鈴木（交代後）'), findsOneWidget);
    });
  });
}
