import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kendo_os/presentation/provider/match_list_provider.dart';
import 'package:kendo_os/models/match_model.dart';
import 'package:kendo_os/domain/match/score_event.dart';
import 'package:kendo_os/models/settings_model.dart';
import 'package:kendo_os/domain/match/match_rule.dart';
import 'package:kendo_os/presentation/provider/match_command_provider.dart';
import 'package:kendo_os/presentation/provider/match_timer_provider.dart';
import 'package:isar_community/isar.dart';
import 'package:kendo_os/repositories/local_match_repository.dart';
import 'package:kendo_os/presentation/provider/match_provider.dart';
import 'package:kendo_os/presentation/provider/audit_provider.dart';
import 'package:kendo_os/presentation/provider/settings_provider.dart';
import 'package:kendo_os/presentation/provider/match_rule_provider.dart';
import 'package:kendo_os/application/service/sound_service.dart';
import 'package:kendo_os/repositories/match_repository.dart';
import 'dart:async';
import 'package:kendo_os/presentation/provider/sync_provider.dart';
import 'package:kendo_os/models/audit_log.dart';

class MockAuditService extends Mock implements AuditService {}
class MockSoundService extends Mock implements SoundService {}

// ★ 最終奥義：Isarそのものをダミー（モック）化し、起動エラーを物理的に消滅させる
class MockIsar extends Mock implements Isar {
  @override
  Future<T> writeTxn<T>(Future<T> Function() callback, {bool silent = false}) async {
    return await callback();
  }
  
  @override
  Future<void> clear() async {}
  
  @override
  Future<bool> close({bool deleteFromDisk = false}) async => true;
  
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == Symbol('matchEntitys')) {
      return MockIsarCollectionDynamic();
    }
    return super.noSuchMethod(invocation);
  }
}

class MockIsarCollectionDynamic extends Mock {
  Future<void> put(dynamic item) async {}
  
  Future<dynamic> filter() async => null;
}

class MockSettingsNotifier extends SettingsNotifier {
  final SettingsModel initialSettings;
  MockSettingsNotifier(this.initialSettings);
  @override
  SettingsModel build() => initialSettings;
}

class MockMatchRuleNotifier extends MatchRuleNotifier {
  @override
  MatchRule build() => MatchRule();
}

class TestLocalMatchRepository extends LocalMatchRepository {
  final StreamController<List<MatchModel>> _controller = StreamController<List<MatchModel>>.broadcast();
  final List<MatchModel> _cache = [];
  final FakeFirebaseFirestore fakeFirestore;

  TestLocalMatchRepository(super.isar, this.fakeFirestore);

  @override
  Stream<List<MatchModel>> watchMatches() async* {
    yield List.from(_cache);
    yield* _controller.stream;
  }

  @override
  Future<void> saveMatch(MatchModel match) async {
    // ★ 究極の修正：super.saveMatch (本物のIsarへの保存) を完全に削除！
    // データベースを一切経由せず、メモリ上のキャッシュだけで高速に動作させます。
    await fakeFirestore.collection('matches').doc(match.id).set(match.toJson());

    final index = _cache.indexWhere((m) => m.id == match.id);
    if (index >= 0) {
      _cache[index] = match;
    } else {
      _cache.add(match);
    }
    _controller.add(List.from(_cache));
  }

  @override
  Future<void> saveMatchesBulk(List<MatchModel> matches) async {
    // ★ saveMatchesBulk もメモリ上のキャッシュで実装
    for (final match in matches) {
      await saveMatch(match);
    }
  }
}

class TestMatchRepository extends Fake implements MatchRepository {
  final TestLocalMatchRepository localRepo;
  TestMatchRepository(this.localRepo);

  // ★ 無限ループ回避: テスト時は「リモートからの更新」と「ローカルの更新」を切り離すため、
  // リモートからのリアルタイム監視は一旦「空のストリーム」を返すようにします。
  @override
  Stream<List<MatchModel>> watchInProgressMatches() => const Stream.empty();

  @override
  Future<List<MatchModel>> getStaticMatches() async => [];

  @override
  Stream<MatchModel> watchSingleMatch(String matchId) {
    return localRepo.watchMatches().map((list) => list.firstWhere((m) => m.id == matchId, orElse: () => const MatchModel(id: '', matchType: '', redName: '', whiteName: '')));
  }

