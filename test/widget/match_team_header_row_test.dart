import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/cards/match_team_header_row.dart';

void main() {
  group('🛡️ MatchTeamHeaderRow Widget Tests', () {
    testWidgets('Renders team names correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MatchTeamHeaderRow(
              redTeam: '道上剣友会',
              whiteTeam: '相手道場',
              textColor: Colors.grey,
            ),
          ),
        ),
      );

      expect(find.text('道上剣友会'), findsOneWidget);
      expect(find.text('相手道場'), findsOneWidget);
    });

    testWidgets('Renders fallback label when team name is empty', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MatchTeamHeaderRow(
              redTeam: '',
              whiteTeam: '',
              textColor: Colors.grey,
            ),
          ),
        ),
      );

      expect(find.text('（個人エントリー）'), findsNWidgets(2));
    });
  });
}
