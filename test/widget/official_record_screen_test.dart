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

void main() {
  group('OfficialRecordScreen UI/Logic Tests', () {
    const testTournamentId = 'test_tournament_1';
    const testGroupId = 'group_1';

    Widget createTestableWidget(List<MatchModel> mockMatches) {
      return ProviderScope(
        overrides: [
          matchListProvider.overrideWith((ref) => mockMatches),
          customTeamNamesProvider.overrideWith((ref) => Stream.value(<String>[])),
          permissionProvider.overrideWith((ref) => const AppPermissions(
                canCreateMatch: true,
                canManageTournament: true,
                isReadOnly: false,
              )),
        ],
        child: const MaterialApp(
          home: OfficialRecordScreen(tournamentId: testTournamentId),
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
  });
}