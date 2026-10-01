import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/shared/infrastructure/repository/in_memory_event_store.dart';
import 'package:kendo_os/shared/infrastructure/repository/in_memory_snapshot_store.dart';
import 'package:kendo_os/shared/infrastructure/repository/match_aggregate_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[E2E] OCC楽観的排他制御＆自動修復並行収束テスト', () {
    test('並行書き込みによる競合発生時にexecuteWithRetryが最新状態を再取得して整合収束すること', () async {
      final eventStore = InMemoryEventStore();
      final snapshotStore = InMemorySnapshotStore();
      final repository = MatchAggregateRepository(eventStore, snapshotStore);

      const matchId = 'occ_concurrency_match_1';
      const rule = MatchRule(matchTimeMinutes: 3);

      // 初期状態のロード（0件）
      final initialAgg = await repository.load(matchId, rule);
      expect(initialAgg.version, 0);

      // クライアントAが「赤の面」イベントを生成して保存
      final eventA = ScoreEvent(
        id: 'event_occ_a',
        side: Side.red,
        strikeType: StrikeType.men,
        isIppon: true,
        timestamp: DateTime.now(),
        logicalClock: 1,
      );

      // クライアントBが「白の小手」イベントを生成しようとする（initialAggをベースにしているためバージョン競合が起きる状態）
      final eventB = ScoreEvent(
        id: 'event_occ_b',
        side: Side.white,
        strikeType: StrikeType.kote,
        isIppon: true,
        timestamp: DateTime.now(),
        logicalClock: 1,
      );

      // 1. クライアントAが先にappendを実行
      await repository.append(initialAgg, eventA);

      // 2. クライアントBが古いinitialAggでappendしようとするとConcurrencyExceptionが発生することを確認
      expect(
        () => repository.append(initialAgg, eventB),
        throwsA(isA<ConcurrencyException>()),
      );

      // 3. クライアントBがexecuteWithRetryを使用すると自動で最新Aggをロードして再試行・適用されること
      final finalAgg = await repository.executeWithRetry(matchId, rule, (
        currentAgg,
      ) {
        return ScoreEvent(
          id: 'event_occ_b_repaired',
          side: Side.white,
          strikeType: StrikeType.kote,
          isIppon: true,
          timestamp: DateTime.now(),
          logicalClock: currentAgg.events.length + 1,
        );
      });

      // 4. イベントロストが0件で、両方のイベントが完全に収束していることを検証
      expect(finalAgg.version, 2);
      expect(finalAgg.events.length, 2);
      expect(finalAgg.events[0].id, 'event_occ_a');
      expect(finalAgg.events[1].id, 'event_occ_b_repaired');

      // 5. リポジトリ再ロード後も完全整合していること
      final reloadedAgg = await repository.load(matchId, rule);
      expect(reloadedAgg.events.length, 2);
    });

    test('3回連続で競合し続けた場合はConcurrencyExceptionが正しくスローされること', () async {
      final eventStore = InMemoryEventStore();
      final snapshotStore = InMemorySnapshotStore();
      final repository = MatchAggregateRepository(eventStore, snapshotStore);

      const matchId = 'occ_retry_exhaust_match';
      const rule = MatchRule(matchTimeMinutes: 3);

      expect(
        () => repository.executeWithRetry(matchId, rule, (currentAgg) {
          // 意図的に別の並行書き込みをバックグラウンドで行い、常に先を越される状況を擬似生成
          eventStore.append(
            streamId: matchId,
            events: [
              ScoreEvent(
                id: 'stealth_${DateTime.now().microsecondsSinceEpoch}',
                side: Side.red,
                strikeType: StrikeType.dou,
                timestamp: DateTime.now(),
              ),
            ],
            expectedVersion: currentAgg.events.length,
          );

          return ScoreEvent(
            id: 'my_event',
            side: Side.white,
            strikeType: StrikeType.tsuki,
            timestamp: DateTime.now(),
          );
        }),
        throwsA(isA<ConcurrencyException>()),
      );
    });
  });
}
