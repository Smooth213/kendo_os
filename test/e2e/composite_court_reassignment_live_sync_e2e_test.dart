import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/application/mappers/match_projection_mapper.dart';
import 'package:kendo_os/features/match/application/usecases/match_rebuild_usecase.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/sync_crdt_merger.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/team_progress_helper.dart';
import 'package:kendo_os/shared/application/projections/match_projection.dart';
import 'package:kendo_os/shared/time/system_time_source.dart';

void main() {
  group('🏟️ 【複合E2E】コート急遽振替 × タイマー保持 × 観客PWAライブ追従E2Eテスト', () {
    test(
      '第1コート進行中試合の第3コートへの急遽振替時に、タイマー絶対時間・スコア・PendingEventsが完全保持され、観客PWAが即時追従すること',
      () async {
        final now = DateTime(2026, 9, 27, 10, 0, 0);
        final ruleEngine = KendoRuleEngine();
        final timeSource = SystemTimeSource();

        // 1. 第1試合場で試合開始・タイマー稼働（開始から60秒経過、一時停止10秒蓄積）
        //    赤が「面」を1本先取済み
        final menEvent = ScoreEvent(
          id: 'ev_e2e_men_1',
          side: Side.red,
          strikeType: StrikeType.men,
          isIppon: true,
          timestamp: now.add(const Duration(seconds: 30)),
          sequence: 1,
          logicalClock: 1,
        );

        final initialMatch = MatchModel(
          id: 'm_court_swap_e2e_01',
          tournamentId: 't_zenkoku',
          matchType: '個人戦',
          redName: '神武館: 佐藤',
          whiteName: '修道館: 田中',
          redScore: 1,
          whiteScore: 0,
          status: 'in_progress',
          note: '第1試合場, 準決勝, 1試合目',
          timerStartedAt: now,
          accumulatedPauseDurationMs: 10000,
          events: [menEvent],
          rule: const MatchRule(),
        );

        // 観客用Viewerが購読するリアルタイムStreamを模擬
        final viewerStreamController =
            StreamController<MatchProjection>.broadcast();
        addTearDown(viewerStreamController.close);

        final receivedProjections = <MatchProjection>[];
        final subscription = viewerStreamController.stream.listen((projection) {
          receivedProjections.add(projection);
        });
        addTearDown(subscription.cancel);

        // 初期状態配信
        final initialAnalysis = ruleEngine.analyzeHistory(
          initialMatch.events,
          initialMatch,
          const MatchRule(),
        );
        viewerStreamController.add(
          MatchProjectionMapper.toMatchProjection(
            initialMatch,
            initialAnalysis,
          ),
        );
        await pumpEventQueue();

        expect(receivedProjections.length, 1);
        expect(receivedProjections.first.redScore, 1);
        expect(
          TeamProgressHelper.extractCourtAndRoundDisplay(initialMatch),
          contains('第1試合場'),
        );

        // 2. 体育館の進行管理により、空いている「第3試合場」へ急遽コート振替を実行！
        //    同時にローカルで未送信の反則イベント（白反則1回目）が pendingEvents に存在
        final hansokuEvent = ScoreEvent(
          id: 'ev_e2e_hansoku_1',
          side: Side.white,
          isHansoku: true,
          timestamp: now.add(const Duration(seconds: 70)),
          sequence: 2,
          logicalClock: 2,
        );

        final courtReassignedLocalMatch = initialMatch.copyWith(
          note: '第3試合場, 準決勝, 1試合目',
          pendingEvents: [hansokuEvent],
        );

        // 3. CRDTマージ ＆ 整合性リビルド
        final rebuilder = RebuildMatchFromEventsUseCase(ruleEngine, timeSource);
        final mergedMatch = SyncCrdtMerger.mergeAndRebuild(
          remoteMatch: initialMatch,
          localMatch: courtReassignedLocalMatch,
          rule: const MatchRule(),
          rebuilder: rebuilder,
        );

        // 4. 検証: コートが第3試合場に変更されつつ、コアデータが一切破壊されていないこと
        expect(
          TeamProgressHelper.extractCourtAndRoundDisplay(mergedMatch),
          contains('第3試合場'),
        );
        expect(mergedMatch.timerStartedAt, initialMatch.timerStartedAt);
        expect(
          mergedMatch.accumulatedPauseDurationMs,
          initialMatch.accumulatedPauseDurationMs,
        );
        expect(mergedMatch.redScore, 1, reason: '先取した面が保持されていること');
        expect(mergedMatch.events.length, 2, reason: '面と反則が統合されていること');

        // 5. 観客席Viewerへ最新Projectionを配信
        final updatedAnalysis = ruleEngine.analyzeHistory(
          mergedMatch.events,
          mergedMatch,
          const MatchRule(),
        );
        viewerStreamController.add(
          MatchProjectionMapper.toMatchProjection(mergedMatch, updatedAnalysis),
        );
        await pumpEventQueue();

        // 6. 観客側でもリアルタイムに第3試合場への追従が完了していることを確認
        expect(receivedProjections.length, 2);
        final latestProjection = receivedProjections.last;
        expect(latestProjection.redScore, 1);
        expect(latestProjection.whiteScore, 0);
        expect(
          TeamProgressHelper.extractCourtAndRoundDisplay(mergedMatch),
          '第3試合場 (準決勝・第1試合)',
        );
      },
    );
  });
}
