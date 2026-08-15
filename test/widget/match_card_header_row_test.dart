import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/cards/match_card_header_row.dart';

void main() {
  group('🛡️ MatchCardHeaderRow Widget Tests', () {
    testWidgets('Renders action buttons and status badge with spacer', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MatchCardHeaderRow(
              actionButtons: Text('ACTIONS'),
              statusBadge: Text('STATUS'),
            ),
          ),
        ),
      );

      expect(find.text('ACTIONS'), findsOneWidget);
      expect(find.text('STATUS'), findsOneWidget);
    });

    testWidgets('Renders leading widget when provided', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MatchCardHeaderRow(
              leading: Text('MATCH_NUM'),
              actionButtons: Text('ACTIONS'),
              statusBadge: Text('STATUS'),
            ),
          ),
        ),
      );

      expect(find.text('MATCH_NUM'), findsOneWidget);
      expect(find.text('ACTIONS'), findsOneWidget);
      expect(find.text('STATUS'), findsOneWidget);
    });
  });
}
