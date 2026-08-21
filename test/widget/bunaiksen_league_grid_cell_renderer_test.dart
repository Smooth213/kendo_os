import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen_official_record/bunaiksen_league_grid_cell_renderer.dart';
import 'package:kendo_os/features/viewer/painters/league_table_painters.dart';

void main() {
  group('BunaiksenLeagueGridCellRenderer Tests', () {
    testWidgets('renders diagonal blank cell for same team', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) =>
                  BunaiksenLeagueGridCellRenderer.buildMatchCell(
                    context: context,
                    rowTeam: 'チームA',
                    colTeam: 'チームA',
                    normalMatches: [],
                    isIndiv: false,
                    isDark: false,
                    blankColor: Colors.grey,
                    borderColor: Colors.black,
                  ),
            ),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is DiagonalLinePainter,
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders match result cell correctly', (tester) async {
      final match = MatchModel(
        id: 'm1',
        tournamentId: 't1',
        redName: 'チームA:先鋒',
        whiteName: 'チームB:先鋒',
        matchType: '先鋒',
        redScore: 2,
        whiteScore: 0,
        status: 'finished',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) =>
                  BunaiksenLeagueGridCellRenderer.buildMatchCell(
                    context: context,
                    rowTeam: 'チームA',
                    colTeam: 'チームB',
                    normalMatches: [match],
                    isIndiv: false,
                    isDark: false,
                    blankColor: Colors.grey,
                    borderColor: Colors.black,
                  ),
            ),
          ),
        ),
      );

      expect(find.text('2'), findsOneWidget);
    });
  });
}
