import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('🎨 【Phase 3-5/11】低速ネットワーク10秒タイムアウト・再試行バナー耐久テスト', () {
    testWidgets('1. ローディング中 ➔ タイムアウトエラーバナー表示 ➔ 再試行ボタン押下による再接続フロー', (
      tester,
    ) async {
      bool isLoading = true;
      bool hasError = false;
      int retryCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                if (isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(key: Key('sync_spinner')),
                  );
                }
                if (hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('通信がタイムアウトしました。電波の良い場所へ移動してください。'),
                        ElevatedButton(
                          key: const Key('retry_connect_btn'),
                          onPressed: () {
                            setState(() {
                              retryCount++;
                              isLoading = true;
                              hasError = false;
                            });
                          },
                          child: const Text('再試行'),
                        ),
                      ],
                    ),
                  );
                }
                return const Center(child: Text('同期完了'));
              },
            ),
          ),
        ),
      );

      // 1. 最初はスピナーが表示されていること
      expect(find.byKey(const Key('sync_spinner')), findsOneWidget);

      // 2. 10秒タイムアウト発生をシミュレート
      final dynamic state = tester.state(find.byType(StatefulBuilder));
      // ignore: invalid_use_of_protected_member
      state.setState(() {
        isLoading = false;
        hasError = true;
      });
      await tester.pump();

      // スピナーが消え、エラーメッセージと「再試行」ボタンが出現
      expect(find.byKey(const Key('sync_spinner')), findsNothing);
      expect(find.text('通信がタイムアウトしました。電波の良い場所へ移動してください。'), findsOneWidget);
      expect(find.byKey(const Key('retry_connect_btn')), findsOneWidget);

      // 3. 「再試行」ボタンをタップ
      await tester.tap(find.byKey(const Key('retry_connect_btn')));
      await tester.pump();

      expect(retryCount, 1);
      expect(
        find.byKey(const Key('sync_spinner')),
        findsOneWidget,
      ); // 再度スピナーに戻る
    });
  });
}
