import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/safe_timeline_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/team_match_status_screen.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';
import '../helpers/event_factory.dart';

void main() {
  group('🥋 【E2E】チーム試合状況 遠征現場シナリオ完全保証テスト', () {
    final liveEvents = [kote(Side.red), men(Side.white)];

    final initialMatches = [
      // チームA: 団体戦1回戦（進行中: 赤コテ1本、白メン1本）
      MatchModel(
        id: 'm1_live',
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
        timerStartedAt: DateTime.now(),
      ),
      const MatchModel(
        id: 'm1_waiting',
        groupName: 'group_dohjo_a_r1',
        matchType: '中堅戦',
        redName: '道上剣友会A: 塚本 大道',
        whiteName: '相手チーム02: 相手 二郎',
        status: 'waiting',
        note: '第3試合場, 2回戦, 3試合目',
        category: '小学生低学年の部',
        order: 2.0,
      ),

      // チームB: 合同テストチーム（白側だが登録選手 久安 智也 で自チーム認識・終了済）
      const MatchModel(
        id: 'm2_finished',
        groupName: 'group_test_r1',
        matchType: '大将戦',
        redName: '強豪館: 相手 三郎',
        whiteName: '大阪選抜: 久安 智也',
        status: 'finished',
        redScore: 0,
        whiteScore: 2,
        note: '第1コート, 1回戦, 1試合目',
        category: '小学生の部',
        order: 1.0,
      ),
    ];

    testWidgets('【E2Eシナリオ】自チーム認識・技マーク描画・5段構造表示・コートタップ編集・フィルター・スコアボード遷移の全工程検証', (
      tester,
    ) async {
      final currentMatches = [...initialMatches];

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
              (ref) => Stream.value(['道上剣友会A']),
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
      await tester.pumpAndSettle();

      // ----------------------------------------------------
      // Step 1: 初期表示 & 自チーム認識（ヘッダー）の検証
      // ----------------------------------------------------
      expect(find.text('チーム試合状況'), findsOneWidget);
      expect(find.text('登録チーム'), findsOneWidget);
      expect(find.text('🔴 試合中 (LIVE)'), findsOneWidget);

      // チームAカードの確認
      expect(find.text('道上剣友会A'), findsNWidgets(2)); // ヘッダー ＋ 選手上段道場名
      expect(find.text('試合中 (LIVE)'), findsOneWidget);

      // チームB（大阪選抜：白側選手からの逆引き自チーム判定）の確認
      expect(find.text('大阪選抜'), findsNWidgets(2)); // ヘッダー ＋ 選手上段道場名
      expect(find.text('🏁 試合終了'), findsOneWidget);

      // ----------------------------------------------------
      // Step 2: 5段構造レイアウトの完全検証
      // ----------------------------------------------------
      // 2段目: コート・試合順表示
      expect(find.text('第3試合場 (2回戦・第3試合)'), findsOneWidget);
      // 3段目: 独立した対戦枠見出し（文字切れなし！）
      expect(find.text('団体戦：道上剣友会A vs 相手チーム02'), findsOneWidget);
      // 4段目: 選手名（下段大文字）および取得部位（技マークライン）
      expect(find.text('皿田 脩人'), findsOneWidget);
      expect(find.text('相手 一郎'), findsOneWidget);
      expect(find.text('コ'), findsOneWidget); // 赤側コテ
      expect(find.text('メ'), findsOneWidget); // 白側メン
      expect(find.text('ー'), findsOneWidget); // セパレーター

      // 5段目: 通算・進行度（団体戦が1試合として集約）
      expect(find.text('進行: 0/1 試合'), findsOneWidget);

      // ----------------------------------------------------
      // Step 3: コート名タップでの直接編集シート起動＆復帰検証
      // ----------------------------------------------------
      // コート名（第3試合場 (2回戦・第3試合)）をタップ
      await tester.tap(find.text('第3試合場 (2回戦・第3試合)'));
      await tester.pumpAndSettle();

      // 「団体戦対戦の編集」ボトムシート（コート・メモタブ）が開いたことを確認
      expect(find.text('団体戦対戦の編集'), findsOneWidget);
      expect(find.text('コート・メモ'), findsOneWidget);
      expect(find.text('🏟️ 試合場（コート）を選択'), findsOneWidget);

      // 閉じるボタンをタップしてシートを閉じる
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // チーム試合状況画面に無事復帰していることを確認
      expect(find.text('チーム試合状況'), findsOneWidget);

      // ----------------------------------------------------
      // Step 4: フィルター操作の検証
      // ----------------------------------------------------
      // 「🔴 試合中のみ (1)」をタップ
      await tester.tap(find.text('🔴 試合中のみ (1)'));
      await tester.pumpAndSettle();

      expect(find.text('道上剣友会A'), findsNWidgets(2));
      expect(find.text('大阪選抜'), findsNothing);

      // 「すべて表示」をタップして全解除
      await tester.tap(find.text('すべて表示'));
      await tester.pumpAndSettle();

      expect(find.text('道上剣友会A'), findsNWidgets(2));
      expect(find.text('大阪選抜'), findsNWidgets(2));

      // ----------------------------------------------------
      // Step 5: 終了試合カードタップで団体戦スコアボード遷移検証
      // ----------------------------------------------------
      // 終了している大阪選抜のカードをタップ
      await tester.tap(find.text('大阪選抜').first);
      await tester.pumpAndSettle();

      // 団体戦スコアボード画面に遷移したことを確認
      expect(find.text('団体戦スコアボード画面: group_test_r1'), findsOneWidget);
    });
  });
}
