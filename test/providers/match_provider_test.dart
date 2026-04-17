import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kendo_os/providers/match_provider.dart';
import 'package:kendo_os/models/match_model.dart';
import 'package:kendo_os/repositories/match_repository.dart';
import 'package:kendo_os/providers/audit_provider.dart';
import 'package:kendo_os/services/sound_service.dart';
import 'package:kendo_os/providers/match_command_provider.dart';
import 'package:kendo_os/providers/match_list_provider.dart';
import 'package:kendo_os/providers/settings_provider.dart';
import 'package:kendo_os/models/settings_model.dart';
import 'package:kendo_os/models/score_event.dart';
import '../helpers/test_match_factory.dart';

/// 依存サービスの Mock 作成
class MockMatchRepository extends Mock implements MatchRepository {}
class MockAuditService extends Mock implements AuditService {}
class MockSoundService extends Mock implements SoundService {}
class MockMatchCommand extends Mock implements MatchCommand {}

// ★ Step 3-2: mocktail で MatchModel を引数として検証するために必要
class FakeMatchModel extends Fake implements MatchModel {}

// ★ Step 3-1 修正: NotifierProvider をオーバーライドするための簡易モッククラス
// build() メソッドでテスト用の初期状態を返すように定義します
class MockSettingsNotifier extends SettingsNotifier {
  @override
  SettingsModel build() => const SettingsModel();
}

class MockMatchListNotifier extends MatchListNotifier {
  @override
  List<MatchModel> build() => [];
}

void main() {
  late ProviderContainer container;
  late MockMatchRepository mockRepository;
  late MockAuditService mockAudit;
  late MockSoundService mockSound;
  late MockMatchCommand mockCommand;

  setUp(() {
    // any() を MatchModel 型で使用するための登録
    registerFallbackValue(FakeMatchModel());

    mockRepository = MockMatchRepository();
    mockAudit = MockAuditService();
    mockSound = MockSoundService();
    mockCommand = MockMatchCommand();

    // ★ Step 3-1 修正: NotifierProvider に対しては Notifier クラスを返す関数を渡します
    container = ProviderContainer(
      overrides: [
        matchRepositoryProvider.overrideWithValue(mockRepository),
        auditProvider.overrideWithValue(mockAudit),
        soundServiceProvider.overrideWithValue(mockSound),
        matchCommandProvider.overrideWithValue(mockCommand),
        settingsProvider.overrideWith(() => MockSettingsNotifier()),
        matchListProvider.overrideWith(() => MockMatchListNotifier()),
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

    test('matchUseCaseProvider が依存関係（Engine）を持って初期化されていること', () {
      final useCase = container.read(matchUseCaseProvider);
      expect(useCase, isNotNull);
    });

    test('matchActionProvider が正しく取得できること', () {
      final controller = container.read(matchActionProvider);
      expect(controller, isA<MatchActionController>());
    });
  });

  group('MatchProvider - Step 3-2: 状態遷移の検証', () {
    test('processScoreEvent を呼び出した際、正しく保存処理と監査ログが実行されること', () async {
      // Given: 準備
      final match = TestMatchFactory.createIndividualMatch(id: 'match-123');
      final event = TestMatchFactory.createEvent(side: Side.red, type: PointType.men);

      // Mock の振る舞い設定
      when(() => mockCommand.saveMatch(any())).thenAnswer((_) async => {});
      when(() => mockAudit.logAction(
            matchId: any(named: 'matchId'),
            action: any(named: 'action'),
            details: any(named: 'details'),
          )).thenAnswer((_) async => {});

      final controller = container.read(matchActionProvider);

      // When: スコア追加イベントを実行
      await controller.processScoreEvent(match, event);

      // Then:
      // 1. saveMatch が「スコアが加算されたモデル」で呼ばれたか検証
      verify(() => mockCommand.saveMatch(any(
            that: isA<MatchModel>().having((m) => m.redScore, 'redScore', 1),
          ))).called(1);

      // 2. 監査ログが記録されたか検証
      verify(() => mockAudit.logAction(
            matchId: 'match-123',
            action: 'add_score',
            details: any(named: 'details', that: contains('赤')),
          )).called(1);
    });

    test('undoEvent を呼び出した際、保存処理が実行されること', () async {
      final event = TestMatchFactory.createEvent(side: Side.red, type: PointType.men);
      final match = TestMatchFactory.createIndividualMatch(events: [event]).copyWith(redScore: 1);

      when(() => mockCommand.saveMatch(any())).thenAnswer((_) async => {});
      when(() => mockAudit.logAction(
            matchId: any(named: 'matchId'),
            action: any(named: 'action'),
            details: any(named: 'details'),
          )).thenAnswer((_) async => {});

      final controller = container.read(matchActionProvider);

      // When: Undoを実行
      controller.undoEvent(match);
      await Future.delayed(Duration.zero); // voidの非同期処理が完了するのを待つ

      // Then: スコアが 0 に戻った状態で保存されたか検証
      verify(() => mockCommand.saveMatch(any(
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

      // 無関係なプロパティの変更
      notifier.state = notifier.state.copyWith(sound: !notifier.state.sound);
      expect(callCount, 0);

      // 監視対象のプロパティを変更
      notifier.state = notifier.state.copyWith(strikeVib: !notifier.state.strikeVib);
      expect(callCount, 1);
    });
  });

  group('MatchProvider - Step 3-4: 同時操作・競合の防止', () {
    test('データ保存時に競合エラーが発生しても、適切にキャッチして処理を継続すること', () async {
      // Given
      final match = TestMatchFactory.createIndividualMatch();
      final event = TestMatchFactory.createEvent(side: Side.red, type: PointType.men);

      when(() => mockCommand.saveMatch(any())).thenThrow(
        Exception('他の端末でデータが更新されました')
      );

      final controller = container.read(matchActionProvider);

      // When & Then
      await expectLater(
        controller.processScoreEvent(match, event),
        completes,
      );
    });

    test('予期せぬエラーが発生した場合も、監査ログの送信を試みず安全に終了すること', () async {
      final match = TestMatchFactory.createIndividualMatch();
      final event = TestMatchFactory.createEvent(side: Side.red, type: PointType.men);

      when(() => mockCommand.saveMatch(any())).thenThrow(
        Exception('Network Failure')
      );

      final controller = container.read(matchActionProvider);

      await controller.processScoreEvent(match, event);

      verifyNever(() => mockAudit.logAction(
        matchId: any(named: 'matchId'),
        action: any(named: 'action'),
        details: any(named: 'details'),
      ));
    });
  });
}