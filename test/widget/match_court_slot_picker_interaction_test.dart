import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/common/match_court_slot_picker.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/common/match_heading_format_helper.dart';

void main() {
  group('[Widget] MatchCourtSlotPicker Interaction Test', () {
    testWidgets('未設定状態から＋押下で1になり、テンキー入力後に＋ーで増減できること', (
      WidgetTester tester,
    ) async {
      final courtController = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListenableBuilder(
              listenable: courtController,
              builder: (context, _) {
                final courtNumber = MatchHeadingFormatHelper.extractCourtNumber(
                  courtController.text,
                );
                final matchOrder = MatchHeadingFormatHelper.extractMatchOrder(
                  courtController.text,
                );

                return MatchCourtSlotPicker(
                  courtNumber: courtNumber,
                  matchOrder: matchOrder,
                  isDark: false,
                  onCourtNumberChanged: (newCourt) {
                    courtController.text =
                        MatchHeadingFormatHelper.updateHeading(
                          currentText: courtController.text,
                          courtNumber: newCourt,
                          matchOrder: matchOrder,
                        );
                  },
                  onMatchOrderChanged: (newOrder) {
                    courtController.text =
                        MatchHeadingFormatHelper.updateHeading(
                          currentText: courtController.text,
                          courtNumber: courtNumber,
                          matchOrder: newOrder,
                        );
                  },
                );
              },
            ),
          ),
        ),
      );

      // 1. 最初は未設定
      expect(find.text('未設定'), findsNWidgets(2)); // 試合場・試合順の2つ
      expect(courtController.text, '');

      // 2. 試合場の［＋］を押す
      final addButtons = find.byIcon(Icons.add);
      await tester.tap(addButtons.first);
      await tester.pumpAndSettle();

      // 試合場が 1 になること
      expect(find.text('1'), findsOneWidget);
      expect(find.text('第1試合場'), findsOneWidget);
      expect(courtController.text, '第1試合場');

      // 3. もう一度［＋］を押すと 2 になること
      await tester.tap(addButtons.first);
      await tester.pumpAndSettle();
      expect(find.text('2'), findsOneWidget);
      expect(find.text('第2試合場'), findsOneWidget);
      expect(courtController.text, '第2試合場');

      // 4. ［－］を押すと 1 に戻ること
      final removeButtons = find.byIcon(Icons.remove);
      await tester.tap(removeButtons.first);
      await tester.pumpAndSettle();
      expect(find.text('1'), findsOneWidget);
      expect(find.text('第1試合場'), findsOneWidget);
      expect(courtController.text, '第1試合場');

      // 5. 中央の数字（1）をタップしてテンキーダイアログを開く
      await tester.tap(find.text('1'));
      await tester.pumpAndSettle();

      // ダイアログが開いたことを確認
      expect(find.text('試合場番号を入力'), findsOneWidget);
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      // 「15」を入力して「決定」をタップ
      await tester.enterText(textField, '15');
      await tester.pumpAndSettle();
      await tester.tap(find.text('決定'));
      await tester.pumpAndSettle();

      // 6. 15 が反映されていること
      expect(find.text('15'), findsOneWidget);
      expect(find.text('第15試合場'), findsOneWidget);
      expect(courtController.text, '第15試合場');

      // 7. その後［＋］を押して 16 に増やせること
      await tester.tap(addButtons.first);
      await tester.pumpAndSettle();
      expect(find.text('16'), findsOneWidget);
      expect(find.text('第16試合場'), findsOneWidget);
      expect(courtController.text, '第16試合場');

      // 8. その後［－］を押して 15 に減らせること
      await tester.tap(removeButtons.first);
      await tester.pumpAndSettle();
      expect(find.text('15'), findsOneWidget);
      expect(find.text('第15試合場'), findsOneWidget);
      expect(courtController.text, '第15試合場');
    });
  });
}
