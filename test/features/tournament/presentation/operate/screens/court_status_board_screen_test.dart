import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/court_progress_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/screens/court_status_board_screen.dart';

import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';

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
              currentDojoIdProvider.overrideWith((ref) => '明鏡館'),
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

        // 「⭐ 自チームのみ」フィルターをタップ
        await tester.tap(find.text('⭐ 自チームのみ (1)'));
        await tester.pumpAndSettle();

        // 第2試合場のみ表示されること
        expect(find.text('第2試合場'), findsOneWidget);
        expect(find.text('第1試合場'), findsNothing);

        // 「すべて表示」フィルターをタップ
        await tester.tap(find.text('すべて表示'));
        await tester.pumpAndSettle();

        // 再び全コート表示されること
        expect(find.text('第1試合場'), findsOneWidget);
        expect(find.text('第2試合場'), findsOneWidget);
      },
    );
  });
}
