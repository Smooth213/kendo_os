import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/tournament/presentation/operate/official_record_screen.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/home_screen.dart';
import 'package:kendo_os/shared/domain/entities/team_model.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/team_repository.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('[Widget] 試合スコア修正から公式記録選手サマリーへの画面間連動統合テスト', () {
    testWidgets('試合で打突が取り消し（Undo）修正された結果が公式記録の選手サマリーおよび個人カルテに100%正確に反映されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1366, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final now = DateTime(2026, 10, 10, 10, 30);

      // 試合1: 先鋒 山田（東京道場）vs 田中（京都道場）
      // 面を取得したが、Undoで取り消されて0-0の引き分けになった試合
      final evMen1 = ScoreEvent(
        id: 'flow_ev_men_1',
        side: Side.red,
        strikeType: StrikeType.men,
        isIppon: true,
        timestamp: now,
      );
      final evUndo1 = ScoreEvent(
        id: 'flow_ev_undo_1',
        side: Side.none,
        isUndo: true,
        targetId: 'flow_ev_men_1',
        timestamp: now.add(const Duration(seconds: 10)),
      );

      final bout1 = MatchModel(
        id: 'flow_bout_1',
        tournamentId: 't_flow',
        matchType: '先鋒',
        category: '一般',
        groupName: '1回戦 (東京道場 vs 京都道場)',
        redName: '東京道場 : 山田',
        whiteName: '京都道場 : 田中',
        redScore: 0,
        whiteScore: 0,
        status: 'finished',
        events: [evMen1, evUndo1],
      );

      // 試合2: 次鋒 佐藤（東京道場）vs 鈴木（京都道場）
      // 面と小手を取得後、小手をUndoで取り消して1-0の勝ちになった試合
      final evMen2 = ScoreEvent(
        id: 'flow_ev_men_2',
        side: Side.red,
        strikeType: StrikeType.men,
        isIppon: true,
        timestamp: now.add(const Duration(seconds: 20)),
      );
      final evKote2 = ScoreEvent(
        id: 'flow_ev_kote_2',
        side: Side.red,
        strikeType: StrikeType.kote,
        isIppon: true,
        timestamp: now.add(const Duration(seconds: 30)),
      );
      final evUndo2 = ScoreEvent(
        id: 'flow_ev_undo_2',
        side: Side.none,
        isUndo: true,
        targetId: 'flow_ev_kote_2',
        timestamp: now.add(const Duration(seconds: 40)),
      );

      final bout2 = MatchModel(
        id: 'flow_bout_2',
        tournamentId: 't_flow',
        matchType: '次鋒',
        category: '一般',
        groupName: '1回戦 (東京道場 vs 京都道場)',
        redName: '東京道場 : 佐藤',
        whiteName: '京都道場 : 鈴木',
        redScore: 1,
        whiteScore: 0,
        status: 'finished',
        events: [evMen2, evKote2, evUndo2],
      );

      final router = GoRouter(
        initialLocation: '/official-record/t_flow',
        routes: [
          GoRoute(
            path: '/official-record/:id',
            builder: (context, state) =>
                OfficialRecordScreen(tournamentId: state.pathParameters['id']!),
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          tournamentProvider('t_flow').overrideWith(
            (ref) => Stream.value(
              TournamentModel(
                id: 't_flow',
                organizationId: 'org_flow',
                name: '秋季選抜大会',
                date: now,
                categories: ['一般'],
                venue: '日本武道館',
              ),
            ),
          ),
          matchListProvider.overrideWith((ref) => [bout1, bout2]),
          registeredTeamsProvider('t_flow').overrideWith(
            (ref) => Stream.value([
              const TeamModel(
                id: 't_tokyo',
                tournamentId: 't_flow',
                teamName: '東京道場',
                category: '一般',
                playerNames: ['山田', '佐藤'],
              ),
            ]),
          ),
          customTeamNamesProvider.overrideWith((ref) => Stream.value([])),
          permissionProvider.overrideWith(
            (ref) => const AppPermissions(
              isReadOnly: false,
              canManageTournament: true,
              canCreateMatch: true,
              canChangeSettings: true,
              canDeleteData: true,
            ),
          ),
          isarProvider.overrideWithValue(null),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            theme: ThemeData.light(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. 公式記録画面が表示され、成績サマリーが存在すること
      expect(find.text('成績サマリー'), findsOneWidget);

      // 2. 成績サマリーを展開
      await tester.tap(find.byKey(const Key('btn_toggle_expedition_summary')));
      await tester.pumpAndSettle();

      // 3. 選手別成績アコーディオンを展開
      await tester.tap(find.textContaining('選手別成績'));
      await tester.pumpAndSettle();

      // 4. 山田選手のバッジ検証: 面取り消しが反映されて「0本」（(0本)バッジなし）および「0勝0敗1分」であること
      final yamadaBadge = find.text('山田: 0勝0敗1分');
      expect(yamadaBadge, findsOneWidget);
      expect(find.text('(0本)'), findsNothing);

      // 5. 佐藤選手のバッジ検証: 小手取り消しが反映されて「1本」および「1勝0敗」であること
      final satoBadge = find.text('佐藤: 1勝0敗');
      expect(satoBadge, findsOneWidget);
      expect(find.text('(1本)'), findsOneWidget);

      // 6. 山田選手のカルテ展開検証
      await tester.tap(yamadaBadge);
      await tester.pumpAndSettle();

      expect(find.text('山田 選手の個人カルテ'), findsOneWidget);
      expect(find.text('0勝 0敗 1分'), findsOneWidget);

      // 個人カルテを閉じる
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // 7. 佐藤選手のカルテ展開検証
      await tester.tap(satoBadge);
      await tester.pumpAndSettle();

      expect(find.text('佐藤 選手の個人カルテ'), findsOneWidget);
      expect(find.text('1勝 0敗 '), findsOneWidget);
    });
  });
}
