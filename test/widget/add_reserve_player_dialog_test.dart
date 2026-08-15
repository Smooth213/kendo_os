import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/dialogs/add_reserve_player_dialog.dart';

void main() {
  group('🛡️ AddReservePlayerDialog Widget Tests', () {
    testWidgets(
      'Renders available players list and select returns player name',
      (WidgetTester tester) async {
        String? selectedName;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    selectedName = await showDialog<String>(
                      context: context,
                      builder: (ctx) => const AddReservePlayerDialog(
                        availablePlayers: ['佐藤', '鈴木', '高橋'],
                      ),
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

        expect(find.text('控え選手の追加'), findsOneWidget);
        expect(find.text('佐藤'), findsOneWidget);
        expect(find.text('鈴木'), findsOneWidget);

        await tester.tap(find.text('鈴木'));
        await tester.pumpAndSettle();

        expect(selectedName, equals('鈴木'));
      },
    );

    testWidgets('Manual input textfield adds helper player', (
      WidgetTester tester,
    ) async {
      String? selectedName;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  selectedName = await showDialog<String>(
                    context: context,
                    builder: (ctx) =>
                        const AddReservePlayerDialog(availablePlayers: []),
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

      expect(find.text('未出場の所属選手はいません。'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '助っ人 田中');
      await tester.tap(find.text('追加'));
      await tester.pumpAndSettle();

      expect(selectedName, equals('助っ人 田中'));
    });
  });
}
