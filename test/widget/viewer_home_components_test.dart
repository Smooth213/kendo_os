import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_category_section_list.dart';

void main() {
  group('ViewerHome Components Tests', () {
    testWidgets('ViewerCategorySectionList renders categories and teams', (
      tester,
    ) async {
      const match = MatchModel(
        id: 'm1',
        tournamentId: 't1',
        category: '小学生低学年',
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
            body: SingleChildScrollView(
              child: ViewerCategorySectionList(
                entries: [
                  MapEntry('小学生低学年', [match]),
                ],
                ownTeams: ['練馬道場'],
                sanitizedQuery: '',
                matchedMatchIds: {},
                matchedGroupNames: {},
                isDark: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('小学生低学年'), findsOneWidget);
    });
  });
}
