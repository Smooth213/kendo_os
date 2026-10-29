import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/safe_pump_helper.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/official_record_individual_matches_list.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/official_record_kachinuki_card.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/official_record_league_section.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/official_record_score_table_builder.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  group('[Widget] 公式記録 セクション・形試合リスト・勝ち抜き戦カード統合検証テスト', () {
    testWidgets('公式記録スコアテーブルが正しく描画されること', (tester) async {
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

    testWidgets('公式記録リーグセクションにリーグタイトルが正しく描画されること', (tester) async {
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

      await tester.safePumpAndSettle();

      expect(find.text('【形・基本判定】 1回戦'), findsOneWidget);
      expect(find.text('山田・佐藤'), findsOneWidget);
      expect(find.text('鈴木・田中'), findsOneWidget);
      expect(find.text('-'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
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

      await tester.safePumpAndSettle();

      expect(find.text('【形・基本判定】 2回戦'), findsOneWidget);
      expect(find.text('不戦'), findsOneWidget);
      expect(find.text('○'), findsOneWidget);
      expect(find.text('×'), findsOneWidget);
    });

    testWidgets('ライトモード時に勝ち抜き戦スコアカードの背景が白系でありtextColorでないこと', (tester) async {
      final kachinukiMatches = [
        MatchModel(
          id: 'kachinuki_m1',
          matchType: '勝ち抜き戦',
          redName: '宇品体協剣道部: 沖野',
          whiteName: '道上剣友会B: 選手A',
          status: 'finished',
          redScore: 2,
          whiteScore: 0,
          redRemaining: ['沖野', '大川'],
          whiteRemaining: ['選手B'],
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData(
              brightness: Brightness.light,
              extensions: [
                AppThemeColors.ofMode(isDark: false, mode: 'normal'),
              ],
            ),
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  return OfficialRecordKachinukiCard(
                    matches: kachinukiMatches,
                    isDark: false,
                    ref: ref,
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.safePumpAndSettle();

      final cardFinder = find.byType(Card);
      expect(cardFinder, findsOneWidget);
      final cardWidget = tester.widget<Card>(cardFinder);
      expect(
        cardWidget.color,
        equals(
          AppThemeColors.ofMode(isDark: false, mode: 'normal').cardBackground,
        ),
      );

      final containers = tester.widgetList<Container>(
        find.descendant(
          of: find.byType(SingleChildScrollView),
          matching: find.byType(Container),
        ),
      );
      expect(containers.isNotEmpty, isTrue);
      expect(
        containers.first.color,
        isNot(
          equals(
            AppThemeColors.ofMode(isDark: false, mode: 'normal').textColor,
          ),
        ),
      );
      expect(
        containers.first.color,
        equals(
          AppThemeColors.ofMode(isDark: false, mode: 'normal').cardBackground,
        ),
      );
    });

    testWidgets('ダークモード時に勝ち抜き戦スコアカードの背景がダーク系色となること', (tester) async {
      final kachinukiMatches = [
        MatchModel(
          id: 'kachinuki_m1',
          matchType: '勝ち抜き戦',
          redName: '宇品体協剣道部: 沖野',
          whiteName: '道上剣友会B: 選手A',
          status: 'finished',
          redScore: 2,
          whiteScore: 0,
          redRemaining: ['沖野', '大川'],
          whiteRemaining: ['選手B'],
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData(
              brightness: Brightness.dark,
              extensions: [AppThemeColors.ofMode(isDark: true, mode: 'normal')],
            ),
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  return OfficialRecordKachinukiCard(
                    matches: kachinukiMatches,
                    isDark: true,
                    ref: ref,
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.safePumpAndSettle();

      final cardFinder = find.byType(Card);
      expect(cardFinder, findsOneWidget);
      final cardWidget = tester.widget<Card>(cardFinder);
      expect(
        cardWidget.color,
        equals(
          AppThemeColors.ofMode(isDark: true, mode: 'normal').cardBackground,
        ),
      );

      final containers = tester.widgetList<Container>(
        find.descendant(
          of: find.byType(SingleChildScrollView),
          matching: find.byType(Container),
        ),
      );
      expect(containers.isNotEmpty, isTrue);
      expect(
        containers.first.color,
        equals(
          AppThemeColors.ofMode(isDark: true, mode: 'normal').cardBackground,
        ),
      );
    });
  });
}
