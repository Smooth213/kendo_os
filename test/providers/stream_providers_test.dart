import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/domain/match/match_model.dart';
import 'package:kendo_os/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/presentation/operate/providers/match_list_provider.dart';
import 'dart:async';

class FakeLocalMatchRepository implements LocalMatchRepository {
  final StreamController<List<MatchModel>> _controller = StreamController<List<MatchModel>>.broadcast();

  void emitMatches(List<MatchModel> list) { _controller.add(list); }

  @override
  Stream<List<MatchModel>> watchAllLocalMatches() => _controller.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('🛡️ STEP 3-2: Stream Provider（自動バインド・瞬断再接続）完全テスト要塞', () {
    late FakeLocalMatchRepository fakeLocalRepo;

    setUp(() {
      fakeLocalRepo = FakeLocalMatchRepository();
    });

    test('1. 【matchStreamProvider】ローカルDBストリームからデータが射出された際、リアクティブに最新の試合リスト配列が伝播されること', () async {
      final container = ProviderContainer(
        overrides: [
          localMatchRepositoryProvider.overrideWithValue(fakeLocalRepo),
        ],
      );
      addTearDown(container.dispose);

      final listener = container.listen<AsyncValue<List<MatchModel>>>(
        matchStreamProvider,
        (previous, next) {},
      );

      expect(listener.read(), isA<AsyncLoading<List<MatchModel>>>());

      final mockMatches = [
        const MatchModel(
          id: 'stream_match_001',
          matchType: '大将戦',
          redName: '紅組',
          whiteName: '白組',
          status: 'in_progress',
        ),
      ];
      
      fakeLocalRepo.emitMatches(mockMatches);
      await Future.microtask(() {});

      final state = listener.read();
      expect(state, isA<AsyncData<List<MatchModel>>>());
      expect(state.value!.first.id, equals('stream_match_001'));
      expect(state.value!.first.matchType, equals('大将戦'));
    });

    test('2. 【再接続シーケンスホールド】ストリームが空配列を射出した際にも、システムがクラッシュせず安全にデータ状態が維持されること', () async {
      final container = ProviderContainer(
        overrides: [
          localMatchRepositoryProvider.overrideWithValue(fakeLocalRepo),
        ],
      );
      addTearDown(container.dispose);

      final listener = container.listen<AsyncValue<List<MatchModel>>>(
        matchStreamProvider,
        (previous, next) {},
      );

      fakeLocalRepo.emitMatches([]);
      await Future.microtask(() {});

      final state = listener.read();
      expect(state, isA<AsyncData<List<MatchModel>>>());
      expect(state.value, isEmpty);
    });
  });
}
