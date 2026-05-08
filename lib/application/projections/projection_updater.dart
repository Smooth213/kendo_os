import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/domain/entities/match_aggregate.dart';
import 'package:kendo_os/domain/entities/match_model.dart';
import 'package:kendo_os/domain/services/kendo_rule_engine.dart';
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
      // 1. 真実のドメイン状態（Aggregate）を再構築
      final updatedAggregate = baseAggregate.copyWith(events: events);
      
      // 2. 共通の計算エンジン（RuleEngine）で解析
      final engine = KendoRuleEngine();
      final mergedModel = baseModel.copyWith(
        events: events,
        status: updatedAggregate.status,
      );
      final analysis = engine.analyzeHistory(events, mergedModel, mergedModel.rule);

      // 3. ★ Phase 5-1: 用途別に異なる3種類のProjectionを同時に生成
      final richProjection = MatchProjectionMapper.toMatchProjection(mergedModel, analysis);
      // final listProjection = MatchProjectionMapper.toListProjection(mergedModel, analysis); // ★ 将来的なキャッシュ拡張用
      
      // 4. ProjectionStoreに保存
      await projectionStore.save(richProjection);
      // await projectionStore.saveListCache(listProjection); // 拡張予定
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