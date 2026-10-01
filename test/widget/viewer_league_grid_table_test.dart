import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/viewer/components/viewer_league_grid_table.dart';
import 'package:kendo_os/shared/application/projections/match_projection.dart';

void main() {
  group('[Widget] ViewerLeagueGridTable ウィジェットテスト', () {
    testWidgets('league grid カード with matchesが正しく描画されること', (tester) async {
      final matches = [
        const MatchListProjection(
          id: 'm1',
          tournamentId: 't1',
          matchOrder: 1,
          matchType: 'team',
          redName: 'チームA',
          whiteName: 'チームB',
          redScore: 2,
          whiteScore: 1,
          status: 'finished',
          note: '',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ViewerLeagueGridTable(
              groupName: 'リーグA',
              matches: matches,
              isDark: false,
              stats: const [],
              isLeagueRule: true,
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('viewer_match_card_リーグA')), findsOneWidget);
    });
  });
}
