import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/components/bunaiksen_official_record/bunaiksen_individual_matches_list.dart';

void main() {
  testWidgets(
    'BunaiksenIndividualMatchesList renders player names and match rows',
    (WidgetTester tester) async {
      final matches = [
        MatchModel(
          id: 'm1',
          tournamentId: 't1',
          matchType: 'individual',
          redName: '先鋒: 山田 太郎',
          whiteName: '先鋒: 佐藤 次郎',
          status: 'finished',
          redScore: 2,
          whiteScore: 0,
          order: 1,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BunaiksenIndividualMatchesList(
              groupName: 'Aパート',
              matches: matches,
              isDark: false,
            ),
          ),
        ),
      );

      // Verify header and names
      expect(find.textContaining('【個人戦】'), findsOneWidget);
      expect(find.textContaining('山田 太郎'), findsOneWidget);
      expect(find.textContaining('佐藤 次郎'), findsOneWidget);
    },
  );
}
