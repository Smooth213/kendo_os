import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/shared/infrastructure/repository/in_memory_event_store.dart';

void main() {
  group('[Unit] 同時多発打突入力OCC競合調停およびCRDT収束テスト', () {
    test('ミリ秒単位の同時打突入力で競合発生時に再試行と整列によりデータ消失なく同一スコアへ収束すること', () async {
      final store = InMemoryEventStore();
      final streamId = 'match_concurrent_stream_1';
      final baseTime = DateTime(2026, 10, 2, 14, 0, 0);

      // 端末A（赤側記録員）からの赤面
      final eventFromClientA = ScoreEvent(
        id: 'ev_client_a_men',
        side: Side.red,
        strikeType: StrikeType.men,
        isIppon: true,
        timestamp: baseTime.add(const Duration(milliseconds: 100)),
      );

      // 端末B（白側記録員）からの白小手（ほぼ同時、タイムスタンプが5ms遅い）
      final eventFromClientB = ScoreEvent(
        id: 'ev_client_b_kote',
        side: Side.white,
        strikeType: StrikeType.kote,
        isIppon: true,
        timestamp: baseTime.add(const Duration(milliseconds: 105)),
      );

      // 端末Aが expectedVersion: 0 で先に書き込み成功
      await store.append(
        streamId: streamId,
        events: [eventFromClientA],
        expectedVersion: 0,
      );

      // 端末Bも expectedVersion: 0 で書き込もうとして OCC 競合（ConcurrencyException）を検知
      bool conflictDetected = false;
      try {
        await store.append(
          streamId: streamId,
          events: [eventFromClientB],
          expectedVersion: 0,
        );
      } on ConcurrencyException {
        conflictDetected = true;
      }
      expect(conflictDetected, isTrue);

      // 端末Bが最新イベントをロードし、再試行（expectedVersion: 1 でアペンド）
      final currentEvents = await store.load(streamId);
      expect(currentEvents.length, 1);

      await store.append(
        streamId: streamId,
        events: [eventFromClientB],
        expectedVersion: currentEvents.length,
      );

      // 最終ストリームの確認
      final finalEvents = await store.load(streamId);
      expect(finalEvents.length, 2);

      // ドメインルールエンジンでスコア再計算（Replay）し、1-1の同点状態に収束すること
      final ruleEngine = KendoRuleEngine();
      final match = MatchModel(
        id: 'm_concurrent_occ',
        redName: '赤選手',
        whiteName: '白選手',
        matchType: '個人戦',
      );

      final analysis = ruleEngine.analyzeHistory(
        finalEvents,
        match,
        match.rule,
      );
      expect(analysis.context.redIppon, 1);
      expect(analysis.context.whiteIppon, 1);
    });
  });
}
