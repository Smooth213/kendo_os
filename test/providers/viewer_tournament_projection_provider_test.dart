import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/tournament_repository.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/viewer/providers/viewer_view_state_provider.dart';
import 'package:kendo_os/shared/application/projections/tournament_projection.dart';
import 'dart:async';

class FakeTournamentRepository implements TournamentRepository {
  final StreamController<TournamentModel?> _controller =
      StreamController<TournamentModel?>.broadcast();

  void emitData(TournamentModel? model) {
    _controller.add(model);
  }

  void emitError(Object error) {
    _controller.addError(error);
  }

  @override
  Stream<TournamentModel?> getTournamentStream(String id) => _controller.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('🛡️ STEP 3-1: viewerTournamentProjectionProvider 非同期4状態 完全テスト要塞', () {
    late FakeTournamentRepository fakeRepo;
    const tId = 'tournament_provider_test_001';

    setUp(() {
      fakeRepo = FakeTournamentRepository();
    });

    test(
      '1. 【Projection生成】正常な大会モデルと試合リストが供給された際、完全な動的Projection（AsyncData）が生成されること',
      () async {
        final container = ProviderContainer(
          overrides: [
            tournamentRepositoryProvider.overrideWithValue(fakeRepo),
            matchListProvider.overrideWithValue([
              const MatchModel(
                id: 'match_p_001',
                tournamentId: tId,
                matchType: '先鋒',
                redName: '紅チーム',
                whiteName: '白チーム',
                groupName: '一般の部',
                status: 'waiting',
              ),
            ]),
          ],
        );
        addTearDown(container.dispose);

        final tournament = TournamentModel(
          id: tId,
          organizationId: 'org_001',
          name: 'Riverpodテスト大会',
          date: DateTime(2026, 5, 29),
          venue: '武道館',
        );

        final listener = container.listen<AsyncValue<TournamentProjection?>>(
          viewerTournamentProjectionProvider(tId),
          (previous, next) {},
        );

        fakeRepo.emitData(tournament);
        await Future.microtask(() {});

        final state = listener.read();
        expect(state, isA<AsyncData<TournamentProjection?>>());
        expect(state.value!.tournament.name, equals('Riverpodテスト大会'));
      },
    );

    test(
      '2. 【null処理】大会データが未登録（null）であっても、システムがクラッシュせずフォールバックダミーが自動適用されること',
      () async {
        final container = ProviderContainer(
          overrides: [
            tournamentRepositoryProvider.overrideWithValue(fakeRepo),
            matchListProvider.overrideWithValue([]),
          ],
        );
        addTearDown(container.dispose);

        final listener = container.listen<AsyncValue<TournamentProjection?>>(
          viewerTournamentProjectionProvider(tId),
          (previous, next) {},
        );

        fakeRepo.emitData(null);
        await Future.microtask(() {});

        final state = listener.read();
        expect(state, isA<AsyncData<TournamentProjection?>>());
        expect(state.value!.tournament.name, equals('大会情報'));
      },
    );

    test(
      '3. 【loading】インフラ層からのデータ疎通を待機している間、プロバイダが正確に AsyncLoading 状態をホールドすること',
      () {
        final container = ProviderContainer(
          overrides: [
            tournamentRepositoryProvider.overrideWithValue(fakeRepo),
            matchListProvider.overrideWithValue([]),
          ],
        );
        addTearDown(container.dispose);

        final state = container.read(viewerTournamentProjectionProvider(tId));
        expect(state, isA<AsyncLoading<TournamentProjection?>>());
      },
    );

    test(
      '4. 【error】通信障害や権限エラーが発生した際、プロバイダが破綻せず正確に AsyncError をUIへ伝播すること',
      () async {
        final container = ProviderContainer(
          overrides: [
            tournamentRepositoryProvider.overrideWithValue(fakeRepo),
            matchListProvider.overrideWithValue([]),
          ],
        );
        addTearDown(container.dispose);

        final listener = container.listen<AsyncValue<TournamentProjection?>>(
          viewerTournamentProjectionProvider(tId),
          (previous, next) {},
        );

        fakeRepo.emitError(Exception('Firestore connection timeout'));
        await Future.microtask(() {});

        final state = listener.read();
        expect(state, isA<AsyncError<TournamentProjection?>>());
      },
    );
  });
}
