import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kendo_os/presentation/operate/providers/match_provider.dart';
import 'package:kendo_os/domain/match/match_model.dart';
import 'package:kendo_os/infrastructure/repository/match_repository.dart';
import 'package:kendo_os/domain/entities/audit_log.dart'; 
import 'package:kendo_os/presentation/providers/internal/audit_provider.dart';
import 'package:kendo_os/application/services/sound_service.dart';
import 'package:kendo_os/presentation/operate/providers/match_command_provider.dart';
import 'package:kendo_os/presentation/operate/providers/match_list_provider.dart';
import 'package:kendo_os/presentation/operate/providers/settings_provider.dart';
import 'package:kendo_os/domain/entities/settings_model.dart';
import 'package:kendo_os/domain/score/score_event.dart';
import '../../helpers/test_match_factory.dart';
import 'package:kendo_os/application/usecases/match_usecases.dart';
import 'package:kendo_os/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/application/usecases/match_application_service.dart';
// ★ 追加: テスト用のモック追加
import 'package:kendo_os/presentation/operate/providers/ui_message_provider.dart';
import 'package:kendo_os/presentation/operate/providers/sync_provider.dart';
import 'package:kendo_os/infrastructure/repository/sync_engine.dart' as new_sync;
import 'package:kendo_os/core/time/system_time_source.dart';
// ★ 追加: ProjectionとIsarの警告を防ぐためのモック追加
import 'package:kendo_os/application/projections/projection_store.dart' as app_store;
import 'package:kendo_os/domain/repositories/projection_store.dart' as domain_store;
import 'package:kendo_os/infrastructure/repository/in_memory_projection_store.dart' as in_memory_store;
import 'package:kendo_os/application/projections/match_projection.dart';

class MockMatchRepository extends Mock implements MatchRepository {}
class MockAuditService extends Mock implements AuditService {}
class MockSoundService extends Mock implements SoundService {}
class MockMatchCommand extends Mock implements MatchCommandService {}
class MockLocalMatchRepository extends Mock implements LocalMatchRepository {}
class MockSyncEngine extends Mock implements SyncEngine {} // ★ 追加
class MockNewSyncEngine extends Mock implements new_sync.SyncEngine {} // ★ 追加

// ★ 追加: UiMessageNotifier のモック
class MockUiMessageNotifier extends UiMessageNotifier {
  @override
  UiMessage? build() => null;
  @override
  void showError(String message) {}
  @override
  void showSuccess(String message) {}
}

// ★ 追加: Projection Storeのモック (Isar警告の完全抑止)
class MockAppProjectionStore extends Mock implements app_store.ProjectionStore {}
class MockDomainProjectionStore extends Mock implements domain_store.ProjectionStore {}

class FakeMatchModel extends Fake implements MatchModel {
  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return super.toString();
  }
}

class FakeMatchCommandModel extends Fake implements MatchCommandModel {}
class FakeMatchProjection extends Fake implements MatchProjection {}

class MockSettingsNotifier extends SettingsNotifier {
  @override
  SettingsModel build() => const SettingsModel();
}

final mockMatchListProvider = StateProvider<List<MatchModel>>((ref) => []);

