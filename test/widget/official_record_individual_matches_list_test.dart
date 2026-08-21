import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/official_record_individual_matches_list.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart';

void main() {
  testWidgets(
    'OfficialRecordIndividualMatchesList renders individual matches list correctly',
    (WidgetTester tester) async {
      final matches = [
        const MatchModel(
          id: 'm1',
          tournamentId: 't1',
          matchType: 'individual',
          redName: '選手A',
          whiteName: '選手B',
          redScore: 2,
          whiteScore: 0,
          status: 'finished',
          note: '',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            customTeamNamesProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: OfficialRecordIndividualMatchesList(
                groupName: '1回戦',
                matches: matches,
                isDark: false,
                applySort: true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify header and names
      expect(find.text('【個人戦】 1回戦'), findsOneWidget);
      expect(find.text('選手A'), findsOneWidget);
      expect(find.text('選手B'), findsOneWidget);
    },
  );
}
