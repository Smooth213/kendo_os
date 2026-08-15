import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_time_stepper_tile.dart';

void main() {
  group('🛡️ CategoryTimeStepperTile Widget Tests', () {
    testWidgets('Renders time stepper tile with title and formatted minutes', (
      WidgetTester tester,
    ) async {
      double currentTime = 3.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return CategoryTimeStepperTile(
                  title: '試合時間',
                  subtitle: '1試合の標準時間',
                  value: currentTime,
                  minValue: 1.0,
                  maxValue: 10.0,
                  step: 0.5,
                  onChanged: (val) {
                    setState(() {
                      currentTime = val;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('試合時間'), findsOneWidget);
      expect(find.text('1試合の標準時間'), findsOneWidget);
      expect(find.text('3分'), findsOneWidget);

      // Increment button tap
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(currentTime, 3.5);
      expect(find.text('3分30秒'), findsOneWidget);
    });
  });
}