  @override
  Future<void> saveMatch(MatchModel match) => localRepo.saveMatch(match);
}

class MockSyncEngine extends Mock implements SyncEngine {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ★ 修正1: 起動時に一度だけ、必要なモックの型（Fallback）を確実に登録する
  setUpAll(() {
    registerFallbackValue(const MatchModel(id: 'dummy', matchType: '', redName: '', whiteName: ''));
    // 🌟 エラーの原因だった AuditAction (enum) のダミー登録を追加！
    registerFallbackValue(AuditAction.addScore);
  });

  group('MatchListProvider (Score Logic) Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockIsar mockIsar; 
    late ProviderContainer container;

    setUp(() {
      mockIsar = MockIsar(); // ★ 0.01秒でダミーを生成
      fakeFirestore = FakeFirebaseFirestore();
      
      final mockAudit = MockAuditService();
      when(() => mockAudit.logAction(
        matchId: any(named: 'matchId'),
        action: any(named: 'action'),
        details: any(named: 'details'),
      )).thenAnswer((_) async => {});

      final testLocalRepo = TestLocalMatchRepository(mockIsar, fakeFirestore);
      
      final mockSyncEngine = MockSyncEngine();
      when(() => mockSyncEngine.syncNow()).thenAnswer((_) async {});

      container = ProviderContainer(
        overrides: [
          firestoreProvider.overrideWithValue(fakeFirestore),
          isarProvider.overrideWithValue(mockIsar), // ★ プロバイダーにもダミーを注入
          auditProvider.overrideWithValue(mockAudit),
          soundServiceProvider.overrideWithValue(MockSoundService()),
          settingsProvider.overrideWith(() => MockSettingsNotifier(const SettingsModel(confirmBehavior: 'manual'))),
          matchRuleProvider.overrideWith(() => MockMatchRuleNotifier()),
          localMatchRepositoryProvider.overrideWithValue(testLocalRepo),
          matchRepositoryProvider.overrideWith((ref) => TestMatchRepository(testLocalRepo)),
          connectivityProvider.overrideWith((ref) => Stream.value(true)),
          syncEngineProvider.overrideWithValue(mockSyncEngine),
        ],
      );

      container.listen(matchListProvider, (_, _) {});
    });

    tearDown(() async {
      container.dispose();
    });
    test('addScoreEventで「面」が正しく追加され、スコアが増えるか', () async {
      final testMatch = const MatchModel(id: 'test_1', matchType: '先鋒', redName: '赤', whiteName: '白');
      await container.read(localMatchRepositoryProvider).saveMatch(testMatch); // ★ Isarに保存
      container.read(matchListProvider);
      await Future.delayed(const Duration(milliseconds: 100));

      final controller = container.read(matchActionProvider);
      await controller.processScoreEvent(testMatch, ScoreEvent(
        id: 'e1', side: Side.red, type: PointType.men, timestamp: DateTime.now(), sequence: 1
      ));
      
      await Future.delayed(const Duration(milliseconds: 100));
      final match = container.read(matchListProvider).firstWhere((m) => m.id == 'test_1');
      expect(match.redScore, 1);
    });

    test('addScoreEventで、反則2回目で相手に1本入るか', () async {
      final testMatch = const MatchModel(id: 'test_2', matchType: '次鋒', redName: '赤', whiteName: '白');
      await container.read(localMatchRepositoryProvider).saveMatch(testMatch); // ★ Isarに保存
      container.read(matchListProvider);
      await Future.delayed(const Duration(milliseconds: 100));

      final controller = container.read(matchActionProvider);
      await controller.processScoreEvent(testMatch, ScoreEvent(id: 'h1', side: Side.red, type: PointType.hansoku, timestamp: DateTime.now(), sequence: 1));
      await Future.delayed(const Duration(milliseconds: 100));
      
      final matchAfterFirst = container.read(matchListProvider).firstWhere((m) => m.id == 'test_2');
      await controller.processScoreEvent(matchAfterFirst, ScoreEvent(id: 'h2', side: Side.red, type: PointType.hansoku, timestamp: DateTime.now(), sequence: 2));
      
      await Future.delayed(const Duration(milliseconds: 100));
      final match = container.read(matchListProvider).firstWhere((m) => m.id == 'test_2');
      expect(match.whiteScore, 1);
    });

    test('undoLastEventで「2回目の反則」を取り消すと、相手の得点も正しく減るか', () async {
      final testMatch = const MatchModel(id: 'test_3', matchType: '中堅', redName: '赤', whiteName: '白');
      await container.read(localMatchRepositoryProvider).saveMatch(testMatch); // ★ Isarに保存
      container.read(matchListProvider);
      await Future.delayed(const Duration(milliseconds: 100));

      final controller = container.read(matchActionProvider);
      await controller.processScoreEvent(testMatch, ScoreEvent(id: 'h1', side: Side.red, type: PointType.hansoku, timestamp: DateTime.now(), sequence: 1));
      await Future.delayed(const Duration(milliseconds: 100));
      var match = container.read(matchListProvider).firstWhere((m) => m.id == 'test_3');
      await controller.processScoreEvent(match, ScoreEvent(id: 'h2', side: Side.red, type: PointType.hansoku, timestamp: DateTime.now(), sequence: 2));
      
      await Future.delayed(const Duration(milliseconds: 100));
      match = container.read(matchListProvider).firstWhere((m) => m.id == 'test_3');
      expect(match.whiteScore, 1);

      await controller.undoEvent(match);
      await Future.delayed(const Duration(milliseconds: 100));

      match = container.read(matchListProvider).firstWhere((m) => m.id == 'test_3');
      expect(match.whiteScore, 0);
    });

    test('異常系ガード: 終了した試合(finished)にはスコアが追加されないか', () async {
      final testMatch = const MatchModel(id: 'test_4', matchType: '副将', redName: '赤', whiteName: '白', status: 'finished');
      await container.read(localMatchRepositoryProvider).saveMatch(testMatch); // ★ Isarに保存
      container.read(matchListProvider);
      await Future.delayed(const Duration(milliseconds: 100));

      final controller = container.read(matchActionProvider);
      try {
        await controller.processScoreEvent(testMatch, ScoreEvent(id: 'e1', side: Side.red, type: PointType.men, timestamp: DateTime.now(), sequence: 1));
      } catch (_) {
        // DomainException expected
      }
      await Future.delayed(const Duration(milliseconds: 100));

      final match = container.read(matchListProvider).firstWhere((m) => m.id == 'test_4');
      expect(match.redScore, 0);
    });

    test('異常系ガード: 残り時間が0秒の時はタイマーがスタートしないか', () async {
      final testMatch = const MatchModel(id: 'test_5', matchType: '大将', redName: '赤', whiteName: '白', remainingSeconds: 0, timerIsRunning: false);
      await container.read(localMatchRepositoryProvider).saveMatch(testMatch); // ★ Isarに保存
      container.read(matchListProvider);
      await Future.delayed(const Duration(milliseconds: 100));

      await container.read(matchTimerProvider).toggleTimer('test_5');
      await Future.delayed(const Duration(milliseconds: 100));

      final match = container.read(matchListProvider).firstWhere((m) => m.id == 'test_5');
      expect(match.timerIsRunning, false);
    });

    test('異常系ガード: イベントが0件の時にUndoを押してもクラッシュしないか', () async {
      final testMatch = const MatchModel(id: 'test_6', matchType: '先鋒', redName: '赤', whiteName: '白', events: []);
      await container.read(localMatchRepositoryProvider).saveMatch(testMatch); // ★ Isarに保存
      container.read(matchListProvider);
      await Future.delayed(const Duration(milliseconds: 100));

      final controller = container.read(matchActionProvider);
      await controller.undoEvent(testMatch);
      await Future.delayed(const Duration(milliseconds: 100));

      final match = container.read(matchListProvider).firstWhere((m) => m.id == 'test_6');
      expect(match.events.isEmpty, true);
    });

    test('排他制御(claimScorer): 他の人がスコアラーになっている時は横取りできないか', () async {
      final testMatch = const MatchModel(id: 'test_8', matchType: '中堅', redName: '赤', whiteName: '白', scorerId: 'User_A');
      await container.read(localMatchRepositoryProvider).saveMatch(testMatch); // ★ Isarに保存
      container.read(matchListProvider);
      await Future.delayed(const Duration(milliseconds: 100));

      final success = await container.read(matchCommandProvider).claimScorer('test_8', 'User_B');
      await Future.delayed(const Duration(milliseconds: 100));

      final match = container.read(matchListProvider).firstWhere((m) => m.id == 'test_8');
      expect(success, false);
      expect(match.scorerId, 'User_A');
    });
  });
}