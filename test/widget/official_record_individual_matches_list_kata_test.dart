import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/official_record_individual_matches_list.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart';

void main() {
  group('[Widget] OfficialRecordIndividualMatchesList 形試合表示検証', () {
    testWidgets('形試合の場合にヘッダーが形・基本判定となり、判定ラベルが表示されること', (
      WidgetTester tester,
    ) async {
      final matches = [
        MatchModel(
          id: 'm_kata_1',
          tournamentId: 't1',
          matchType: 'individual',
          redName: '山田・佐藤',
          whiteName: '鈴木・田中',
          redScore: 2,
          whiteScore: 1,
          status: 'finished',
          rule: const MatchRule(isKataMatch: true),
          events: [
            ScoreEvent(
              id: 'ev_kata_1',
              side: Side.red,
              timestamp: DateTime.now(),
              isHantei: true,
              redFlags: 2,
              whiteFlags: 1,
            ),
          ],
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

      // ヘッダーが形試合用になっていること
      expect(find.text('【形・基本判定】 1回戦'), findsOneWidget);
      // ペア名が表示されていること
      expect(find.text('山田・佐藤'), findsOneWidget);
      expect(find.text('鈴木・田中'), findsOneWidget);
      // 中央の判定ラベル「判定」が表示されていること
      expect(find.text('判定'), findsOneWidget);
    });

    testWidgets('形試合の不戦勝の場合に中央ラベルが「不戦」となり○と×が表示されること', (
      WidgetTester tester,
    ) async {
      final matches = [
        MatchModel(
          id: 'm_kata_fusen',
          tournamentId: 't1',
          matchType: 'individual',
          redName: '山田・佐藤',
          whiteName: '鈴木・田中',
          redScore: 1,
          whiteScore: 0,
          status: 'finished',
          rule: const MatchRule(isKataMatch: true),
          events: [
            ScoreEvent(
              id: 'ev_kata_fusen',
              side: Side.red,
              timestamp: DateTime.now(),
              isFusen: true,
            ),
          ],
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
                groupName: '2回戦',
                matches: matches,
                isDark: false,
                applySort: true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('【形・基本判定】 2回戦'), findsOneWidget);
      expect(find.text('不戦'), findsOneWidget);
      expect(find.text('○'), findsOneWidget);
      expect(find.text('×'), findsOneWidget);
    });
  });
}
