import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/domain/entities/match_model.dart';
import 'package:kendo_os/domain/entities/score_event.dart';
import 'package:kendo_os/presentation/operate/screens/official_record_screen.dart';
import 'package:kendo_os/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/application/mappers/score_event_legacy_adapter.dart';
import 'package:kendo_os/presentation/operate/screens/home_screen.dart' show customTeamNamesProvider;
import 'package:go_router/go_router.dart';
import 'package:kendo_os/presentation/operate/providers/settings_provider.dart';
import 'package:kendo_os/domain/entities/settings_model.dart';

class MockSettingsNotifier extends SettingsNotifier {
  @override
  SettingsModel build() => const SettingsModel(securityLevel: 1);
}

void main() {
  group('OfficialRecordScreen UI/Logic Tests', () {
    const testTournamentId = 'test_tournament_1';
    const testGroupId = 'group_1';

    Widget createTestableWidget(List<MatchModel> mockMatches, {String tournamentId = testTournamentId}) {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => OfficialRecordScreen(tournamentId: tournamentId),
          ),
        ],
      );

      return ProviderScope(
        overrides: [
          matchListProvider.overrideWith((ref) => mockMatches),
          customTeamNamesProvider.overrideWith((ref) => Stream.value(<String>[])),
          permissionProvider.overrideWith((ref) => const AppPermissions(
                canCreateMatch: true, canManageTournament: true, isReadOnly: false,
                canChangeSettings: true, canDeleteData: true,
              )),
          settingsProvider.overrideWith(() => MockSettingsNotifier()),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      );
    }

    testWidgets('1. 代表戦のスコアがチームの合計(勝数/本数)に合算されないこと', (WidgetTester tester) async {
      final mockMatches = [
        const MatchModel(
          id: 'm1',
          tournamentId: testTournamentId,
          groupName: testGroupId,
          matchType: '大将',
          redName: 'Aチーム: 赤選手',
          whiteName: 'Bチーム: 白選手',
          redScore: 1,
          whiteScore: 0,
          status: 'finished',
        ),
        const MatchModel(
          id: 'm2',
          tournamentId: testTournamentId,
          groupName: testGroupId,
          matchType: '代表戦', // ★ 代表戦
          redName: 'Aチーム: 赤代表',
          whiteName: 'Bチーム: 白代表',
          redScore: 2, // 代表戦で赤が2本取る
          whiteScore: 0,
          status: 'finished',
        ),
      ];

      await tester.pumpWidget(createTestableWidget(mockMatches));
      await tester.pumpAndSettle();

      // 大将戦で赤が1勝1本、代表戦で赤が1勝2本だが、
      // サマリー（合計）には本戦の「1勝 1本」だけが反映されるべき
      expect(find.text('1\n--\n1'), findsOneWidget, reason: '赤チームのサマリーは1勝1本であるべき');
      expect(find.text('0\n--\n0'), findsOneWidget, reason: '白チームのサマリーは0勝0本であるべき');
    });

    testWidgets('2. 判定勝ちの場合、「判」という1文字に圧縮されて丸囲み等で描画されること', (WidgetTester tester) async {
      final hanteiEvent = ScoreEventLegacyAdapter.fromLegacy(
        id: 'e1',
        type: PointType.hantei,
        side: Side.red,
        timestamp: DateTime.now(),
      );

      final mockMatches = [
        MatchModel(
          id: 'm1',
          tournamentId: testTournamentId,
          groupName: testGroupId,
          matchType: '個人戦',
          redName: '赤選手',
          whiteName: '白選手',
          redScore: 1,
          whiteScore: 0,
          status: 'finished',
          events: [hanteiEvent],
        ),
      ];

      await tester.pumpWidget(createTestableWidget(mockMatches));
      await tester.pumpAndSettle();

      // KendoRuleEngine を通して「判定」が返ってくるが、UIで「判」に圧縮される
      expect(find.text('判'), findsOneWidget);
      expect(find.text('判定'), findsNothing, reason: 'レイアウト崩れを防ぐため「判定」とは表示されないこと');
    });

    testWidgets('3. 欠員の場合、選手名のセルは空欄で表示されるべき', (WidgetTester tester) async {
      final matches = [
        const MatchModel(
          id: 'm_kekkin',
          tournamentId: testTournamentId,
          groupName: testGroupId,
          redName: 'チームA:山田太郎',
          whiteName: 'チームB:(欠員)',
          matchType: '先鋒',
          status: 'finished',
        ),
      ];

      await tester.pumpWidget(createTestableWidget(matches));
      await tester.pumpAndSettle();

      final tableWidget = tester.widget<Table>(find.byType(Table).first);
      final whiteNameRow = tableWidget.children[3]; // 0:header, 1:red names, 2:scores, 3:white names
      final nameCellWidget = whiteNameRow.children[1] as Container;

      expect(nameCellWidget.child, isNull);
      expect(find.text('(欠員)'), findsNothing);
    });

    testWidgets('4. 同姓の選手がいる場合、名（イニシャル）が表示されるべき', (WidgetTester tester) async {
      final matches = [
        const MatchModel(
          id: 'm_same_1',
          tournamentId: testTournamentId,
          groupName: testGroupId,
          order: 1,
          matchType: '先鋒',
          redName: 'チームA:山田 太郎',
          whiteName: 'チームB:佐藤 一',
          status: 'finished',
        ),
        const MatchModel(
          id: 'm_same_2',
          tournamentId: testTournamentId,
          groupName: testGroupId,
          order: 2,
          matchType: '次鋒',
          redName: 'チームA:山田 花子',
          whiteName: 'チームB:鈴木 二',
          status: 'finished',
        ),
      ];

      await tester.pumpWidget(createTestableWidget(matches));
      await tester.pumpAndSettle();

      // Find the initial '太'
      final initialTaroFinder = find.text('太');
      expect(initialTaroFinder, findsOneWidget);

      final rowTaroFinder = find.ancestor(of: initialTaroFinder, matching: find.byType(Row));
      expect(find.descendant(of: rowTaroFinder, matching: find.text('山')), findsOneWidget);
      expect(find.descendant(of: rowTaroFinder, matching: find.text('田')), findsOneWidget);

      final initialHanakoFinder = find.text('花');
      expect(initialHanakoFinder, findsOneWidget);
      final rowHanakoFinder = find.ancestor(of: initialHanakoFinder, matching: find.byType(Row));
      expect(find.descendant(of: rowHanakoFinder, matching: find.text('山')), findsOneWidget);
      expect(find.descendant(of: rowHanakoFinder, matching: find.text('田')), findsOneWidget);

      expect(find.text('一'), findsNothing);
      expect(find.text('二'), findsNothing);
    });
  });
}