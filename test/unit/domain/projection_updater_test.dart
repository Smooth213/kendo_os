import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_aggregate.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/application/projections/match_projection.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
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
  Stream<List<ScoreEvent>> watch(String streamId) {
    return getController(streamId).stream;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeProjectionStore implements ProjectionStore {
  final List<MatchProjection> savedProjections = [];

  @override
  Future<void> save(MatchProjection projection) async {
    savedProjections.add(projection);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('[Unit] CQRSプロジェクション自動更新および購読ライフサイクル単体テスト', () {
    test(
      'startWatchingにおいてイベント受信に伴いプロジェクションが生成保存されstopWatchingで解除されること',
      () async {
        final fakeEventStore = _FakeEventStore();
        final fakeProjectionStore = _FakeProjectionStore();

        final updater = ProjectionUpdater(
          eventStore: fakeEventStore,
          projectionStore: fakeProjectionStore,
        );

        final match = MatchModel(
          id: 'proj-match-1',
          tournamentId: 't-1',
          matchType: '個人戦',
          redName: '選手A',
          whiteName: '選手B',
        );

        final aggregate = MatchAggregate(
          id: 'proj-match-1',
          events: const [],
          status: 'ongoing',
          version: 0,
        );

        updater.startWatching(match, aggregate);

        // イベントを流す
        final ev = ScoreEvent(
          id: 'ev-proj-1',
          side: Side.red,
          strikeType: StrikeType.men,
          isIppon: true,
          timestamp: DateTime.now(),
        );

        fakeEventStore.getController('proj-match-1').add([ev]);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(fakeProjectionStore.savedProjections.length, 1);
        expect(fakeProjectionStore.savedProjections.first.id, 'proj-match-1');

        // 購読停止
        updater.stopWatching('proj-match-1');

        // 追加でイベントを流しても保存件数は増えない
        fakeEventStore.getController('proj-match-1').add([ev, ev]);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(fakeProjectionStore.savedProjections.length, 1);
      },
    );

    test('stopAllにおいてすべての監視ストリームが一括破棄されること', () async {
      final fakeEventStore = _FakeEventStore();
      final fakeProjectionStore = _FakeProjectionStore();

      final updater = ProjectionUpdater(
        eventStore: fakeEventStore,
        projectionStore: fakeProjectionStore,
      );

      final match1 = MatchModel(
        id: 'm-1',
        tournamentId: 't-1',
        matchType: '個',
        redName: 'A',
        whiteName: 'B',
      );
      final match2 = MatchModel(
        id: 'm-2',
        tournamentId: 't-1',
        matchType: '個',
        redName: 'C',
        whiteName: 'D',
      );

      final agg1 = MatchAggregate(
        id: 'm-1',
        events: const [],
        status: 'waiting',
        version: 0,
      );
      final agg2 = MatchAggregate(
        id: 'm-2',
        events: const [],
        status: 'waiting',
        version: 0,
      );

      updater.startWatching(match1, agg1);
      updater.startWatching(match2, agg2);

      updater.stopAll();

      fakeEventStore.getController('m-1').add([]);
      fakeEventStore.getController('m-2').add([]);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(fakeProjectionStore.savedProjections, isEmpty);
    });
  });
}
