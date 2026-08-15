import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_option_card.dart';

void main() {
  group('🛡️ MatchFormatOptionCard & SetupReadOnlyRuleRow Widget Tests', () {
    testWidgets('Renders MatchFormatOptionCard with title, icon, and child', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MatchFormatOptionCard(
              title: '試合形式設定',
              icon: Icons.sports_kabaddi,
              color: Colors.blue,
              child: Text('5人制団体戦'),
            ),
          ),
        ),
      );

      expect(find.text('試合形式設定'), findsOneWidget);
      expect(find.byIcon(Icons.sports_kabaddi), findsOneWidget);
      expect(find.text('5人制団体戦'), findsOneWidget);
    });

    testWidgets('Renders SetupReadOnlyRuleRow with label and value', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SetupReadOnlyRuleRow(label: '試合時間', value: '3分'),
          ),
        ),
      );

      expect(find.text('試合時間'), findsOneWidget);
      expect(find.text('3分'), findsOneWidget);
    });
  });
}
