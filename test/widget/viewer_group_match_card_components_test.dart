import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_group_match_score_summary.dart';

void main() {
  group('ViewerGroupMatchCard Components Tests', () {
    testWidgets('ViewerGroupMatchScoreSummary renders team names and score', (
      tester,
    ) async {
      const match = MatchModel(
        id: 'm1',
        tournamentId: 't1',
        matchType: '先鋒',
        redName: '練馬道場 : 山田',
        whiteName: '杉並道場 : 田中',
        redScore: 2,
        whiteScore: 0,
        status: 'finished',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ViewerGroupMatchScoreSummary(
              groupList: [match],
              rTeam: '練馬道場',
              wTeam: '杉並道場',
              ownTeams: ['練馬道場'],
              titleColor: Colors.black,
            ),
          ),
        ),
      );

      expect(find.text('練馬道場'), findsOneWidget);
      expect(find.text('杉並道場'), findsOneWidget);
      expect(find.text('1'), findsOneWidget); // 1勝
    });
  });
}
