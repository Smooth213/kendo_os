import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../helpers/safe_pump_helper.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/tournament/domain/team_progress_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/permission_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/safe_timeline_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/team_progress_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/team_match_status_screen.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import '../../../helpers/event_factory.dart';

void main() {
  group('[Widget] チーム試合状況画面 全試合形式（個人・リーグ・勝抜・団体）検証テスト', () {
    final liveEvents = [kote(Side.red), men(Side.white)];

    final comprehensiveMatches = [
      // 1. トーナメント団体戦（道上剣友会A: 進行中LIVE）
      MatchModel(
        id: 'm1_dantai_live',
        groupName: 'group_dohjo_a_r1',
        matchType: '先鋒戦',
        redName: '道上剣友会A: 皿田 脩人',
        whiteName: '相手チーム02: 相手 一郎',
        status: 'in_progress',
        redScore: 1,
        whiteScore: 1,
        events: liveEvents,
        note: '第3試合場, 2回戦, 3試合目',
        category: '小学生低学年の部',
        order: 1.0,
        timerStartedAt: DateTime(2026, 10, 1, 10, 0, 0),
      ),
      const MatchModel(
        id: 'm1_dantai_wait',
        groupName: 'group_dohjo_a_r1',
        matchType: '中堅戦',
        redName: '道上剣友会A: 塚本 大道',
        whiteName: '相手チーム02: 相手 二郎',
        status: 'waiting',
        note: '第3試合場, 2回戦, 3試合目',
        category: '小学生低学年の部',
        order: 2.0,
      ),

      // 2. 個人戦（トーナメント個人戦: 終了済）
      const MatchModel(
        id: 'm2_indiv',
        matchType: '個人戦',
        redName: '道上剣友会A: 久安 智也',
        whiteName: 'ライバル道場: 相手 三郎',
        status: 'finished',
        redScore: 2,
        whiteScore: 0,
        note: '第1コート, 準決勝, 1試合目',
        category: '中学生個人の部',
        order: 3.0,
      ),

      // 3. リーグ個人戦（選手名のみだが名簿から逆引き判定: 待機中）
      const MatchModel(
        id: 'm3_league_indiv',
        matchType: 'リーグ個人戦',
        redName: '相手 四郎',
        whiteName: '皿田 脩人',
        status: 'waiting',
        note: '第2コート, Aリーグ, 4試合目',
        category: '小学生個人の部',
        order: 4.0,
      ),

      // 4. リーグ団体戦（道上選抜: 終了済）
      const MatchModel(
        id: 'm4_league_team',
        groupName: 'group_league_dohjo_1',
        matchType: 'リーグ団体戦',
        redName: '道上選抜',
        whiteName: '強豪館B',
        status: 'finished',
        redScore: 3,
        whiteScore: 1,
        note: '第4コート, 予選リーグ, 2試合目',
        category: '中学生団体の部',
        order: 5.0,
      ),

      // 5. 勝ち抜き戦（道上勝抜隊: 待機中）
      const MatchModel(
        id: 'm5_kachinuki',
        matchType: '勝ち抜き戦',
        isKachinuki: true,
        redName: '道上勝抜隊',
        whiteName: '炎陽塾',
        status: 'waiting',
        note: '第5コート, 1回戦',
        category: '勝ち抜きオープンの部',
        order: 6.0,
      ),
    ];

    testWidgets('個人戦・リーグ個人戦・リーグ団体戦・勝ち抜き戦・団体戦のカード描画・見出し・遷移の全工程が正しく検証されること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final currentMatches = [...comprehensiveMatches];

      final router = GoRouter(
        initialLocation: '/team-status',
        routes: [
          GoRoute(
            path: '/team-status',
            builder: (context, state) => const TeamMatchStatusScreen(),
          ),
          GoRoute(
            path: '/team-scoreboard/:groupName',
            builder: (context, state) {
              final groupName = state.pathParameters['groupName'] ?? '';
              return Scaffold(
                body: Center(child: Text('団体戦スコアボード画面: $groupName')),
              );
            },
          ),
          GoRoute(
            path: '/match/:matchId',
            builder: (context, state) {
              final matchId = state.pathParameters['matchId'] ?? '';
              return Scaffold(body: Center(child: Text('個別試合画面: $matchId')));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matchListProvider.overrideWith((ref) => currentMatches),
            customTeamNamesProvider.overrideWith(
              (ref) => Stream.value(['道上剣友会A', '道上選抜', '道上勝抜隊']),
            ),
            timelinePlayerListProvider.overrideWith(
              (ref) => Stream.value([
                PlayerModel(
                  id: 'p1',
                  lastName: '皿田',
                  firstName: '脩人',
                  lastNameKana: 'さらだ',
                  firstNameKana: 'しゅうと',
                  grade: 3,
                ),
                PlayerModel(
                  id: 'p2',
                  lastName: '久安',
                  firstName: '智也',
                  lastNameKana: 'ひさやす',
                  firstNameKana: 'ともや',
                  grade: 5,
                ),
              ]),
            ),
            currentDojoNameProvider.overrideWith((ref) => Stream.value('道上')),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.safePumpAndSettle();

      // ----------------------------------------------------
      // Step 1: 初期表示 & 自チーム認識（ヘッダー）の検証
      // ----------------------------------------------------
      expect(find.text('チーム試合状況'), findsOneWidget);
      expect(find.textContaining('すべて表示'), findsOneWidget);

      expect(find.text('道上剣友会A'), findsWidgets);
      expect(find.text('道上選抜'), findsWidgets);

      // ----------------------------------------------------
      // Step 2: 各試合形式の対戦枠見出し（全形式網羅）の検証
      // ----------------------------------------------------
      expect(find.text('団体戦：道上剣友会A vs 相手チーム02'), findsOneWidget);
      expect(find.textContaining('個人戦：'), findsWidgets);
      expect(find.textContaining('リーグ個人戦：'), findsWidgets);
      expect(find.textContaining('リーグ団体戦：'), findsWidgets);
      expect(find.textContaining('勝ち抜き戦：'), findsWidgets);

      // ----------------------------------------------------
      // Step 3: コートタップ直接編集シート起動＆復帰検証
      // ----------------------------------------------------
      await tester.tap(find.text('第3試合場 (2回戦・第3試合)'));
      await tester.safePumpAndSettle();

      expect(find.text('団体戦対戦の編集'), findsOneWidget);
      expect(find.text('コート・メモ'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.safePumpAndSettle();

      expect(find.text('チーム試合状況'), findsOneWidget);

      // ----------------------------------------------------
      // Step 4: フィルター動作の検証
      // ----------------------------------------------------
      await tester.tap(find.text('🔴 試合中のみ (1)'));
      await tester.safePumpAndSettle();

      expect(find.text('道上剣友会A'), findsWidgets);
      expect(find.text('道上選抜'), findsNothing);

      await tester.tap(find.textContaining('すべて表示'));
      await tester.safePumpAndSettle();

      expect(find.text('道上剣友会A'), findsWidgets);
      expect(find.text('道上選抜'), findsWidgets);

      // ----------------------------------------------------
      // Step 5: 終了した団体戦カードタップでスコアボード遷移検証
      // ----------------------------------------------------
      await tester.tap(find.text('道上選抜').first);
      await tester.safePumpAndSettle();

      expect(find.text('団体戦スコアボード画面: group_league_dohjo_1'), findsOneWidget);
    });

    testWidgets('並び替えチップのタップにより、会場順・試合順・進行状況順にリストが正しく並び替わること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      TeamProgressStatus makeStatus({
        required String teamName,
        required String courtName,
        bool hasLive = false,
        bool isFinished = false,
      }) {
        return TeamProgressStatus(
          teamName: teamName,
          currentCourtName: courtName,
          matches: [
            MatchModel(
              id: 'm_$teamName',
              matchType: '先鋒',
              redName: '$teamName: 選手A',
              whiteName: '相手チーム: 選手B',
              status: isFinished
                  ? 'finished'
                  : (hasLive ? 'in_progress' : 'waiting'),
              order: 1.0,
            ),
          ],
          completedCount: isFinished ? 1 : 0,
          totalCount: 1,
          hasLiveMatch: hasLive,
        );
      }

      final mockTeams = [
        makeStatus(teamName: 'チームA', courtName: '第2コート (第1試合)', hasLive: true),
        makeStatus(teamName: 'チームB', courtName: '第1コート (第3試合)', hasLive: false),
        makeStatus(teamName: 'チームC', courtName: '第1コート (第1試合)', hasLive: false),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            teamProgressListProvider.overrideWithValue(mockTeams),
            customTeamNamesProvider.overrideWith((ref) => Stream.value([])),
            permissionProvider.overrideWith(
              (ref) => const AppPermissions(
                canCreateMatch: true,
                canManageTournament: true,
                isReadOnly: false,
                canChangeSettings: true,
                canDeleteData: true,
              ),
            ),
          ],
          child: const MaterialApp(
            home: TeamMatchStatusScreen(
              tournamentId: 'test_tournament',
              isBottomSheet: false,
            ),
          ),
        ),
      );

      await tester.safePumpAndSettle();

      expect(find.text('並び替え:'), findsOneWidget);
      expect(find.text('⚡ 進行状況順'), findsOneWidget);
      expect(find.text('🏟️ 試合会場順'), findsOneWidget);
      expect(find.text('🔢 試合順'), findsOneWidget);

      List<String> getRenderedTeamNames() {
        final teamNames = <String>[];
        final widgets = tester.widgetList<Text>(
          find.byWidgetPredicate(
            (w) =>
                w is Text &&
                w.data != null &&
                (w.data == 'チームA' || w.data == 'チームB' || w.data == 'チームC'),
          ),
        );
        for (final w in widgets) {
          if (!teamNames.contains(w.data)) {
            teamNames.add(w.data!);
          }
        }
        return teamNames;
      }

      // 1. 初期順序 (進行状況順: チームA (LIVE) が最上位)
      expect(getRenderedTeamNames().first, 'チームA');

      // 2. 「試合会場順」をタップ
      await tester.tap(find.text('🏟️ 試合会場順'));
      await tester.safePumpAndSettle();

      final courtOrdered = getRenderedTeamNames();
      expect(courtOrdered[0], 'チームC');
      expect(courtOrdered[1], 'チームB');
      expect(courtOrdered[2], 'チームA');

      // 3. 「試合順」をタップ
      await tester.tap(find.text('🔢 試合順'));
      await tester.safePumpAndSettle();

      final matchOrdered = getRenderedTeamNames();
      expect(matchOrdered[0], 'チームC');
      expect(matchOrdered[1], 'チームA');
      expect(matchOrdered[2], 'チームB');

      // 4. 「進行状況順」に戻す
      await tester.tap(find.text('⚡ 進行状況順'));
      await tester.safePumpAndSettle();

      expect(getRenderedTeamNames().first, 'チームA');
    });
  });
}
