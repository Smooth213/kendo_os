import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/services/team_match_calculator.dart';
import 'package:kendo_os/features/viewer/components/viewer_team_scoreboard_table_builder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🛡️ ViewerTeamScoreboard Extracted Components Tests', () {
    testWidgets('1. ViewerTeamScoreboardTableBuilder builds rows correctly', (
      tester,
    ) async {
      final headerRow = ViewerTeamScoreboardTableBuilder.buildHeaderRow(
        '赤チーム',
        '白チーム',
        false,
      );
      final totalRow = ViewerTeamScoreboardTableBuilder.buildTotalRow(
        TeamMatchResult(
          redPoints: 4,
          whitePoints: 1,
          redWins: 2,
          whiteWins: 1,
          allFinished: true,
          hasDaihyo: false,
          isTie: false,
          teamWinner: 'red',
        ),
        false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Table(children: [headerRow, totalRow])),
        ),
      );

      expect(find.text('赤チーム'), findsOneWidget);
      expect(find.text('白チーム'), findsOneWidget);
      expect(find.text('2 / 4'), findsOneWidget);
      expect(find.text('1 / 1'), findsOneWidget);
    });
  });
}
