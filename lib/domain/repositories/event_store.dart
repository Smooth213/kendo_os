import 'package:kendo_os/domain/entities/score_event.dart';

abstract class EventStore {
  /// イベントをストリームの末尾に追加します
  /// [expectedVersion] を用いて楽観的並行性制御（Optimistic Concurrency Control）を行います
  Future<void> append({
    required String streamId,
    required List<ScoreEvent> events,
    required int expectedVersion,
  });

  /// 指定したストリームIDの全イベント履歴をロードします
  Future<List<ScoreEvent>> load(String streamId);

  /// 指定したストリームIDのイベントの追加をリアルタイムで購読します
  Stream<List<ScoreEvent>> watch(String streamId);
}