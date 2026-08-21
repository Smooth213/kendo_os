import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen_official_record/bunaiksen_league_grid_table.dart';

void main() {
  testWidgets('BunaiksenLeagueGridTable renders league table grid headers', (
    WidgetTester tester,
  ) async {
    final matches = [
      MatchModel(
        id: 'm1',
        tournamentId: 't1',
        matchType: 'team',
        redName: 'RedTeam',
        whiteName: 'WhiteTeam',
        status: 'finished',
        redScore: 2,
        whiteScore: 1,
        order: 1,
        rule: const MatchRule(isLeague: true),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: BunaiksenLeagueGridTable(
              groupName: 'Aパート',
              matches: matches,
              isDark: false,
            ),
          ),
        ),
      ),
    );

    // Verify stats header cells
    expect(find.text('勝数'), findsOneWidget);
    expect(find.text('勝者'), findsOneWidget);
    expect(find.text('本数'), findsOneWidget);
    expect(find.text('順位'), findsOneWidget);
  });
}
