import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen_official_record/bunaiksen_record_action_bar.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen_official_record/bunaiksen_team_score_table.dart';

void main() {
  group('BunaiksenOfficialRecord Components Tests', () {
    testWidgets('BunaiksenRecordActionBar renders action buttons', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BunaiksenRecordActionBar(
              cardColor: Colors.white,
              isDark: false,
              isExporting: false,
              onPrintPdf: () {},
              onShareImage: () {},
            ),
          ),
        ),
      );

      expect(find.text('PDF印刷'), findsOneWidget);
      expect(find.text('画像シェア'), findsOneWidget);
    });

    testWidgets('BunaiksenTeamScoreTable renders matchup properly', (
      tester,
    ) async {
      const match1 = MatchModel(
        id: 'm1',
        tournamentId: 't1',
        matchType: '先鋒',
        redName: '先鋒チーム : 山田',
        whiteName: '相手チーム : 田中',
        redScore: 2,
        whiteScore: 0,
        status: 'finished',
        note: 'リーグ1',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: BunaiksenTeamScoreTable(
                groupName: 'グループA',
                matches: const [match1],
                cardColor: Colors.white,
                isDark: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('先鋒'), findsOneWidget);
      expect(find.textContaining('先鋒チーム vs 相手チーム'), findsOneWidget);
      expect(find.text('赤'), findsOneWidget);
      expect(find.text('白'), findsOneWidget);
    });
  });
}
