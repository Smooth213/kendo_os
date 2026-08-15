import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/viewer/components/viewer_point_box_cell.dart';

void main() {
  group('🛡️ ViewerPointBoxCell & OfficialTechMarkBadge Widget Tests', () {
    testWidgets('Renders simple tech marks and first point circled badge', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                OfficialTechMarkBadge(
                  point: OfficialPointDisplay('メ', true),
                  color: Colors.red,
                ),
                OfficialTechMarkBadge(
                  point: OfficialPointDisplay('コ', false),
                  color: Colors.blue,
                ),
                OfficialTechMarkBadge(
                  point: OfficialPointDisplay('判定', false),
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('メ'), findsOneWidget);
      expect(find.text('コ'), findsOneWidget);
      expect(find.text('判'), findsOneWidget);
    });

    testWidgets(
      'Renders ViewerPointBoxCell with winner highlight and 2 points',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ViewerPointBoxCell(
                pts: [
                  OfficialPointDisplay('メ', false),
                  OfficialPointDisplay('ド', false),
                ],
                isWinner: true,
                isRed: true,
                isDark: false,
              ),
            ),
          ),
        );

        expect(find.text('メ'), findsOneWidget);
        expect(find.text('ド'), findsOneWidget);
        expect(find.byType(ViewerPointBoxCell), findsOneWidget);
      },
    );
  });
}
