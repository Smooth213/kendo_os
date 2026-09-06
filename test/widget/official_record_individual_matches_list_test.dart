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

  testWidgets(
    'OfficialRecordIndividualMatchesList: __merged_individual__ ではタイトルが【個人戦】となり、自チーム選手優先で選手順に並ぶこと',
    (WidgetTester tester) async {
      final matches = [
        const MatchModel(
          id: 'm1',
          tournamentId: 't1',
          matchType: '個人戦',
          redName: '道上剣友会: 橋本 璃久',
          whiteName: '湯田剣道教室: 村上 颯',
          redScore: 1,
          whiteScore: 0,
          status: 'finished',
          order: 17,
        ),
        const MatchModel(
          id: 'm2',
          tournamentId: 't1',
          matchType: '個人戦',
          redName: '小畠剣道教室: 小林 奨',
          whiteName: '道上剣友会: 皿田 唯人',
          redScore: 0,
          whiteScore: 1,
          status: 'finished',
          order: 33,
        ),
        const MatchModel(
          id: 'm3',
          tournamentId: 't1',
          matchType: '個人戦',
          redName: '道上剣友会: 橋本 璃久',
          whiteName: '小畠剣道教室: 田村 聰典',
          redScore: 1,
          whiteScore: 0,
          status: 'finished',
          order: 34,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            customTeamNamesProvider.overrideWith(
              (ref) => Stream.value(['小畠剣道教室']),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: OfficialRecordIndividualMatchesList(
                groupName: '__merged_individual__',
                matches: matches,
                isDark: false,
                applySort: true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // ヘッダーは単一の「【個人戦】」として表示される（個別の試合番号などが付かない）
      expect(find.text('【個人戦】'), findsOneWidget);
      expect(find.text('【個人戦】 __merged_individual__'), findsNothing);

      // 全3試合が1つのリストカード内に表示されている
      expect(find.text('小林 奨'), findsOneWidget);
      expect(find.text('田村 聰典'), findsOneWidget);
      expect(find.text('村上 颯'), findsOneWidget);

      // 自チーム所属の選手名（小畠剣道教室）が解決され表示されている
      expect(find.text('小畠剣道教室'), findsNWidgets(2));
    },
  );

  testWidgets(
    'OfficialRecordIndividualMatchesList: 同門決勝（第35試合）が一番上に飛び出さず、初戦順・試合順に正しく並ぶこと',
    (WidgetTester tester) async {
      // ユーザーの実際のシナリオ（道上剣友会）:
      // 13試合目: 恵木 春陽 vs 津山
      // 25試合目: 恵木 春陽 vs 田村
      // 17試合目: 橋本 璃久 vs 村上
      // 27試合目: 橋本 璃久 vs 岩岡
      // 35試合目: 決勝 皿田 唯人 vs 橋本 璃久（同門対決！）
      final matches = [
        const MatchModel(
          id: 'm35',
          tournamentId: 't1',
          matchType: '個人戦',
          groupName: '第1試合場, 35試合目',
          note: '第1試合場, 35試合目\n決勝',
          redName: '道上剣友会: 皿田 唯人',
          whiteName: '道上剣友会: 橋本 璃久',
          status: 'finished',
          order: 35,
        ),
        const MatchModel(
          id: 'm13',
          tournamentId: 't1',
          matchType: '個人戦',
          groupName: '第1試合場, 13試合目',
          note: '第1試合場, 13試合目',
          redName: '道上剣友会: 恵木 春陽',
          whiteName: '大和剣道クラブ: 津山 星和',
          status: 'finished',
          order: 13,
        ),
        const MatchModel(
          id: 'm25',
          tournamentId: 't1',
          matchType: '個人戦',
          groupName: '第1試合場, 25試合目',
          note: '第1試合場, 25試合目',
          redName: '道上剣友会: 恵木 春陽',
          whiteName: '小畠剣道教室: 田村 聰典',
          status: 'finished',
          order: 25,
        ),
        const MatchModel(
          id: 'm17',
          tournamentId: 't1',
          matchType: '個人戦',
          groupName: '第1試合場, 17試合目',
          note: '第1試合場, 17試合目',
          redName: '道上剣友会: 橋本 璃久',
          whiteName: '湯田剣道教室: 村上 颯',
          status: 'finished',
          order: 17,
        ),
        const MatchModel(
          id: 'm27',
          tournamentId: 't1',
          matchType: '個人戦',
          groupName: '第1試合場, 27試合目',
          note: '第1試合場, 27試合目',
          redName: '道上剣友会: 橋本 璃久',
          whiteName: '加茂剣友会: 岩岡 大駿',
          status: 'finished',
          order: 27,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            customTeamNamesProvider.overrideWith(
              (ref) => Stream.value(['道上剣友会']),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: OfficialRecordIndividualMatchesList(
                  groupName: '__merged_individual__',
                  matches: matches,
                  isDark: false,
                  applySort: true,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 各試合のnoteまたは選手名ウィジェットの表示順序を取得
      final textWidgets = tester
          .widgetList<Text>(find.byType(Text))
          .map((w) => w.data ?? '')
          .toList();

      // 決勝戦（35試合目）が恵木選手（13試合目）より上に来ていないことを検証！
      final index13 = textWidgets.indexWhere((t) => t.contains('13試合目'));
      final index35 = textWidgets.indexWhere((t) => t.contains('35試合目'));
      final index17 = textWidgets.indexWhere((t) => t.contains('17試合目'));

      expect(index13 != -1, isTrue);
      expect(index35 != -1, isTrue);
      expect(index17 != -1, isTrue);

      // 初戦が13試合目の恵木選手が先頭に来る
      expect(index13 < index17, isTrue);
      // 決勝戦（35試合目）は一番上ではなく、後（index13より後ろ）に来ること！
      expect(index13 < index35, isTrue);
      expect(index17 < index35, isTrue);
    },
  );
}
