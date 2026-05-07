import 'dart:async';
import 'package:kendo_os/domain/entities/score_event.dart';
import 'package:kendo_os/domain/repositories/event_store.dart';

/// 楽観的ロック（Optimistic Concurrency Control）失敗時の例外
class ConcurrencyException implements Exception {
  final String message;
  ConcurrencyException(this.message);
  @override
  String toString() => 'ConcurrencyException: $message';
}

/// A-2: 最も単純なインメモリ版 EventStore 実装
class InMemoryEventStore implements EventStore {
  final _store = <String, List<ScoreEvent>>{};
  final _controllers = <String, StreamController<List<ScoreEvent>>>{};

  // =========================================================================
  // ★ Phase 1-Step 3: マイグレーター作成
  // 古いバージョンのイベントデータがロードされた際、最新のスキーマに変換する
  // =========================================================================
  ScoreEvent _migrateEvent(ScoreEvent raw) {
    switch (raw.schemaVersion) {
      case 1:
        // v1 -> v2 への変換ロジック（現時点ではバージョンを引き上げるのみ）
        return raw.copyWith(schemaVersion: currentEventVersion);
      case 2:
        return raw; // 既に最新なのでそのまま
      default:
        // 将来的な未対応バージョンへのフォールバック
        return raw;
    }
  }

  @override
  Future<void> append({
    required String streamId,
    required List<ScoreEvent> events,
    required int expectedVersion,
  }) async {
    final current = _store[streamId] ?? [];
    
    // 楽観的ロックのチェック
    if (current.length != expectedVersion) {
      // ★ Phase 3-Step 3: 競合時の再適用の土台（後ほどApplicationServiceで処理）
      throw ConcurrencyException('同時更新の競合を検知しました。期待値: $expectedVersion, 実際: ${current.length}');
    }
    
    // 現在の最新の時計を取得
    int currentMaxClock = current.isEmpty ? 0 : current.map((e) => e.logicalClock).reduce((a, b) => a > b ? a : b);

    // 新しいイベントに時計を割り振る
    final updatedEvents = events.map((e) {
      currentMaxClock = (currentMaxClock >= e.logicalClock ? currentMaxClock : e.logicalClock) + 1;
      return e.copyWith(logicalClock: currentMaxClock);
    }).toList();

    // Append-onlyで状態を更新
    var next = [...current, ...updatedEvents];
    
    // ==========================================
    // ★ Phase 3-Step 4: 順序決定（ソート）
    // ==========================================
    next.sort((a, b) {
      // 1. 論理時計で比較
      int cmp = a.logicalClock.compareTo(b.logicalClock);
      if (cmp != 0) return cmp;
      // 2. 時計が同じなら実時間で比較
      cmp = a.timestamp.compareTo(b.timestamp);
      if (cmp != 0) return cmp;
      // 3. 完全に同じならID（文字列）で一意に決定
      return a.id.compareTo(b.id);
    });

    _store[streamId] = next;
    
    // ★ Phase 1-Step 4: ストリームに流す際も必ずマイグレーションを通す
    final migratedNext = next.map(_migrateEvent).toList();
    _controllers.putIfAbsent(streamId, () => StreamController<List<ScoreEvent>>.broadcast()).add(migratedNext);
  }

  @override
  Future<List<ScoreEvent>> load(String streamId) async {
    final rawEvents = _store[streamId] ?? [];
    // ★ Phase 1-Step 4: EventStoreからのロード時に組み込み
    final migratedEvents = rawEvents.map(_migrateEvent).toList();
    return List.unmodifiable(migratedEvents);
  }

  @override
  Stream<List<ScoreEvent>> watch(String streamId) {
    final controller = _controllers.putIfAbsent(streamId, () => StreamController<List<ScoreEvent>>.broadcast());
    return controller.stream;
  }
}