import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen/bunaiksen_custom_time_dialog.dart';

void main() {
  group('🛡️ BunaiksenCustomTimeDialog Widget Tests', () {
    testWidgets('Renders minute and second text fields with initial values', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => BunaiksenCustomTimeDialog.show(
                  context,
                  currentTime: 2.5, // 2分30秒
                  isDark: false,
                  primaryAccent: Colors.blue,
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('任意の試合時間'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
      expect(find.text('キャンセル'), findsOneWidget);
      expect(find.text('設定する'), findsOneWidget);
    });

    testWidgets('Updates value and returns computed total minutes on submit', (
      WidgetTester tester,
    ) async {
      double? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await BunaiksenCustomTimeDialog.show(
                    context,
                    currentTime: 1.0,
                    isDark: true,
                    primaryAccent: Colors.deepPurple,
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // 分フィールドを 3 に変更
      final minField = find.widgetWithText(TextField, '1');
      await tester.enterText(minField, '3');

      // 秒フィールドを 45 に変更
      final secField = find.widgetWithText(TextField, '0');
      await tester.enterText(secField, '45');

      await tester.tap(find.text('設定する'));
      await tester.pumpAndSettle();

      // 3分 + 45/60分 = 3.75
      expect(result, equals(3.75));
    });
  });
}
