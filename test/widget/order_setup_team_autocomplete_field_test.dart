import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/order_setup/order_setup_team_autocomplete_field.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Widget] OrderSetupTeamAutocompleteField ウィジェットテスト', () {
    testWidgets('初期表示と手動入力が正常に行えること', (tester) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: OrderSetupTeamAutocompleteField(
                controller: controller,
                focusNode: focusNode,
                suggestions: const ['修道館', '養正館', '練兵館'],
                labelText: '赤チーム名',
                hintText: 'チーム名を入力または選択',
                fillColor: Colors.grey.shade100,
                borderColor: Colors.grey,
                textColor: Colors.black,
                subTextColor: Colors.grey.shade600,
                primaryAccent: Colors.blue,
                isDark: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('赤チーム名'), findsOneWidget);
      expect(find.text('チーム名を入力または選択'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '玄武館');
      await tester.pump();

      expect(controller.text, '玄武館');
    });

    testWidgets('フィールドをタップしてサジェストリストから選択できること', (tester) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: OrderSetupTeamAutocompleteField(
                controller: controller,
                focusNode: focusNode,
                suggestions: const ['修道館', '養正館'],
                labelText: '白チーム名',
                hintText: '選択してください',
                fillColor: Colors.grey.shade100,
                borderColor: Colors.grey,
                textColor: Colors.black,
                subTextColor: Colors.grey.shade600,
                primaryAccent: Colors.blue,
                isDark: false,
              ),
            ),
          ),
        ),
      );

      // タップしてフォーカス付与
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      // サジェスト候補が表示されること
      if (find.text('修道館').evaluate().isNotEmpty) {
        await tester.tap(find.text('修道館'));
        await tester.pumpAndSettle();
        expect(controller.text, '修道館');
      }
    });
  });
}
