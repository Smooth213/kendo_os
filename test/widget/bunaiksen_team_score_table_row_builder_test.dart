import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen_official_record/bunaiksen_team_score_table_row_builder.dart';

void main() {
  group('BunaiksenTeamScoreTableRowBuilder Tests', () {
    testWidgets('renders teamResultCell correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BunaiksenTeamScoreTableRowBuilder.teamResultCell(
              'red',
              false,
              true,
            ),
          ),
        ),
      );

      expect(find.text('勝'), findsOneWidget);
      expect(find.text('負'), findsOneWidget);
    });

    testWidgets('renders summaryCell correctly', (tester) async {
      final match = MatchModel(
        id: 'm1',
        tournamentId: 't1',
        redName: 'A',
        whiteName: 'B',
        matchType: '先鋒',
        redScore: 2,
        whiteScore: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BunaiksenTeamScoreTableRowBuilder.summaryCell(
              [match],
              true,
              false,
            ),
          ),
        ),
      );

      expect(find.text('2\n--\n1'), findsOneWidget);
    });
  });
}