void main() {
  // ★ 修正: Flutterの描画エンジンに依存する処理（microtask等）がクラッシュしないように初期化
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late MockMatchRepository mockRepository;
  late MockAuditService mockAudit;
  late MockSoundService mockSound;
  late MockMatchCommand mockCommand;
  late MockLocalMatchRepository mockLocalRepo;
  late MockSyncEngine mockSyncEngine;
  late MockNewSyncEngine mockNewSyncEngine;
  late MockAppProjectionStore mockAppProjectionStore;
  late MockDomainProjectionStore mockDomainStore;

  setUp(() {
    registerFallbackValue(FakeMatchModel());
    registerFallbackValue(AuditAction.addScore); 
    registerFallbackValue(FakeMatchCommandModel());
    registerFallbackValue(FakeMatchProjection());

    mockRepository = MockMatchRepository();
    mockAudit = MockAuditService();
    mockSound = MockSoundService();
    mockCommand = MockMatchCommand();
    mockLocalRepo = MockLocalMatchRepository();
    mockSyncEngine = MockSyncEngine();
    mockNewSyncEngine = MockNewSyncEngine();
    mockAppProjectionStore = MockAppProjectionStore();
    mockDomainStore = MockDomainProjectionStore();

    // 試合が見つからないと処理が中断されるため、モックプロバイダから試合を返すように設定
    when(() => mockLocalRepo.getMatch(any())).thenAnswer((inv) async {
      final id = inv.positionalArguments[0] as String;
      return container.read(mockMatchListProvider).where((m) => m.id == id).firstOrNull;
    });
    when(() => mockLocalRepo.saveMatch(any())).thenAnswer((_) async {});
    when(() => mockLocalRepo.getPendingMatches()).thenAnswer((_) async => <MatchModel>[]);
    when(() => mockLocalRepo.savePendingCommand(any())).thenAnswer((_) async {});
    when(() => mockLocalRepo.getPendingCommands()).thenAnswer((_) async => <MatchCommandModel>[]);
    when(() => mockRepository.saveMatch(any())).thenAnswer((_) async {});
    // ★ 修正: 同期エンジンが呼ばれたら何もしない（テストをパスさせる）
    when(() => mockSyncEngine.syncNow()).thenAnswer((_) async {});
    when(() => mockNewSyncEngine.processQueue()).thenAnswer((_) async {});

    // ★ 追加: Projectionの書き込み処理をモック化して例外ログを完全沈黙させる
    when(() => mockDomainStore.save(any())).thenAnswer((_) => Future.value());

    container = ProviderContainer(
      overrides: [
        matchRepositoryProvider.overrideWithValue(mockRepository),
        localMatchRepositoryProvider.overrideWithValue(mockLocalRepo),
        isarProvider.overrideWithValue(null), // ★ 追加: Isar初期化エラーの根本解決
        auditProvider.overrideWithValue(mockAudit),
        soundServiceProvider.overrideWithValue(mockSound),
        matchCommandProvider.overrideWithValue(mockCommand),
        syncEngineProvider.overrideWithValue(mockSyncEngine), // ★ モックを追加
        new_sync.syncEngineProvider.overrideWithValue(mockNewSyncEngine), // ★ モックを追加
        uiMessageProvider.overrideWith(() => MockUiMessageNotifier()), // ★ モックを追加
        app_store.projectionStoreProvider.overrideWithValue(mockAppProjectionStore), // ★ Isar Projection 警告を抑止
        in_memory_store.projectionStoreProvider.overrideWithValue(mockDomainStore), // ★ 追加: ドメイン層のProjectionStoreもモック化
        settingsProvider.overrideWith(() => MockSettingsNotifier()),
        matchListProvider.overrideWith((ref) => ref.watch(mockMatchListProvider)), 
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('MatchProvider - Step 3-1: 初期状態の検証', () {
    test('currentMatchIdProvider の初期値は null であること', () {
      final matchId = container.read(currentMatchIdProvider);
      expect(matchId, isNull);
    });

    test('kendoRuleEngineProvider が正しくインスタンス化されていること', () {
      final engine = container.read(kendoRuleEngineProvider);
      expect(engine, isNotNull);
    });

    test('addScoreUseCaseProvider が依存関係（Engine）を持って初期化されていること', () {
      final addScoreUseCase = container.read(addScoreUseCaseProvider);
      expect(addScoreUseCase, isNotNull);
    });

    test('matchActionProvider が正しく取得できること', () {
      final controller = container.read(matchActionProvider);
      expect(controller, isA<MatchActionController>());
    });
  });

  group('MatchProvider - Step 3-2: 状態遷移の検証', () {
    test('processScoreEvent を呼び出した際、正しく保存処理と監査ログが実行されること', () async {
      final match = TestMatchFactory.createIndividualMatch(id: 'match-123');
      container.read(mockMatchListProvider.notifier).state = [match];
      final event = TestMatchFactory.createEvent(side: Side.red, type: PointType.men);

      when(() => mockAudit.logAction(
            matchId: any(named: 'matchId'),
            action: any(named: 'action'),
            details: any(named: 'details'),
            traceId: any(named: 'traceId'), // ★ 追加: traceId をモックが受け入れられるようにする
          )).thenAnswer((_) async => {});

      final controller = container.read(matchActionProvider);

      await controller.processScoreEvent(match, event);

      // ★ 修正: マイクロタスク（syncNow）の実行完了を待つ
      await Future.delayed(Duration.zero);

      verify(() => mockLocalRepo.saveMatch(any(
            that: isA<MatchModel>().having((m) => m.redScore, 'redScore', 1),
          ))).called(1);

      verify(() => mockAudit.logAction(
            matchId: 'match-123',
            action: AuditAction.addScore, 
            details: any(named: 'details', that: contains('red')),
            traceId: any(named: 'traceId'), // ★ 追加: 検証時にも traceId を許容する
          )).called(1);
    });

    test('undoEvent を呼び出した際、保存処理が実行されること', () async {
      final event = TestMatchFactory.createEvent(side: Side.red, type: PointType.men);
      final match = TestMatchFactory.createIndividualMatch(events: [event]).copyWith(redScore: 1);
      container.read(mockMatchListProvider.notifier).state = [match];

      when(() => mockAudit.logAction(
            matchId: any(named: 'matchId'),
            action: any(named: 'action'),
            details: any(named: 'details'),
            traceId: any(named: 'traceId'), // ★ 追加: traceId をモックが受け入れられるようにする
          )).thenAnswer((_) async => {});

      final controller = container.read(matchActionProvider);

      await controller.undoEvent(match);
      await Future.delayed(Duration.zero);

      verify(() => mockLocalRepo.saveMatch(any(
            that: isA<MatchModel>().having((m) => m.redScore, 'redScore', 0),
          ))).called(1);
    });
  });

  group('MatchProvider - Step 3-3: rebuild最適化の検証', () {
    test('.select() により、監視対象外のプロパティ変更では通知が飛ばないこと', () {
      final notifier = container.read(settingsProvider.notifier);
      int callCount = 0;

      container.listen<bool>(
        settingsProvider.select((s) => s.strikeVib),
        (previous, next) {
          callCount++;
        },
        fireImmediately: false,
      );

      notifier.state = notifier.state.copyWith(
        audioFeedbackMode: notifier.state.audioFeedbackMode == 'off' ? 'effect' : 'off'
      );
      expect(callCount, 0);

      notifier.state = notifier.state.copyWith(strikeVib: !notifier.state.strikeVib);
      expect(callCount, 1);
    });
  });

  group('MatchProvider - Step 3-4: 同時操作・競合の防止', () {
    test('データ保存時に競合エラーが発生した場合、上位に例外が伝播すること', () async {
      final match = TestMatchFactory.createIndividualMatch();
      container.read(mockMatchListProvider.notifier).state = [match];
      final event = TestMatchFactory.createEvent(side: Side.red, type: PointType.men);

      when(() => mockLocalRepo.saveMatch(any())).thenThrow(
        Exception('他の端末でデータが更新されました')
      );

      final controller = container.read(matchActionProvider);

      await expectLater(
        () => controller.processScoreEvent(match, event),
        throwsException,
      );
    });

    test('予期せぬエラーが発生した場合、監査ログの送信を試みず終了すること', () async {
      final match = TestMatchFactory.createIndividualMatch();
      container.read(mockMatchListProvider.notifier).state = [match];
      final event = TestMatchFactory.createEvent(side: Side.red, type: PointType.men);

      when(() => mockLocalRepo.saveMatch(any())).thenThrow(
        Exception('Network Failure')
      );

      final controller = container.read(matchActionProvider);

      try {
        await controller.processScoreEvent(match, event);
      } catch (_) {}

      verifyNever(() => mockAudit.logAction(
        matchId: any(named: 'matchId'),
        action: any(named: 'action'),
        details: any(named: 'details'),
      ));
    });
  });

  group('MatchApplicationService - 修正事項の回帰テスト', () {
    test('finishMatch を呼び出した際、残り時間が0秒にリセットされないこと', () async {
      final now = SystemTimeSource().now();
      final match = TestMatchFactory.createIndividualMatch(id: 'match-time-test').updateRemainingSeconds(45, now);
      container.read(mockMatchListProvider.notifier).state = [match];
      
      final appService = container.read(matchApplicationServiceProvider);
      await appService.finishMatch(match.id);
      await Future.delayed(Duration.zero);

      verify(() => mockLocalRepo.saveMatch(any(that: isA<MatchModel>().having((m) => m.calculateRemainingSeconds(now), 'remainingSeconds', 45).having((m) => m.status, 'status', 'finished')))).called(1);
    });

    test('addIppon を呼び出した際、DB保存(saveMatch)が1回しか呼ばれないこと（二重保存の防止）', () async {
      final match = TestMatchFactory.createIndividualMatch(id: 'match-add-ippon');
      container.read(mockMatchListProvider.notifier).state = [match];
      
      when(() => mockAudit.logAction(
            matchId: any(named: 'matchId'),
            action: any(named: 'action'),
            details: any(named: 'details'),
            traceId: any(named: 'traceId'), // ★ 追加: traceId をモックが受け入れられるようにする
          )).thenAnswer((_) async => {});

      final appService = container.read(matchApplicationServiceProvider);
      await appService.addIppon(match.id, Side.red, PointType.men);
      await Future.delayed(Duration.zero);

      verify(() => mockLocalRepo.saveMatch(any())).called(1);
    });
  });
}