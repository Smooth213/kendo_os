import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/official_record_league_grid_table.dart';

void main() {
  testWidgets(
    'OfficialRecordLeagueGridTable renders league grid table correctly',
    (WidgetTester tester) async {
      const rule = MatchRule(isLeague: true, matchTimeMinutes: 3.0);

      final matches = [
        const MatchModel(
          id: 'm1',
          tournamentId: 't1',
          matchType: '団体戦',
          redName: '東京A',
          whiteName: '大阪B',
          redScore: 2,
          whiteScore: 1,
          status: 'approved',
          rule: rule,
          note: '[リーグ戦]',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: OfficialRecordLeagueGridTable(
                groupName: 'Aブロック',
                matches: matches,
                isDark: false,
                scoreTableBuilder: (name, bouts) => Text('ScoreTable: $name'),
                individualListBuilder: (name, bouts) =>
                    Text('IndivList: $name'),
              ),
            ),
          ),
        ),
      );

      // Verify team names rendered in table
      expect(find.text('東京A'), findsWidgets);
      expect(find.text('大阪B'), findsWidgets);
    },
  );
}
