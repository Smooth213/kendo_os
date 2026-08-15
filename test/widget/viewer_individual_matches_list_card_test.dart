import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/viewer/components/viewer_individual_matches_list_card.dart';

void main() {
  group('🛡️ ViewerIndividualMatchesListCard Widget Tests', () {
    testWidgets(
      'Renders individual matches list with player names and scores',
      (WidgetTester tester) async {
        final match1 = MatchModel(
          id: 'indiv_1',
          redName: '東軍: 坂本',
          whiteName: '西軍: 岡田',
          redScore: 1,
          whiteScore: 0,
          status: 'finished',
          matchType: 'individual',
          note: '第1試合',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ViewerIndividualMatchesListCard(
                groupName: '男子個人の部',
                matches: [match1],
                isDark: false,
              ),
            ),
          ),
        );

        expect(find.text('【個人戦】 男子個人の部'), findsOneWidget);
        expect(find.text('坂本'), findsOneWidget);
        expect(find.text('岡田'), findsOneWidget);
        expect(find.text('東軍'), findsOneWidget);
        expect(find.text('西軍'), findsOneWidget);
        expect(find.text('第1試合'), findsOneWidget);
      },
    );
  });
}
