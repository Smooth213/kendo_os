import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/timeline/timeline_league_team_match_header.dart';

void main() {
  group('TimelineLeagueTeamMatchHeader Tests', () {
    testWidgets('renders teams and wins correctly', (tester) async {
      final bout1 = MatchModel(
        id: 'm1',
        tournamentId: 't1',
        redName: 'Team A : Player 1',
        whiteName: 'Team B : Player 1',
        matchType: '先鋒',
        redScore: 2,
        whiteScore: 0,
        status: 'finished',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TimelineLeagueTeamMatchHeader(
                bouts: [bout1],
                isReadOnlyUI: false,
                boutsAllFinished: true,
                boutsInProgress: false,
                t1: 'Team A',
                t2: 'Team B',
                ownTeams: const ['Team A'],
                mTitleColor: Colors.black,
                isDark: false,
                onShowSummaryInputDialog: (ctx, ref, list) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Team A'), findsOneWidget);
      expect(find.text('Team B'), findsOneWidget);
      expect(find.text('1ポジション'), findsOneWidget);
      expect(find.text('終了'), findsOneWidget);
    });
  });
}
