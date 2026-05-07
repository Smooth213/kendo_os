import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/domain/entities/match_aggregate.dart';
import 'package:kendo_os/domain/entities/match_model.dart';
import 'package:kendo_os/domain/repositories/event_store.dart';
import 'package:kendo_os/domain/repositories/projection_store.dart';
import 'package:kendo_os/infrastructure/repository/match_aggregate_repository.dart';
import 'package:kendo_os/infrastructure/repository/in_memory_projection_store.dart';
import 'package:kendo_os/application/mappers/match_projection_mapper.dart';

final projectionUpdaterProvider = Provider<ProjectionUpdater>((ref) {
  return ProjectionUpdater(
    eventStore: ref.read(eventStoreProvider),
    projectionStore: ref.read(projectionStoreProvider),
  );
});

/// B-3: EventStoreの変更を監視し、非同期にProjectionを生成・保存するエンジン
/// 真のCQRS（Command Query Responsibility Segregation）を実現するための要となるクラス
class ProjectionUpdater {
  final EventStore eventStore;
  final ProjectionStore projectionStore;
  
  // メモリリークを防ぐため、購読中のストリームを保持する
  final _subscriptions = <String, StreamSubscription>{};

  ProjectionUpdater({
    required this.eventStore,
    required this.projectionStore,
  });

  /// 指定した試合（Match）の監視を開始し、変更があるたびにProjectionを更新する
  void startWatching(MatchModel baseModel, MatchAggregate baseAggregate) {
    final matchId = baseModel.id;
    if (_subscriptions.containsKey(matchId)) return; // 既に監視中なら何もしない

    _subscriptions[matchId] = eventStore.watch(matchId).listen((events) async {
      // 1. 新しいイベントリストを使ってAggregate（集約）を再構築する
      final updatedAggregate = baseAggregate.copyWith(events: events);

      // 2. Mapperを使って、純粋なAggregateとUI用メタデータ(baseModel)を合体させてProjectionを作る
      final projection = MatchProjectionMapper.fromAggregate(updatedAggregate, baseModel);

      // 3. ProjectionStoreに保存する（これがUIにリアルタイム配信される）
      await projectionStore.save(projection);
    });
  }

  /// 監視を停止する（画面を閉じた時やアプリ終了時など）
  void stopWatching(String matchId) {
    _subscriptions[matchId]?.cancel();
    _subscriptions.remove(matchId);
  }

  /// 全ての監視を停止する
  void stopAll() {
    for (var sub in _subscriptions.values) {
      sub.cancel();
    }
    _subscriptions.clear();
  }
}