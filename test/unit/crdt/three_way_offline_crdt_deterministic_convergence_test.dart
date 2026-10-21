import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/application/usecases/match_rebuild_usecase.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/sync_crdt_merger.dart';
import 'package:kendo_os/shared/time/system_time_source.dart';

void main() {
  group('[Unit] 3端末オフライン同時編集・CRDT決定論的収束テスト', () {
    test('3台の端末（スコア入力、タイマー操作、ルール設定）がオフライン編集後、マージ順序に依存せず同一状態に収束すること', () {
      final now = DateTime(2026, 10, 2, 10, 0);
      final rebuilder = RebuildMatchFromEventsUseCase(
        KendoRuleEngine(),
        SystemTimeSource(),
      );

      // 共通のベース試合
      final baseMatch = MatchModel(
        id: 'crdt_convergence_01',
        matchType: '個人戦',
        redName: '選手赤',
        whiteName: '選手白',
        status: 'in_progress',
        redScore: 0,
        whiteScore: 0,
        rule: const MatchRule(matchTimeMinutes: 3.0),
      );

      // 端末A: スコア入力（赤・メン1本、logicalClock: 1）
      final eventA = ScoreEvent(
        id: 'ev_a_men',
        side: Side.red,
        strikeType: StrikeType.men,
        isIppon: true,
        timestamp: now.add(const Duration(seconds: 15)),
        logicalClock: 1,
        deviceId: 'device_A',
      );
      final matchA = baseMatch.copyWith(events: [eventA]);

      // 端末B: タイマー操作（一時停止時間蓄積 3000ms、logicalClock: 2）
      final matchB = baseMatch.copyWith(
        timerStartedAt: now,
        accumulatedPauseDurationMs: 3000,
      );

      // 端末C: スコア入力（白・コテ1本、logicalClock: 3）
      final eventC = ScoreEvent(
        id: 'ev_c_kote',
        side: Side.white,
        strikeType: StrikeType.kote,
        isIppon: true,
        timestamp: now.add(const Duration(seconds: 40)),
        logicalClock: 3,
        deviceId: 'device_C',
      );
      final matchC = baseMatch.copyWith(events: [eventC]);

      // パターン1: A -> B -> C の順でマージ
      final mergeAB1 = SyncCrdtMerger.mergeAndRebuild(
        remoteMatch: matchB,
        localMatch: matchA,
        rebuilder: rebuilder,
        rule: const MatchRule(matchTimeMinutes: 3.0),
      );
      final finalMerge1 = SyncCrdtMerger.mergeAndRebuild(
        remoteMatch: matchC,
        localMatch: mergeAB1,
        rebuilder: rebuilder,
        rule: const MatchRule(matchTimeMinutes: 3.0),
      );

      // パターン2: C -> B -> A の順でマージ
      final mergeCB2 = SyncCrdtMerger.mergeAndRebuild(
        remoteMatch: matchB,
        localMatch: matchC,
        rebuilder: rebuilder,
        rule: const MatchRule(matchTimeMinutes: 3.0),
      );
      final finalMerge2 = SyncCrdtMerger.mergeAndRebuild(
        remoteMatch: matchA,
        localMatch: mergeCB2,
        rebuilder: rebuilder,
        rule: const MatchRule(matchTimeMinutes: 3.0),
      );

      // 検証: マージ順序に関わらず、イベント・スコア・タイマー状態が完全一致（決定論的収束）
      expect(finalMerge1.redScore, finalMerge2.redScore);
      expect(finalMerge1.whiteScore, finalMerge2.whiteScore);
      expect(finalMerge1.redScore, 1);
      expect(finalMerge1.whiteScore, 1);
      expect(finalMerge1.events.length, 2);
      expect(finalMerge2.events.length, 2);
      expect(
        finalMerge1.accumulatedPauseDurationMs,
        finalMerge2.accumulatedPauseDurationMs,
      );
    });
  });
}
