import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/viewer/components/viewer_vertical_player_name_cell.dart';

void main() {
  group('🛡️ ViewerVerticalPlayerNameCell Widget Tests', () {
    testWidgets('Renders simple vertical text characters', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: ViewerVerticalPlayerNameCell(text: '山田', isDark: false),
            ),
          ),
        ),
      );

      expect(find.text('山'), findsOneWidget);
      expect(find.text('田'), findsOneWidget);
    });

    testWidgets('Renders RotatedBox for hyphen and brackets, with initial', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: ViewerVerticalPlayerNameCell(
                text: 'リーダー(A)',
                initial: 'Y',
                isDark: true,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(RotatedBox), findsWidgets);
      expect(find.text('Y'), findsOneWidget);
    });
  });
}
