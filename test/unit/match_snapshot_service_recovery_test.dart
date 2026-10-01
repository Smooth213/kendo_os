import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/application/usecases/match_application_service.dart';
import 'package:kendo_os/features/match/application/usecases/match_usecases.dart';
import 'package:kendo_os/features/match/domain/match_aggregate.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_snapshot_service.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:mocktail/mocktail.dart';

class _MockMatchApplicationService extends Mock
    implements MatchApplicationService {}

class _MockLocalMatchRepository extends Mock implements LocalMatchRepository {}

class _MockRebuildMatchFromEventsUseCase extends Mock
    implements RebuildMatchFromEventsUseCase {}

final _testRefProvider = Provider<Ref>((ref) => ref);

void main() {
  setUpAll(() {
    registerFallbackValue(
      const MatchModel(
        id: 'dummy',
        matchType: '個人戦',
        redName: '赤選手',
        whiteName: '白選手',
      ),
    );
    registerFallbackValue(const MatchRule());
  });

  group('[Unit] MatchSnapshotService スナップショット生成と復元再構築の検証', () {
    late _MockMatchApplicationService mockAppService;
    late _MockLocalMatchRepository mockLocalRepo;
    late _MockRebuildMatchFromEventsUseCase mockRebuildUseCase;
    final testTime = DateTime(2025, 1, 1, 10, 0);

    setUp(() {
      mockAppService = _MockMatchApplicationService();
      mockLocalRepo = _MockLocalMatchRepository();
      mockRebuildUseCase = _MockRebuildMatchFromEventsUseCase();

      when(() => mockAppService.saveMatch(any())).thenAnswer((_) async {});
    });

    test('スナップショット生成時において最新1件のみ保持され履歴肥大化が抑制されること', () async {
      final oldSnapshot = MatchSnapshot(
        id: 'snap_old',
        matchId: 'match_1',
        version: 1,
        state: const MatchModel(
          id: 'match_1',
          matchType: '個人戦',
          redName: '赤選手',
          whiteName: '白選手',
        ),
        createdAt: testTime,
        reason: '過去のスナップショット',
        events: const [],
      );

      final initialMatch = MatchModel(
        id: 'match_1',
        matchType: '個人戦',
        redName: '赤選手',
        whiteName: '白選手',
        snapshots: [oldSnapshot],
        events: [
          ScoreEvent(
            id: 'ev_1',
            side: Side.red,
            strikeType: StrikeType.men,
            isIppon: true,
            sequence: 1,
            timestamp: testTime,
          ),
        ],
      );

      when(
        () => mockLocalRepo.getMatch('match_1'),
      ).thenAnswer((_) async => initialMatch);

      final container = ProviderContainer(
        overrides: [
          matchApplicationServiceProvider.overrideWithValue(mockAppService),
          localMatchRepositoryProvider.overrideWithValue(mockLocalRepo),
          matchListProvider.overrideWithValue([initialMatch]),
        ],
      );
      addTearDown(container.dispose);

      final ref = container.read(_testRefProvider);
      final result = await MatchSnapshotService.takeSnapshot(
        ref: ref,
        matchId: 'match_1',
        reason: '二本目取得時',
      );

      expect(result, isNotNull);
      // ドキュメント肥大化防止のため、最新1件のみ保持されること
      expect(result!.snapshots.length, equals(1));
      expect(result.snapshots.first.reason, equals('二本目取得時'));
      expect(result.snapshots.first.version, equals(1));
      verify(() => mockAppService.saveMatch(any())).called(1);
    });

    test('存在しない試合IDにおいてスナップショット処理が安全にスキップされること', () async {
      when(
        () => mockLocalRepo.getMatch('non_existent'),
      ).thenAnswer((_) async => null);

      final container = ProviderContainer(
        overrides: [
          matchApplicationServiceProvider.overrideWithValue(mockAppService),
          localMatchRepositoryProvider.overrideWithValue(mockLocalRepo),
          matchListProvider.overrideWithValue([]),
        ],
      );
      addTearDown(container.dispose);

      final ref = container.read(_testRefProvider);
      final result = await MatchSnapshotService.takeSnapshot(
        ref: ref,
        matchId: 'non_existent',
        reason: '任意のスナップショット',
      );

      expect(result, isNull);
      verifyNever(() => mockAppService.saveMatch(any()));
    });

    test('スナップショット復元時においてリストアイベントが付加されスコア履歴が再構築されること', () async {
      final pastEvent = ScoreEvent(
        id: 'ev_past',
        side: Side.red,
        strikeType: StrikeType.men,
        isIppon: true,
        sequence: 1,
        timestamp: testTime,
      );

      final snapshotToRestore = MatchSnapshot(
        id: 'snap_restore',
        matchId: 'match_100',
        version: 1,
        state: const MatchModel(
          id: 'match_100',
          matchType: '個人戦',
          redName: '赤選手',
          whiteName: '白選手',
        ),
        createdAt: testTime,
        reason: '一本目取り消し前',
        events: [pastEvent],
      );

      final currentMatch = MatchModel(
        id: 'match_100',
        matchType: '個人戦',
        redName: '赤選手',
        whiteName: '白選手',
        events: [
          pastEvent,
          ScoreEvent(
            id: 'ev_wrong',
            side: Side.white,
            strikeType: StrikeType.kote,
            isIppon: true,
            sequence: 2,
            timestamp: testTime,
          ),
        ],
      );

      when(
        () => mockLocalRepo.getMatch('match_100'),
      ).thenAnswer((_) async => currentMatch);
      when(() => mockRebuildUseCase.execute(any(), any())).thenAnswer((
        invocation,
      ) {
        return invocation.positionalArguments[0] as MatchModel;
      });

      final container = ProviderContainer(
        overrides: [
          matchApplicationServiceProvider.overrideWithValue(mockAppService),
          localMatchRepositoryProvider.overrideWithValue(mockLocalRepo),
          rebuildMatchFromEventsUseCaseProvider.overrideWithValue(
            mockRebuildUseCase,
          ),
          matchListProvider.overrideWithValue([currentMatch]),
        ],
      );
      addTearDown(container.dispose);

      final ref = container.read(_testRefProvider);

      await MatchSnapshotService.restoreFromSnapshot(
        ref: ref,
        matchId: 'match_100',
        snapshot: snapshotToRestore,
      );

      // 復元イベントが付加された試合の保存、再構築、および復元時点スナップショットの保存が行われること
      final capturedMatches = verify(
        () => mockAppService.saveMatch(captureAny()),
      ).captured;
      expect(capturedMatches.isNotEmpty, isTrue);

      final firstSavedMatch = capturedMatches.first as MatchModel;
      // snapshot.events (1件) + restoreEvent (1件) = 2件
      expect(firstSavedMatch.events.length, equals(2));
      expect(firstSavedMatch.events.first.id, equals('ev_past'));
      expect(firstSavedMatch.events.last.type, equals(PointType.restore));
    });
  });
}
