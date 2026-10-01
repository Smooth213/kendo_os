import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart'
    show customTeamNamesProvider;
import 'package:kendo_os/shared/application/projections/match_projection.dart';
import 'package:kendo_os/features/viewer/components/viewer_official_record_table_sections.dart';

void main() {
  group('[Widget] ViewerOfficialRecordTableSections ウィジェットテスト', () {
    testWidgets(
      'ViewerOfficialScoreTableCardにおいて チームタイトルおよびスコアテーブルが適切に描画されること',
      (tester) async {
        final matches = [
          const MatchListProjection(
            id: 'm1',
            tournamentId: 't1',
            matchOrder: 1,
            matchType: '先鋒',
            redName: 'チームA : 山田',
            whiteName: 'チームB : 田中',
            redScore: 2,
            whiteScore: 1,
            status: 'finished',
            note: '1回戦',
            isKachinuki: false,
          ),
        ];

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              customTeamNamesProvider.overrideWith((ref) => Stream.value([])),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: ViewerOfficialScoreTableCard(
                  groupName: 'group1',
                  matches: matches,
                  isDark: false,
                ),
              ),
            ),
          ),
        );

        expect(find.text('【団体戦】 チームA vs チームB (1回戦)'), findsOneWidget);
      },
    );

    testWidgets('観客用個人戦リストカードの試合項目が正しく描画されること', (tester) async {
      final matches = [
        const MatchListProjection(
          id: 'm1',
          tournamentId: 't1',
          matchOrder: 1,
          matchType: '個人戦',
          redName: '道場A : 佐藤',
          whiteName: '道場B : 鈴木',
          redScore: 1,
          whiteScore: 0,
          status: 'finished',
          note: '',
          isKachinuki: false,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            customTeamNamesProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ViewerOfficialIndividualListCard(
                groupName: '男子個人',
                matches: matches,
                isDark: false,
                applySort: true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('【個人戦】 男子個人'), findsOneWidget);
    });
  });
}
