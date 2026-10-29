import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_aggregate.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/shared/infrastructure/repository/in_memory_event_store.dart';
import 'package:kendo_os/shared/infrastructure/repository/in_memory_snapshot_store.dart';

void main() {
  group('[Unit] イベントソーシングおよび楽観的ロック基盤単体テスト', () {
    test('期待バージョン不一致時にConcurrencyExceptionが送出され重複競合更新が遮断されること', () async {
      final store = InMemoryEventStore();
      final now = DateTime.now();

      final ev1 = ScoreEvent(
        id: 'ev-1',
        side: Side.red,
        strikeType: StrikeType.men,
        isIppon: true,
        timestamp: now,
      );

      // 初回保存 (expectedVersion: 0) -> 成功
      await store.append(
        streamId: 'stream-1',
        events: [ev1],
        expectedVersion: 0,
      );

      final loaded = await store.load('stream-1');
      expect(loaded.length, 1);

      // 競合発生: 既に1件あるのに expectedVersion: 0 を指定して更新を試みる
      final ev2 = ScoreEvent(
        id: 'ev-2',
        side: Side.white,
        strikeType: StrikeType.kote,
        isIppon: true,
        timestamp: now,
      );

      expect(
        () => store.append(
          streamId: 'stream-1',
          events: [ev2],
          expectedVersion: 0,
        ),
        throwsA(isA<ConcurrencyException>()),
      );
    });

    test('論理時計が正しくインクリメント採番され決定論的3段階ソートが行われること', () async {
      final store = InMemoryEventStore();
      final baseTime = DateTime(2026, 1, 1, 10, 0, 0);

      final evA = ScoreEvent(
        id: 'ev-a',
        side: Side.red,
        strikeType: StrikeType.men,
        isIppon: true,
        timestamp: baseTime,
      );
      final evB = ScoreEvent(
        id: 'ev-b',
        side: Side.white,
        strikeType: StrikeType.dou,
        isIppon: true,
        timestamp: baseTime.add(const Duration(seconds: 1)),
      );

      await store.append(
        streamId: 'stream-sort',
        events: [evA, evB],
        expectedVersion: 0,
      );

      final loaded = await store.load('stream-sort');
      expect(loaded[0].logicalClock, 1);
      expect(loaded[1].logicalClock, 2);
      expect(loaded[0].id, 'ev-a');
      expect(loaded[1].id, 'ev-b');
    });

    test('InMemorySnapshotStoreにおいて集約スナップショットが保存および取得できること', () async {
      final snapshotStore = InMemorySnapshotStore();
      final match = MatchModel(
        id: 'match-snap-1',
        tournamentId: 't-1',
        matchType: '個人戦',
        redName: '選手1',
        whiteName: '選手2',
        status: 'ongoing',
      );

      final snapshot = MatchSnapshot(
        id: 'snap-1',
        matchId: 'match-snap-1',
        version: 1,
        state: match,
        createdAt: DateTime.now(),
        reason: '定期スナップショット',
      );

      expect(await snapshotStore.loadLatest('match-snap-1'), isNull);

      await snapshotStore.save(snapshot);

      final loaded = await snapshotStore.loadLatest('match-snap-1');
      expect(loaded, isNotNull);
      expect(loaded!.matchId, 'match-snap-1');
      expect(loaded.version, 1);
    });
  });
}
