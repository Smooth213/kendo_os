import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart'; // UUID生成用に追加
import 'package:kendo_os/domain/entities/match_aggregate.dart';
import 'package:kendo_os/domain/entities/match_model.dart'; // BaseModel生成用に追加
import 'package:kendo_os/domain/entities/score_event.dart';
import 'package:kendo_os/domain/rules/match_rule.dart';
import 'package:kendo_os/domain/repositories/event_store.dart';
import 'package:kendo_os/domain/repositories/snapshot_store.dart';
import 'package:kendo_os/infrastructure/repository/in_memory_event_store.dart';
import 'package:kendo_os/infrastructure/repository/in_memory_snapshot_store.dart';

// EventStoreをDI（依存性の注入）するためのProvider
final eventStoreProvider = Provider<EventStore>((ref) {
  return InMemoryEventStore(); 
});

final snapshotStoreProvider = Provider<SnapshotStore>((ref) {
  return InMemorySnapshotStore();
});

final matchAggregateRepositoryProvider = Provider<MatchAggregateRepository>((ref) {
  return MatchAggregateRepository(
    ref.read(eventStoreProvider),
    ref.read(snapshotStoreProvider),
  );
});

/// A-3 & Phase 2 & 3: EventStoreとSnapshotStoreを繋ぎ、競合解決を行う中枢
class MatchAggregateRepository {
  final EventStore store;
  final SnapshotStore snapshotStore;

  MatchAggregateRepository(this.store, this.snapshotStore);

  Future<MatchAggregate> load(String matchId, MatchRule rule) async {
    final snapshot = await snapshotStore.loadLatest(matchId);
    final events = await store.load(matchId);
    final baseModel = MatchModel(id: matchId, matchType: 'individual', redName: '赤', whiteName: '白');
    return MatchAggregate.rehydrate(matchId, snapshot, events, baseModel);
  }

  /// Aggregateに新しいイベントを追記して永続化し、新しいAggregateを返す
  Future<MatchAggregate> append(MatchAggregate agg, ScoreEvent event) async {
    await store.append(
      streamId: agg.id,
      events: [event],
      expectedVersion: agg.events.length, // 楽観的ロックのためのバージョン渡し
    );
    
    final newEvents = await store.load(agg.id);

    // ==========================================
    // Phase 2-Step 4: 保存トリガー（性能最適化の核）
    // ==========================================
    if (newEvents.isNotEmpty && newEvents.length % 50 == 0) {
      final snapshot = MatchSnapshot(
        id: const Uuid().v4(),
        matchId: agg.id,
        version: newEvents.length,
        state: MatchModel(id: agg.id, matchType: 'individual', redName: '赤', whiteName: '白'),
        createdAt: DateTime.now(),
        reason: 'Auto Snapshot at ${newEvents.length} events',
        events: newEvents,
      );
      await snapshotStore.save(snapshot);
    }

    return agg.copyWith(events: newEvents, version: newEvents.length);
  }

  // ==========================================
  // ★ Phase 3-Step 3: 競合時のオートリペア（自動再適用ループ）
  // 同時入力で弾かれても、自動で再取得してねじ込む無敵のメソッド
  // ==========================================
  Future<MatchAggregate> executeWithRetry(
    String matchId,
    MatchRule rule,
    ScoreEvent Function(MatchAggregate currentAgg) action,
  ) async {
    int attempts = 0;
    while (attempts < 3) {
      try {
        // 1. 最新の歴史を取得
        final currentAgg = await load(matchId, rule);
        
        // 2. その歴史に対して、自分がやりたい操作（イベント生成）を適用
        final newEvent = action(currentAgg);
        
        // 3. 保存を試みる（ここで他人に先を越されていたら例外が飛ぶ）
        return await append(currentAgg, newEvent);
      } on ConcurrencyException {
        // 4. 競合を検知したら、回数をカウントして最初（最新取得）からやり直す！
        attempts++;
        if (attempts >= 3) {
          rethrow; // 3回連続でぶつかったら諦める
        }
      }
    }
    throw ConcurrencyException('リトライ上限に達しました');
  }

  Stream<MatchAggregate> watch(String matchId, MatchRule rule) {
    return store.watch(matchId).map((events) {
      return MatchAggregate(
        id: matchId,
        events: events,
        version: events.length,
        status: 'waiting',
        remainingSeconds: 180,
        timerIsRunning: false,
      );
    });
  }
}