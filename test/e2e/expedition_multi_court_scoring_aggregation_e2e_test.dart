import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/expedition_detail_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/expedition_event_processor.dart';
import 'package:kendo_os/features/tournament/presentation/components/official_record/expedition_stats_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[E2E] 複数コート遠征打突自動集計および詳細モーダル連携結合テスト', () {
    testWidgets('複数コートでの試合スコアから自チーム打突内訳が集計されボトムシートで閲覧できること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final now = DateTime.now();

      // 第1コートでの試合
      final court1Match = MatchModel(
        id: 'c1-m1',
        tournamentId: 't-exp',
        matchType: '先鋒',
        groupName: '予選A',
        redName: '遠征道場:山田',
        whiteName: '対戦道場A:佐々木',
        status: 'finished',
        events: [
          ScoreEvent(
            id: 'ev-c1-1',
            isIppon: true,
            side: Side.red,
            strikeType: StrikeType.men,
            timestamp: now,
          ),
          ScoreEvent(
            id: 'ev-c1-2',
            isIppon: true,
            side: Side.red,
            strikeType: StrikeType.kote,
            timestamp: now,
          ),
        ],
      );

      // 第2コートでの試合
      final court2Match = MatchModel(
        id: 'c2-m1',
        tournamentId: 't-exp',
        matchType: '次鋒',
        groupName: '予選A',
        redName: '対戦道場B:伊藤',
        whiteName: '遠征道場:佐藤',
        status: 'finished',
        events: [
          ScoreEvent(
            id: 'ev-c2-1',
            isIppon: true,
            side: Side.white,
            strikeType: StrikeType.dou,
            timestamp: now,
          ),
          ScoreEvent(
            id: 'ev-c2-2',
            isIppon: true,
            side: Side.red,
            strikeType: StrikeType.men,
            timestamp: now,
          ),
        ],
      );

      final playerStatsMap = <String, DetailedPlayerStats>{};

      // 遠征成績集計プロセッサによる複数コートの集計
      final stats = ExpeditionEventProcessor.processEvents(
        matches: [court1Match, court2Match],
        selectedSummaryTeam: '全体',
        isMyTeam: (team) => team == '遠征道場',
        isMyPlayer: (player, team) => team == '遠征道場',
        isMatchPlayed: (m) => m.status == 'finished',
        playerStatsMap: playerStatsMap,
      );

      expect(stats.teamMen, 1);
      expect(stats.teamKote, 1);
      expect(stats.teamDou, 1);
      expect(stats.teamTotalScored, 3);
      expect(stats.teamTotalConceded, 1);

      late BuildContext capturedContext;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  capturedContext = context;
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );

      // 詳細ボトムシートを開く
      ExpeditionDetailBottomSheet.show(
        context: capturedContext,
        isDark: false,
        teamName: '遠征道場',
        teamMen: stats.teamMen,
        teamKote: stats.teamKote,
        teamDou: stats.teamDou,
        teamTsuki: stats.teamTsuki,
        teamHansoku: stats.teamHansoku,
        teamOther: stats.teamOther,
        totalScored: stats.teamTotalScored,
        totalConceded: stats.teamTotalConceded,
        cardResults: [],
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('成績 詳細分析 (遠征道場)'), findsOneWidget);
      expect(find.text('総取得本数: 3本'), findsOneWidget);
      expect(find.text('総失本数: 1本'), findsOneWidget);
      expect(find.text('得失差: +2'), findsOneWidget);
    });
  });
}
