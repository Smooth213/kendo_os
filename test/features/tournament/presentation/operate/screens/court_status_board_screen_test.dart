import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/court_progress_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/safe_timeline_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/court_status_board_screen.dart';

void main() {
  group('🥋 マルチコート進行ステータスボード ロジック＆UI統合テスト要塞', () {
    final testMatches = [
      // 第1試合場: 1試合目(終了), 2試合目(LIVE/進行中), 3試合目(待機)
      const MatchModel(
        id: 'c1_m1',
        matchType: '先鋒',
        redName: '雷鳴道場: 竈門炭治郎',
        whiteName: '流水館: 冨岡義勇',
        status: 'finished',
        redScore: 2,
        whiteScore: 0,
        note: '第1試合場',
        order: 1.0,
      ),
      MatchModel(
        id: 'c1_m2',
        matchType: '次鋒',
        redName: '雷鳴道場: 我妻善逸',
        whiteName: '流水館: 鱗滝左近次',
        status: 'in_progress',
        redScore: 1,
        whiteScore: 0,
        note: '第1試合場',
        order: 2.0,
        timerStartedAt: DateTime.now(),
      ),
      const MatchModel(
        id: 'c1_m3',
        matchType: '中堅',
        redName: '雷鳴道場: 嘴平伊之助',
        whiteName: '流水館: 錆兎',
        status: 'waiting',
        note: '第1試合場',
        order: 3.0,
      ),

      // 第2試合場: 1試合目(LIVE/進行中/自道場)
      MatchModel(
        id: 'c2_m1',
        matchType: '先鋒',
        redName: '明鏡館: 煉獄杏寿郎',
        whiteName: '炎陽塾: 宇髄天元',
        status: 'in_progress',
        redScore: 0,
        whiteScore: 0,
        note: '第2試合場',
        order: 1.0,
        timerStartedAt: DateTime.now(),
      ),
    ];

    test(
      '1. calculateCourtProgress: 複数コートの進行・LIVE・直前終了・自チーム判定が100%正確に算出されること',
      () {
        final progressList = calculateCourtProgress(
          testMatches,
          myDojoName: '明鏡館',
        );

        expect(progressList.length, 2);

        // 第1試合場の検証
        final c1 = progressList.firstWhere((c) => c.courtName == '第1試合場');
        expect(c1.totalCount, 3);
        expect(c1.completedCount, 1);
        expect(c1.hasLiveMatch, isTrue);
        expect(c1.inProgressMatch?.id, 'c1_m2');
        expect(c1.lastFinishedMatch?.id, 'c1_m1');
        expect(c1.nextWaitingMatch?.id, 'c1_m3');
        expect(c1.hasMyDojoMatch, isFalse); // 明鏡館ではない

        // 第2試合場の検証
        final c2 = progressList.firstWhere((c) => c.courtName == '第2試合場');
        expect(c2.totalCount, 1);
        expect(c2.completedCount, 0);
        expect(c2.hasLiveMatch, isTrue);
        expect(c2.inProgressMatch?.id, 'c2_m1');
        expect(c2.hasMyDojoMatch, isTrue); // 明鏡館が出場中！
      },
    );

    testWidgets(
      '2. CourtStatusBoardScreen: UIヘッダー、バッジ、LIVE表示、フィルターが正常に動作すること',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              matchListProvider.overrideWithValue(testMatches),
              customTeamNamesProvider.overrideWith(
                (ref) => Stream.value(['明鏡館']),
              ),
              timelinePlayerListProvider.overrideWith(
                (ref) => Stream.value([]),
              ),
              currentDojoNameProvider.overrideWith(
                (ref) => Stream.value('明鏡館'),
              ),
            ],
            child: const MaterialApp(home: CourtStatusBoardScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // ヘッダー確認
        expect(find.text('マルチコート進行状況'), findsOneWidget);
        expect(find.text('全コート'), findsOneWidget);
        expect(find.text('🔴 試合中 (LIVE)'), findsOneWidget);

        // コートカード確認
        expect(find.text('第1試合場'), findsOneWidget);
        expect(find.text('第2試合場'), findsOneWidget);
        expect(find.text('LIVE 試合中'), findsNWidgets(2));
        expect(find.text('⭐ 自チーム'), findsOneWidget);

        // 進行中スコア確認
        expect(find.text('1 - 0'), findsOneWidget);
        expect(find.text('0 - 0'), findsOneWidget);

        // 直前終了試合の確認
        expect(find.textContaining('先鋒 (雷鳴道場: 竈門炭治郎 2-0'), findsOneWidget);

        // カテゴリ別タブの確認
        expect(find.text('全カテゴリ (2)'), findsOneWidget);
        expect(find.text('第1試合場 (1)'), findsWidgets); // チップとカード内テキスト
        expect(find.text('第2試合場 (1)'), findsWidgets);

        // カテゴリタブ「第1試合場 (1)」をタップして絞り込み
        await tester.tap(find.text('第1試合場 (1)'));
        await tester.pumpAndSettle();

        expect(find.text('第1試合場'), findsOneWidget);
        expect(find.text('第2試合場'), findsNothing);

        // 「全カテゴリ (2)」をタップして全解除
        await tester.tap(find.text('全カテゴリ (2)'));
        await tester.pumpAndSettle();

        expect(find.text('第1試合場'), findsOneWidget);
        expect(find.text('第2試合場'), findsOneWidget);

        // 「⭐ 自チームのみ」フィルターをタップ
        await tester.tap(find.text('⭐ 自チームのみ (1)'));
        await tester.pumpAndSettle();

        // 🔽 カテゴリタブの数字も上の絞り込み（自チームのみ）に連動して変化すること！
        expect(find.text('全カテゴリ (1)'), findsOneWidget);
        expect(find.text('第1試合場 (0)'), findsOneWidget);
        expect(find.text('第2試合場 (1)'), findsWidgets); // タブとカード内テキスト

        // 第2試合場のみ表示されること
        expect(find.text('第2試合場'), findsWidgets);
        expect(find.text('第1試合場'), findsNothing);

        // 「すべて表示」フィルターをタップ
        await tester.tap(find.text('すべて表示'));
        await tester.pumpAndSettle();

        // カテゴリタブの数字が全件（2件）に戻ること
        expect(find.text('全カテゴリ (2)'), findsOneWidget);
        expect(find.text('第1試合場 (1)'), findsWidgets);
        expect(find.text('第2試合場 (1)'), findsWidgets);

        // 再び全コート表示されること
        expect(find.text('第1試合場'), findsWidgets);
        expect(find.text('第2試合場'), findsWidgets);
      },
    );

    test(
      '3. UUID形式のgroupNameの場合、英数羅列を排除し対戦カード名（団体戦: チーム vs チーム、個人戦: 選手（道場） vs 選手（道場））が生成されること',
      () {
        final matchesWithUuid = [
          // 団体戦 (UUID groupName)
          const MatchModel(
            id: 'm_team_1',
            groupName: '14d50309-ce23-494e-9df2-d1b05f3caff0',
            matchType: '先鋒',
            redName: '道上剣友会: 久安 智也',
            whiteName: '相手チーム01: 選手01',
            status: 'finished',
            redScore: 1,
            whiteScore: 0,
          ),
          // 個人戦 (UUID groupName)
          const MatchModel(
            id: 'm_indiv_1',
            groupName: '26d77b42-b7b3-43f3-bbb6-c672883a2f52',
            matchType: '個人戦',
            redName: '道上剣友会: 皿田 脩人',
            whiteName: '◯◯道場: 田中 はじめ',
            status: 'in_progress',
            redScore: 0,
            whiteScore: 0,
          ),
        ];

        final progressList = calculateCourtProgress(matchesWithUuid);
        expect(progressList.length, 2);

        // 団体戦: 団体戦：道上剣友会 vs 相手チーム01
        final teamMatchProgress = progressList.firstWhere(
          (c) => c.courtName.contains('道上剣友会 vs 相手チーム01'),
        );
        expect(teamMatchProgress.courtName, '団体戦：道上剣友会 vs 相手チーム01');
        expect(teamMatchProgress.courtName.contains('14d50309'), isFalse);

        // 個人戦: 個人戦：皿田 脩人（道上剣友会） vs 田中 はじめ（◯◯道場）
        final indivMatchProgress = progressList.firstWhere(
          (c) => c.courtName.contains('皿田 脩人（道上剣友会）'),
        );
        expect(
          indivMatchProgress.courtName,
          '個人戦：皿田 脩人（道上剣友会） vs 田中 はじめ（◯◯道場）',
        );
        expect(indivMatchProgress.courtName.contains('26d77b42'), isFalse);
      },
    );

    test(
      '4. 錬成モード・申し合わせモードの場合、【錬成】団体戦：チーム vs チーム / 【申合せ】団体戦：チーム vs チーム となること',
      () {
        final renseiMatches = [
          const MatchModel(
            id: 'rensei_1',
            groupName: '11111111-2222-3333-4444-555555555555',
            matchType: '錬成会',
            redName: '道上剣友会: 皿田 脩人',
            whiteName: '流水館: 冨岡 義勇',
          ),
          const MatchModel(
            id: 'moushiawase_1',
            groupName: '66666666-7777-8888-9999-000000000000',
            matchType: '申し合わせ',
            redName: '道上剣友会: 久安 智也',
            whiteName: '炎陽塾: 宇髄 天元',
          ),
        ];

        final progressList = calculateCourtProgress(renseiMatches);
        expect(progressList.length, 2);

        final renseiProgress = progressList.firstWhere(
          (c) => c.courtName.startsWith('【錬成】'),
        );
        expect(renseiProgress.courtName, '【錬成】団体戦：道上剣友会 vs 流水館');

        final moushiawaseProgress = progressList.firstWhere(
          (c) => c.courtName.startsWith('【申合せ】'),
        );
        expect(moushiawaseProgress.courtName, '【申合せ】団体戦：道上剣友会 vs 炎陽塾');
      },
    );

    test(
      '5. 合同チーム（例: 「中四国選抜」）でチーム名が道場名と完全に異なっていても、所属選手名で自チームとして100%拾い上げられること',
      () {
        final jointMatches = [
          const MatchModel(
            id: 'joint_1',
            groupName: 'joint-group-uuid-001',
            matchType: '先鋒',
            redName: '中四国選抜連合: 皿田 脩人', // チーム名は「中四国選抜連合」だが選手は「皿田 脩人」
            whiteName: '関東代表チーム: 相手選手',
          ),
          const MatchModel(
            id: 'other_1',
            groupName: 'other-group-uuid-002',
            matchType: '先鋒',
            redName: '九州選抜: 他の選手A',
            whiteName: '東北選抜: 他の選手B',
          ),
        ];

        final progressList = calculateCourtProgress(
          jointMatches,
          myPlayerNames: {'皿田 脩人', '久安 智也'},
          myTeamNames: {'道上剣友会'},
        );

        expect(progressList.length, 2);

        // 中四国選抜連合の試合が自道場（hasMyDojoMatch: true）として判定されること
        final jointCourt = progressList.firstWhere(
          (c) => c.courtName.contains('中四国選抜連合'),
        );
        expect(jointCourt.hasMyDojoMatch, isTrue);

        // 他道場の試合は hasMyDojoMatch: false
        final otherCourt = progressList.firstWhere(
          (c) => c.courtName.contains('九州選抜'),
        );
        expect(otherCourt.hasMyDojoMatch, isFalse);
      },
    );

    test(
      '6. 3段構造（1段目: カテゴリ、2段目: 【錬成】団体戦：チーム vs チーム、3段目: 試合詳細メモ・アナウンス除外）が正しく構築されること',
      () {
        final matchesWithMemo = [
          const MatchModel(
            id: 'memo_match_1',
            groupName: 'group_001',
            category: '小学生の部',
            matchType: '錬成会',
            redName: '道上剣友会: 皿田 脩人',
            whiteName: '流水館: 冨岡 義勇',
            note: '第1コート\n2回戦, Bリーグ\n【本部アナウンス】第3試合場へ移動してください',
          ),
        ];

        final progressList = calculateCourtProgress(matchesWithMemo);
        expect(progressList.length, 1);

        final status = progressList.first;
        // 1段目: カテゴリ名（小学生の部）が最優先で採用されること
        expect(status.categoryName, '小学生の部');
        // 2段目: 対戦カード名
        expect(status.matchupTitle, '【錬成】団体戦：道上剣友会 vs 流水館');
        // 3段目: 試合詳細メモ（アナウンスが除外され、詳細メモのみ入ること）
        expect(status.detailNote, '第1コート / 2回戦, Bリーグ');
        expect(status.detailNote.contains('アナウンス'), isFalse);
      },
    );

    test('7. 試合詳細メモ（note）が空の場合、detailNoteが空文字となり3段目は非表示（2段のみ）となること', () {
      final matchesNoMemo = [
        const MatchModel(
          id: 'no_memo_match_1',
          groupName: 'group_002',
          category: '中学生の部',
          matchType: '先鋒',
          redName: '道上剣友会: 皿田 脩人',
          whiteName: '相手チーム: 相手選手',
        ),
      ];

      final progressList = calculateCourtProgress(matchesNoMemo);
      expect(progressList.length, 1);

      final status = progressList.first;
      expect(status.categoryName, '中学生の部');
      expect(status.matchupTitle, '団体戦：道上剣友会 vs 相手チーム');
      expect(status.detailNote, ''); // 空文字
    });

    test('8. 全試合完了したコートの進捗率が100%になり、進行中（LIVE）がfalseになること', () {
      final completedMatches = [
        const MatchModel(
          id: 'comp_1',
          groupName: 'comp_group_1',
          matchType: '先鋒',
          redName: '道上: 選手1',
          whiteName: '相手: 選手1',
          status: 'finished',
          order: 1.0,
        ),
        const MatchModel(
          id: 'comp_2',
          groupName: 'comp_group_1',
          matchType: '次鋒',
          redName: '道上: 選手2',
          whiteName: '相手: 選手2',
          status: 'finished',
          order: 2.0,
        ),
      ];

      final progressList = calculateCourtProgress(completedMatches);
      expect(progressList.length, 1);
      final status = progressList.first;
      expect(status.completedCount, 2);
      expect(status.totalCount, 2);
      expect(status.progressPercent, 100);
      expect(status.hasLiveMatch, isFalse);
    });

    testWidgets('9. 試合リストが空の場合、空状態UIが表示されること', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matchListProvider.overrideWithValue([]),
            customTeamNamesProvider.overrideWith((ref) => Stream.value([])),
            timelinePlayerListProvider.overrideWith((ref) => Stream.value([])),
            currentDojoNameProvider.overrideWith((ref) => Stream.value('')),
          ],
          child: const MaterialApp(home: CourtStatusBoardScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('該当するコートの試合はありません'), findsOneWidget);
    });

    testWidgets('10. ステータスフィルター × カテゴリタブの複合絞り込みが正確に連動・フィルタリングされること', (
      tester,
    ) async {
      final multiCatMatches = [
        // 小学生の部 (試合中)
        MatchModel(
          id: 'm_elem_live',
          category: '小学生の部',
          matchType: '先鋒',
          redName: '道上剣友会: 選手A',
          whiteName: '相手A: 選手X',
          status: 'in_progress',
          timerStartedAt: DateTime.now(),
        ),
        // 小学生の部 (待機中)
        const MatchModel(
          id: 'm_elem_wait',
          groupName: 'elem_wait_grp',
          category: '小学生の部',
          matchType: '次鋒',
          redName: '他道場A: 選手B',
          whiteName: '相手B: 選手Y',
          status: 'waiting',
        ),
        // 中学生の部 (試合中)
        MatchModel(
          id: 'm_junior_live',
          groupName: 'junior_live_grp',
          category: '中学生の部',
          matchType: '先鋒',
          redName: '他道場C: 選手C',
          whiteName: '相手C: 選手Z',
          status: 'in_progress',
          timerStartedAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matchListProvider.overrideWithValue(multiCatMatches),
            customTeamNamesProvider.overrideWith(
              (ref) => Stream.value(['道上剣友会']),
            ),
            timelinePlayerListProvider.overrideWith((ref) => Stream.value([])),
            currentDojoNameProvider.overrideWith(
              (ref) => Stream.value('道上剣友会'),
            ),
          ],
          child: const MaterialApp(home: CourtStatusBoardScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // 初期状態: 全3コート
      expect(find.text('全カテゴリ (3)'), findsOneWidget);
      expect(find.text('小学生の部 (2)'), findsOneWidget);
      expect(find.text('中学生の部 (1)'), findsOneWidget);

      // 「🔴 試合中のみ (2)」をタップ
      await tester.tap(find.text('🔴 試合中のみ (2)'));
      await tester.pumpAndSettle();

      // タブカウントが試合中件数（全2件、小学生1件、中学生1件）に連動！
      expect(find.text('全カテゴリ (2)'), findsOneWidget);
      expect(find.text('小学生の部 (1)'), findsOneWidget);
      expect(find.text('中学生の部 (1)'), findsOneWidget);

      // 「小学生の部 (1)」タブをタップして複合絞り込み
      await tester.tap(find.text('小学生の部 (1)'));
      await tester.pumpAndSettle();

      // 小学生の部の試合中カードのみ表示されること
      expect(find.text('小学生の部'), findsWidgets);
      expect(find.text('中学生の部'), findsNothing);
    });
  });
}
