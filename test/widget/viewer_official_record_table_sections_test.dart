import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/application/projections/match_projection.dart';
import 'package:kendo_os/features/viewer/components/viewer_official_record_table_sections.dart';

void main() {
  group('🛡️ ViewerOfficialRecordTableSections Widget Tests', () {
    testWidgets(
      'ViewerOfficialScoreTableCard renders team title and table properly',
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
          MaterialApp(
            home: Scaffold(
              body: ViewerOfficialScoreTableCard(
                groupName: 'group1',
                matches: matches,
                isDark: false,
              ),
            ),
          ),
        );

        expect(find.text('【団体戦】 チームA vs チームB (1回戦)'), findsOneWidget);
      },
    );

    testWidgets(
      'ViewerOfficialIndividualListCard renders individual match item properly',
      (tester) async {
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
          MaterialApp(
            home: Scaffold(
              body: ViewerOfficialIndividualListCard(
                groupName: '男子個人',
                matches: matches,
                isDark: false,
                applySort: true,
              ),
            ),
          ),
        );

        expect(find.text('【個人戦】 男子個人'), findsOneWidget);
      },
    );
  });
}
