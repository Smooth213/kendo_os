import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/safe_timeline_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/team_match_status_screen.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';

void main() {
  group('🥋 【UI完全保証】チーム試合状況 全試合形式UI描画＆誤表示ゼロ検証テスト', () {
    final uiTestMatches = [
      // 1. トーナメント団体戦（進行中LIVE）
      MatchModel(
        id: 'm1_live',
        groupName: 'group_dohjo_a_r2',
        matchType: '先鋒戦',
        redName: '道上剣友会A: 皿田 脩人',
        whiteName: '相手チーム02: 相手 一郎',
        status: 'in_progress',
        redScore: 1,
        whiteScore: 0,
        note: '第3試合場 (2回戦)',
        category: '小学生低学年の部',
        order: 1.0,
        timerStartedAt: DateTime.now(),
      ),

      // 2. 錬成会団体戦（終了済）
      const MatchModel(
        id: 'm2_finished',
        groupName: 'group_test_rensei',
        matchType: '大将戦',
        redName: '相手チーム: 選手',
        whiteName: 'テスト: 久安 智也',
        status: 'finished',
        redScore: 0,
        whiteScore: 2,
        note: '【錬成会】',
        category: '小学生低学年の部',
        order: 2.0,
      ),

      // 3. 待機中団体戦
      const MatchModel(
        id: 'm3_waiting',
        groupName: 'group_dohjo_wait',
        matchType: '中堅戦',
        redName: '道上: 選手',
        whiteName: '相手06: 相手',
        status: 'waiting',
        category: '小学生低学年の部',
        order: 3.0,
      ),

      // 4. 個人戦（終了済）
      const MatchModel(
        id: 'm4_indiv',
        matchType: '個人戦',
        redName: '道上剣友会A: 久安 智也',
        whiteName: 'ライバル道場: 相手 太郎',
        status: 'finished',
        redScore: 2,
        whiteScore: 0,
        note: '第1コート, 準決勝',
        category: '小学生の部',
        order: 4.0,
      ),

      // 5. リーグ個人戦（待機中）
      const MatchModel(
        id: 'm5_league_indiv',
        matchType: 'リーグ個人戦',
        redName: '相手 次郎',
        whiteName: '皿田 脩人',
        status: 'waiting',
        note: '第2コート, Aリーグ',
        category: '小学生の部',
        order: 5.0,
      ),
    ];

    testWidgets('UI上で「全 5 試合」が表示され、誤ったリーグ団体戦表記が無く、全カードが正確に描画されること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matchListProvider.overrideWithValue(uiTestMatches),
            customTeamNamesProvider.overrideWith(
              (ref) => Stream.value(['道上剣友会A', 'テスト', '道上']),
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
          child: const MaterialApp(home: TeamMatchStatusScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // 1. ヘッダーカウンター: 5対戦カード（全5試合）が表示されていること
      expect(find.text('全試合'), findsOneWidget);
      expect(find.text('5'), findsWidgets); // 全試合バッジ内のカウント
      expect(find.text('🔴 試合中 (LIVE)'), findsOneWidget);
      expect(find.text('⏳ 待機中'), findsWidgets);

      // 2. 「リーグ団体戦」という誤表示が画面内に1件も存在しないこと！
      expect(find.textContaining('リーグ団体戦'), findsNothing);

      // 3. 正しい対戦見出しの描画確認
      // ① トーナメント団体戦（「団体戦：道上剣友会A vs 相手チーム02」）
      expect(find.text('団体戦：道上剣友会A vs 相手チーム02'), findsOneWidget);

      // ② 錬成会団体戦（2段目【錬成】バッジ + 3段目「団体戦：相手チーム vs テスト」）
      expect(find.text('【錬成】'), findsOneWidget);
      expect(find.text('団体戦：相手チーム vs テスト'), findsOneWidget);

      // ③ 待機中団体戦（「団体戦：道上 vs 相手06」）
      expect(find.text('団体戦：道上 vs 相手06'), findsOneWidget);

      // ④ 個人戦（「個人戦：久安 智也（道上剣友会A） vs 相手 太郎（ライバル道場）」）
      expect(find.text('個人戦：久安 智也（道上剣友会A） vs 相手 太郎（ライバル道場）'), findsOneWidget);

      // ⑤ リーグ個人戦（「リーグ個人戦：相手 次郎 vs 皿田 脩人」）
      expect(find.text('リーグ個人戦：相手 次郎 vs 皿田 脩人'), findsOneWidget);

      // 4. カテゴリタブのカウント確認
      expect(find.text('全カテゴリ (5)'), findsOneWidget);
      expect(find.text('小学生低学年の部 (3)'), findsOneWidget);
      expect(find.text('小学生の部 (2)'), findsOneWidget);
    });
  });
}
