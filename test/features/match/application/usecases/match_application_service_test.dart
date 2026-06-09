import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kendo_os/features/match/application/usecases/match_application_service.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/shared/infrastructure/repository/local_match_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/match_repository.dart';
import 'package:kendo_os/shared/infrastructure/repository/sync_engine.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/match_command_provider.dart';
import 'package:kendo_os/shared/presentation/providers/current_sync_context_provider.dart';

// --- モッククラスの定義 ---
class MockLocalMatchRepository extends Mock implements LocalMatchRepository {}

class MockMatchRepository extends Mock implements MatchRepository {}

class MockSyncEngine extends Mock implements SyncEngine {}

void main() {
  late ProviderContainer container;
  late MockLocalMatchRepository mockLocalRepo;
  late MockMatchRepository mockRemoteRepo;
  late MockSyncEngine mockSyncEngine;

  setUpAll(() {
    // mocktail の any() を使うためのフォールバック値の登録
    registerFallbackValue(
      const MatchModel(
        id: 'dummy',
        matchType: 'dummy',
        redName: 'red',
        whiteName: 'white',
      ),
    );
    registerFallbackValue(
      MatchCommandModel(
        id: 'dummy',
        type: CommandType.updateMatch,
        payload: {},
        createdAt: DateTime.now(),
        status: CommandStatus.pending,
      ),
    );
  });

  setUp(() {
    mockLocalRepo = MockLocalMatchRepository();
    mockRemoteRepo = MockMatchRepository();
    mockSyncEngine = MockSyncEngine();

    // モックの振る舞いを設定（保存処理は成功して何もしない）
    when(() => mockLocalRepo.saveMatch(any())).thenAnswer((_) async {});
    when(() => mockLocalRepo.saveMatchesBulk(any())).thenAnswer((_) async {});
    when(
      () => mockLocalRepo.savePendingCommand(any()),
    ).thenAnswer((_) async {});
    when(() => mockSyncEngine.processQueue()).thenAnswer((_) async {});

    // ProviderContainer で使用するプロバイダをモックに差し替え
    container = ProviderContainer(
      overrides: [
        localMatchRepositoryProvider.overrideWithValue(mockLocalRepo),
        matchRepositoryProvider.overrideWithValue(mockRemoteRepo),
        syncEngineProvider.overrideWithValue(mockSyncEngine),
        // ★ テストの核心：現在のテナントIDを固定値にする
        currentDojoIdProvider.overrideWith((ref) => 'test_tenant_001'),
      ],
    );
  });

  group('🛡️ MatchApplicationService - テナントID自動割り当てテスト', () {
    test('✅ organizationIdが default_org の場合、現在の道場IDに上書きされて保存されること', () async {
      final service = container.read(matchApplicationServiceProvider);

      const match = MatchModel(
        id: 'test-match-1',
        matchType: '個人戦',
        redName: '赤',
        whiteName: '白',
        organizationId: 'default_org', // デフォルト値のまま
      );

      await service.saveMatch(match);

      final captured = verify(
        () => mockLocalRepo.saveMatch(captureAny()),
      ).captured;
      final savedMatch = captured.first as MatchModel;

      expect(
        savedMatch.organizationId,
        'test_tenant_001',
        reason: 'default_org は現在のテナントIDで上書きされなければならない',
      );
    });

    test('✅ organizationIdが 空文字 の場合、現在の道場IDに上書きされて保存されること', () async {
      final service = container.read(matchApplicationServiceProvider);

      const match = MatchModel(
        id: 'test-match-2',
        matchType: '個人戦',
        redName: '赤',
        whiteName: '白',
        organizationId: '', // 空
      );

      await service.saveMatch(match);

      final captured = verify(
        () => mockLocalRepo.saveMatch(captureAny()),
      ).captured;
      final savedMatch = captured.first as MatchModel;

      expect(
        savedMatch.organizationId,
        'test_tenant_001',
        reason: '空文字は現在のテナントIDで上書きされなければならない',
      );
    });

    test('✅ 一括保存(saveMatchesBulk)時も、各試合のテナントIDが正しく判定・上書きされること', () async {
      final service = container.read(matchApplicationServiceProvider);

      final matches = [
        const MatchModel(
          id: 'b1',
          matchType: '戦1',
          redName: 'A',
          whiteName: 'B',
          organizationId: 'default_org',
        ),
        const MatchModel(
          id: 'b2',
          matchType: '戦2',
          redName: 'C',
          whiteName: 'D',
          organizationId: '',
        ),
        const MatchModel(
          id: 'b3',
          matchType: '戦3',
          redName: 'E',
          whiteName: 'F',
          organizationId: 'other_tenant_999',
        ),
      ];

      await service.saveMatchesBulk(matches);

      final captured = verify(
        () => mockLocalRepo.saveMatchesBulk(captureAny()),
      ).captured;
      final savedMatches = captured.first as List<MatchModel>;

      expect(
        savedMatches[0].organizationId,
        'test_tenant_001',
        reason: 'default_orgは上書き',
      );
      expect(
        savedMatches[1].organizationId,
        'test_tenant_001',
        reason: '空文字は上書き',
      );
      expect(
        savedMatches[2].organizationId,
        'other_tenant_999',
        reason: '既に設定されているテナントIDは上書きせずそのまま維持する',
      );
    });
  });
}
