import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/safe_timeline_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/team_progress_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/team_match_status_screen.dart';
import 'package:kendo_os/shared/domain/entities/player_model.dart';

void main() {
  group('🥋 チーム試合状況 ロジック＆UI統合テスト要塞', () {
    final testMatches = [
      // 団体戦第1対戦（先鋒・次鋒・中堅の3試合で1対戦カード）：進行中
      const MatchModel(
        id: 'team_a_m1',
        groupName: 'group_team_a_1',
        matchType: '団体戦 (先鋒)',
        redName: '相手10: 冨岡義勇',
        whiteName: '道上剣友会: 竈門炭治郎',
        status: 'finished',
        redScore: 0,
        whiteScore: 2,
        note: '第2コート, 1回戦, 4試合目',
        category: '小学生の部',
        order: 1.0,
      ),
      MatchModel(
        id: 'team_a_m2',
        groupName: 'group_team_a_1',
        matchType: '団体戦 (次鋒)',
        redName: '相手10: 鱗滝左近次',
        whiteName: '道上剣友会: 我妻善逸',
        status: 'in_progress',
        redScore: 1,
        whiteScore: 0,
        note: '第2コート, 1回戦, 4試合目',
        category: '小学生の部',
        order: 2.0,
        timerStartedAt: DateTime.now(),
      ),
      const MatchModel(
        id: 'team_a_m3',
        groupName: 'group_team_a_1',
        matchType: '団体戦 (中堅)',
        redName: '相手10: 錆兎',
        whiteName: '道上剣友会: 嘴平伊之助',
        status: 'waiting',
        note: '第2コート, 1回戦, 4試合目',
        category: '小学生の部',
        order: 3.0,
      ),

      // 中学生チーム: 1試合目(終了: 勝)
      const MatchModel(
        id: 'team_b_m1',
        matchType: '個人戦',
        redName: '雷鳴道場中学: 煉獄杏寿郎',
        whiteName: '炎陽塾: 宇髄天元',
        status: 'finished',
        redScore: 2,
        whiteScore: 1,
        note: '第3コート, 準決勝',
        category: '中学生の部',
        order: 1.0,
      ),
    ];

    test(
      '1. calculateTeamProgress: 相手側が赤でも自チーム名を100%正しく認識し、「第2コート (1回戦・第4試合)」を抽出すること',
      () {
        final progressList = calculateTeamProgress(
          testMatches,
          myDojoName: '道上',
          registeredTeamNames: ['道上剣友会', '雷鳴道場中学'],
          registeredPlayerNames: ['竈門炭治郎', '我妻善逸', '嘴平伊之助', '煉獄杏寿郎'],
        );

        expect(progressList.length, 2);

        // 道上剣友会の検証（「第2コート (1回戦・第4試合)」として抽出されること！）
        final teamA = progressList.firstWhere((t) => t.teamName == '道上剣友会');
        expect(teamA.totalCount, 1); // 1対戦
        expect(teamA.completedCount, 0); // 進行中
        expect(teamA.hasLiveMatch, isTrue);
        expect(teamA.inProgressMatch?.id, 'team_a_m2');
        expect(teamA.currentCourtName, '第2コート (1回戦・第4試合)');

        // 雷鳴道場中学チームの検証（「第3コート (準決勝)」として抽出されること！）
        final teamB = progressList.firstWhere((t) => t.teamName == '雷鳴道場中学');
        expect(teamB.totalCount, 1);
        expect(teamB.completedCount, 1);
        expect(teamB.hasLiveMatch, isFalse);
        expect(teamB.isAllFinished, isTrue);
        expect(teamB.totalWins, 1);
        expect(teamB.currentCourtName, '第3コート (準決勝)');
      },
    );

    testWidgets(
      '2. TeamMatchStatusScreen: UIヘッダー、自チーム名表示、LIVE表示、試合終了バッジ、フィルターが正常に動作すること',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              matchListProvider.overrideWithValue(testMatches),
              customTeamNamesProvider.overrideWith(
                (ref) => Stream.value(['道上剣友会', '雷鳴道場中学']),
              ),
              timelinePlayerListProvider.overrideWith(
                (ref) => Stream.value([
                  PlayerModel(
                    id: 'p1',
                    lastName: '竈門',
                    firstName: '炭治郎',
                    lastNameKana: 'かまど',
                    firstNameKana: 'たんじろう',
                    grade: 4,
                  ),
                  PlayerModel(
                    id: 'p2',
                    lastName: '我妻',
                    firstName: '善逸',
                    lastNameKana: 'あがつま',
                    firstNameKana: 'ぜんいつ',
                    grade: 4,
                  ),
                  PlayerModel(
                    id: 'p3',
                    lastName: '煉獄',
                    firstName: '杏寿郎',
                    lastNameKana: 'れんごく',
                    firstNameKana: 'きょうじゅろう',
                    grade: 6,
                  ),
                ]),
              ),
              currentDojoNameProvider.overrideWith((ref) => Stream.value('道上')),
            ],
            child: const MaterialApp(home: TeamMatchStatusScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // ヘッダー確認
        expect(find.text('チーム試合状況'), findsOneWidget);
        expect(find.text('全試合'), findsOneWidget);
        expect(find.text('🔴 試合中 (LIVE)'), findsOneWidget);

        // チームカード確認（ヘッダーおよび選手上段の道場名として道上剣友会が表示されること）
        expect(find.text('道上剣友会'), findsNWidgets(2));
        expect(find.text('雷鳴道場中学'), findsNWidgets(2));

        expect(find.text('試合中 (LIVE)'), findsOneWidget);
        // 全試合終了バッジが表示されること
        expect(find.text('🏁 全試合終了'), findsOneWidget);

        // 進行度: 道上剣友会が0/1試合、雷鳴道場中学が1/1試合
        expect(find.text('進行: 0/1 試合'), findsOneWidget);
        expect(find.text('進行: 1/1 試合'), findsOneWidget);

        // コート・回戦・試合順の表示確認
        expect(find.text('第2コート (1回戦・第4試合)'), findsOneWidget);

        // 道場名上・選手名下の表示確認
        expect(find.text('我妻善逸'), findsOneWidget);
        expect(find.text('鱗滝左近次'), findsOneWidget);

        // カテゴリ別タブの確認
        expect(find.text('全カテゴリ (2)'), findsOneWidget);

        // 「🔴 試合中のみ (1)」をタップしてフィルター
        await tester.tap(find.text('🔴 試合中のみ (1)'));
        await tester.pumpAndSettle();

        expect(find.text('道上剣友会'), findsNWidgets(2));
        expect(find.text('雷鳴道場中学'), findsNothing);

        // 「すべて表示」をタップして全解除
        await tester.tap(find.text('すべて表示'));
        await tester.pumpAndSettle();

        expect(find.text('道上剣友会'), findsNWidgets(2));
        expect(find.text('雷鳴道場中学'), findsNWidgets(2));
      },
    );
  });
}
