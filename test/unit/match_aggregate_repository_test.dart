import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_aggregate.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/shared/domain/repositories/event_store.dart';
import 'package:kendo_os/shared/domain/repositories/snapshot_store.dart';
import 'package:kendo_os/shared/infrastructure/repository/in_memory_event_store.dart';
import 'package:kendo_os/shared/infrastructure/repository/in_memory_snapshot_store.dart';
import 'package:kendo_os/shared/infrastructure/repository/match_aggregate_repository.dart';

void main() {
  late EventStore eventStore;
  late SnapshotStore snapshotStore;
  late MatchAggregateRepository repository;
  const matchRule = MatchRule();

  setUp(() {
    eventStore = InMemoryEventStore();
    snapshotStore = InMemorySnapshotStore();
    repository = MatchAggregateRepository(eventStore, snapshotStore);
  });

  group('[Unit] MatchAggregateRepository 単体テスト', () {
    test('loadによって初回および空状態からAggregateが正常生成されること', () async {
      final agg = await repository.load('match-1', matchRule);
      expect(agg.id, 'match-1');
      expect(agg.events, isEmpty);
      expect(agg.version, 0);
    });

    test('appendによりイベントが追記され50件到達時に自動スナップショットが保存されること', () async {
      var agg = await repository.load('match-1', matchRule);

      for (int i = 0; i < 49; i++) {
        final event = ScoreEvent(
          id: 'event-$i',
          side: Side.red,
          strikeType: StrikeType.men,
          timestamp: DateTime.now(),
        );
        agg = await repository.append(agg, event);
      }

      var snapshot = await snapshotStore.loadLatest('match-1');
      expect(snapshot, isNull);

      final event50 = ScoreEvent(
        id: 'event-50',
        side: Side.red,
        strikeType: StrikeType.kote,
        timestamp: DateTime.now(),
      );
      agg = await repository.append(agg, event50);

      snapshot = await snapshotStore.loadLatest('match-1');
      expect(snapshot, isNotNull);
      expect(snapshot!.version, 50);
      expect(snapshot.events.length, 50);
    });

    test('executeWithRetryにおいて並行競合発生時に再試行が走り3回以内に正常収束すること', () async {
      int actionCallCount = 0;
      final agg = await repository.executeWithRetry(
        'match-concurrent',
        matchRule,
        (currentAgg) {
          actionCallCount++;
          if (actionCallCount == 1) {
            // 別タスクが先回りして保存した状況をシミュレート
            eventStore.append(
              streamId: 'match-concurrent',
              events: [
                ScoreEvent(
                  id: 'other-task-event',
                  side: Side.white,
                  strikeType: StrikeType.dou,
                  timestamp: DateTime.now(),
                ),
              ],
              expectedVersion: 0,
            );
          }
          return ScoreEvent(
            id: 'my-event-$actionCallCount',
            side: Side.red,
            strikeType: StrikeType.men,
            timestamp: DateTime.now(),
          );
        },
      );

      expect(actionCallCount, 2);
      expect(agg.events.length, 2);
    });

    test('executeWithRetryにおいて3回連続競合した際にリトライ上限例外が送出されること', () async {
      expect(() async {
        await repository.executeWithRetry('match-conflict-limit', matchRule, (
          currentAgg,
        ) {
          // 毎回別タスクがバージョンを進めて競合を発生させる
          eventStore.append(
            streamId: 'match-conflict-limit',
            events: [
              ScoreEvent(
                id: 'conflict-${DateTime.now().microsecondsSinceEpoch}',
                side: Side.white,
                strikeType: StrikeType.tsuki,
                timestamp: DateTime.now(),
              ),
            ],
            expectedVersion: currentAgg.events.length,
          );
          return ScoreEvent(
            id: 'my-fail-event',
            side: Side.red,
            strikeType: StrikeType.men,
            timestamp: DateTime.now(),
          );
        });
      }, throwsA(isA<ConcurrencyException>()));
    });

    test('watchによりAggregateのストリームがイベント発行時に更新通知されること', () async {
      final stream = repository.watch('match-stream', matchRule);

      expectLater(
        stream,
        emitsInOrder([
          predicate<MatchAggregate>((agg) => agg.events.length == 1),
        ]),
      );

      await eventStore.append(
        streamId: 'match-stream',
        events: [
          ScoreEvent(
            id: 'evt-stream-1',
            side: Side.red,
            strikeType: StrikeType.men,
            timestamp: DateTime.now(),
          ),
        ],
        expectedVersion: 0,
      );
    });
  });
}
