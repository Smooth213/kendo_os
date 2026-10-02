import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/widgets/action_buttons.dart';

void main() {
  group('[Widget] 長押し確定ボタンのドラッグ逸脱誤操作防止テスト', () {
    testWidgets('長押し中に指をボタン領域外へドラッグ移動して離した場合に確定処理が発火せずキャンセルされること', (
      WidgetTester tester,
    ) async {
      bool isConfirmed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 120,
                height: 80,
                child: HoldConfirmButton(
                  label: '確定',
                  color: Colors.red,
                  textColor: Colors.white,
                  disabled: false,
                  onConfirm: () {
                    isConfirmed = true;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      final buttonFinder = find.byType(HoldConfirmButton);
      expect(buttonFinder, findsOneWidget);

      // ボタン中央でタッチ開始（長押し開始）
      final gesture = await tester.startGesture(tester.getCenter(buttonFinder));
      await tester.pump(const Duration(milliseconds: 150));

      // 長押しインジケータ（プログレス）が表示されていることを確認
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // ボタンの領域外（大幅に下方向へ500px移動）へドラッグ移動
      await gesture.moveTo(
        tester.getCenter(buttonFinder) + const Offset(0, 500),
      );
      await tester.pump(const Duration(milliseconds: 250));

      // 領域外で指を離す
      await gesture.up();
      await tester.pumpAndSettle();

      // 領域外逸脱によりキャンセルされ、確定コールバックは発火していないこと
      expect(isConfirmed, isFalse);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('長押し完了時間まで領域内で保持し続けた場合は確定処理が正常に発火すること', (
      WidgetTester tester,
    ) async {
      bool isConfirmed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 120,
                height: 80,
                child: HoldConfirmButton(
                  label: '確定',
                  color: Colors.red,
                  textColor: Colors.white,
                  disabled: false,
                  onConfirm: () {
                    isConfirmed = true;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      final buttonFinder = find.byType(HoldConfirmButton);

      // タッチ開始
      final gesture = await tester.startGesture(tester.getCenter(buttonFinder));
      await tester.pump(); // ジェスチャーを認識させてアニメーションを開始
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(); // Listenerの処理（onConfirm）を反映

      expect(isConfirmed, isTrue);

      await gesture.up();
      await tester.pumpAndSettle();
    });
  });
}
