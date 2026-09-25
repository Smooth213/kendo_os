import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/match/application/usecases/match_rebuild_usecase.dart';
import 'package:kendo_os/features/match/application/mappers/match_projection_mapper.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/sync_crdt_merger.dart';
import 'package:kendo_os/shared/application/projections/match_projection.dart';
import 'package:kendo_os/shared/time/system_time_source.dart';

void main() {
  group('🌐 【E2E】運営者入力 〜 観客席Webビューア即時追従E2Eテスト', () {
    test('運営者の得点入力がStreamを通じて観客席Webビューアへ即時伝播・同期されること', () async {
      final now = DateTime(2026, 9, 25, 11, 0, 0);
      final ruleEngine = KendoRuleEngine();
      final timeSource = SystemTimeSource();

      // 初期試合状態
      final initialMatch = MatchModel(
        id: 'sync_match_e2e_01',
        tournamentId: 'tourney_sync_e2e',
        matchType: '個人戦',
        redName: '神武館: 佐藤',
        whiteName: '修道館: 田中',
        redScore: 0,
        whiteScore: 0,
        status: 'in_progress',
        rule: const MatchRule(),
      );

      // 観客席ビューアが購読するリアルタイムStreamを模擬
      final matchStreamController =
          StreamController<MatchProjection>.broadcast();
      addTearDown(matchStreamController.close);

      final receivedProjections = <MatchProjection>[];
      final subscription = matchStreamController.stream.listen((projection) {
        receivedProjections.add(projection);
      });
      addTearDown(subscription.cancel);

      // 初期状態の分析とProjection配信
      final initialAnalysis = ruleEngine.analyzeHistory(
        initialMatch.events,
        initialMatch,
        const MatchRule(),
      );
      matchStreamController.add(
        MatchProjectionMapper.toMatchProjection(initialMatch, initialAnalysis),
      );
      await pumpEventQueue();

      expect(receivedProjections.length, 1);
      expect(receivedProjections.first.redScore, 0);
      expect(receivedProjections.first.whiteScore, 0);

      // 1. 運営者が赤に「面」を入力
      final menEvent = ScoreEvent(
        id: 'ev_op_men',
        side: Side.red,
        strikeType: StrikeType.men,
        isIppon: true,
        timestamp: now,
        sequence: 1,
        logicalClock: 1,
      );

      // 2. CRDT同期マージとRebuildを実行
      final rebuilder = RebuildMatchFromEventsUseCase(ruleEngine, timeSource);
      final updatedMatch = SyncCrdtMerger.mergeAndRebuild(
        remoteMatch: initialMatch,
        localMatch: initialMatch.copyWith(events: [menEvent]),
        rule: const MatchRule(),
        rebuilder: rebuilder,
      );

      // 3. 更新された分析結果からProjectionを生成し、観客席ビューアのStreamへ配信
      final updatedAnalysis = ruleEngine.analyzeHistory(
        updatedMatch.events,
        updatedMatch,
        const MatchRule(),
      );
      matchStreamController.add(
        MatchProjectionMapper.toMatchProjection(updatedMatch, updatedAnalysis),
      );
      await pumpEventQueue();

      // 4. 観客席ビューア側で即座に赤1本（メ）が反映されていることの検証
      expect(receivedProjections.length, 2);
      final latestViewerState = receivedProjections.last;
      expect(latestViewerState.redScore, 1);
      expect(latestViewerState.whiteScore, 0);
      expect(latestViewerState.redName, '神武館: 佐藤');
      expect(latestViewerState.whiteName, '修道館: 田中');
      expect(latestViewerState.redPointMarks.contains('メ'), isTrue);
    });
  });
}
