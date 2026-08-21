import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/official_record_league_section.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/official_record_score_table_builder.dart';

void main() {
  group('OfficialRecord Components Tests', () {
    testWidgets('OfficialRecordScoreTableBuilder renders score table', (
      tester,
    ) async {
      const match = MatchModel(
        id: 'm1',
        tournamentId: 't1',
        matchType: '先鋒',
        redName: '先鋒チーム : 山田',
        whiteName: '相手チーム : 田中',
        redScore: 2,
        whiteScore: 0,
        status: 'finished',
        note: '予選1',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: OfficialRecordScoreTableBuilder.buildScoreTable(
                'グループA',
                const [match],
                cardColor: Colors.white,
                isDark: false,
              ),
            ),
          ),
        ),
      );

      expect(find.textContaining('先鋒チーム vs 相手チーム'), findsOneWidget);
    });

    testWidgets('OfficialRecordLeagueSection renders league title', (
      tester,
    ) async {
      const match = MatchModel(
        id: 'm1',
        tournamentId: 't1',
        matchType: '先鋒',
        redName: 'チームA : 選手1',
        whiteName: 'チームB : 選手2',
        status: 'finished',
        note: '[リーグ戦] 予選',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: OfficialRecordLeagueSection(
                  groupName: 'グループL',
                  matches: const [match],
                  cardColor: Colors.white,
                  isDark: false,
                  ownTeams: const ['チームA'],
                  scoreTableBuilder:
                      (name, bouts, {cardColor, isDark = false}) =>
                          const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.textContaining('【リーグ戦】'), findsOneWidget);
    });
  });
}
