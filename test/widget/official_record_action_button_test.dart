import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/viewer/components/official_record_action_button.dart';

void main() {
  group('🛡️ OfficialRecordActionButton Widget Tests', () {
    testWidgets('Renders icon and label, triggers onTap callback', (
      WidgetTester tester,
    ) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OfficialRecordActionButton(
              icon: Icons.picture_as_pdf,
              label: 'PDF出力',
              color: Colors.red,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('PDF出力'), findsOneWidget);
      expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);

      await tester.tap(find.byType(OfficialRecordActionButton));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });
}
