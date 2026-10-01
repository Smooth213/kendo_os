import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_aggregate.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/shared/application/projections/match_projection.dart';
import 'package:kendo_os/shared/application/projections/projection_updater.dart';
import 'package:kendo_os/shared/domain/repositories/event_store.dart';
import 'package:kendo_os/shared/domain/repositories/projection_store.dart';

class _FakeEventStore implements EventStore {
  final _controllers = <String, StreamController<List<ScoreEvent>>>{};

  StreamController<List<ScoreEvent>> getController(String id) {
    return _controllers.putIfAbsent(
      id,
      () => StreamController<List<ScoreEvent>>.broadcast(),
    );
  }

  @override
  Stream<List<ScoreEvent>> watch(String streamId) =>
      getController(streamId).stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeProjectionStore implements ProjectionStore {
  @override
  Future<void> save(MatchProjection projection) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('[Governance] プロジェクション監視ストリーム明示解除およびメモリリークゼロ保証規約', () {
    test('stopWatchingおよびstopAllの実行によりストリーム購読が完全に破棄されメモリリークしないこと', () async {
      final fakeEventStore = _FakeEventStore();
      final fakeProjectionStore = _FakeProjectionStore();

      final updater = ProjectionUpdater(
        eventStore: fakeEventStore,
        projectionStore: fakeProjectionStore,
      );

      final match = MatchModel(
        id: 'leak-check-match',
        tournamentId: 't-1',
        matchType: '個人戦',
        redName: '選手A',
        whiteName: '選手B',
      );
      final aggregate = MatchAggregate(
        id: 'leak-check-match',
        events: const [],
        status: 'waiting',
        version: 0,
      );

      updater.startWatching(match, aggregate);

      // コントローラのリスナーが存在することを確認
      expect(
        fakeEventStore.getController('leak-check-match').hasListener,
        isTrue,
      );

      // 個別購読解除
      updater.stopWatching('leak-check-match');

      // リスナーが解除されていること
      expect(
        fakeEventStore.getController('leak-check-match').hasListener,
        isFalse,
      );

      // stopAll の呼出が安全に終了すること
      updater.startWatching(match, aggregate);
      expect(
        fakeEventStore.getController('leak-check-match').hasListener,
        isTrue,
      );
      updater.stopAll();
      expect(
        fakeEventStore.getController('leak-check-match').hasListener,
        isFalse,
      );
    });

    test('静的解析においてProjectionUpdaterが購読管理コレクションとキャンセル処理を保持すること', () {
      final file = File(
        'lib/shared/application/projections/projection_updater.dart',
      );
      expect(file.existsSync(), isTrue);

      final content = file.readAsStringSync();
      expect(content.contains('_subscriptions'), isTrue);
      expect(content.contains('cancel()'), isTrue);
      expect(content.contains('stopWatching'), isTrue);
      expect(content.contains('stopAll'), isTrue);
    });
  });
}
