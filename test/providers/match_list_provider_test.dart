import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kendo_os/providers/match_list_provider.dart';
import 'package:kendo_os/models/match_model.dart';
import 'package:kendo_os/models/score_event.dart';
import 'package:kendo_os/models/settings_model.dart';
import 'package:kendo_os/models/match_rule.dart';
import 'package:kendo_os/providers/match_command_provider.dart';
import 'package:kendo_os/providers/match_timer_provider.dart';
import 'package:isar_community/isar.dart';
import 'package:kendo_os/repositories/local_match_repository.dart';
import 'package:kendo_os/models/local/match_entity.dart'; // ★ スキーマ（設計図）を読み込む
import 'package:kendo_os/providers/match_provider.dart';
import 'package:kendo_os/providers/audit_provider.dart';
import 'package:kendo_os/providers/settings_provider.dart';
import 'package:kendo_os/providers/match_rule_provider.dart';
import 'package:kendo_os/services/sound_service.dart';
import 'package:kendo_os/repositories/match_repository.dart'; // ★ MatchRepositoryの型を読み込む
import 'dart:async'; // ★ StreamController用
import 'dart:io'; // ★ 一時ディレクトリ取得のために追加
import 'package:kendo_os/providers/sync_provider.dart'; // ★ connectivityProviderをモックするために追加

class MockAuditService extends Mock implements AuditService {}
class MockSoundService extends Mock implements SoundService {}

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

// ★ LocalMatchRepository の挙動をテスト用に拡張し、Streamの発火を確実に捉えるクラス
class TestLocalMatchRepository extends LocalMatchRepository {
  final StreamController<List<MatchModel>> _controller = StreamController<List<MatchModel>>.broadcast();
  final List<MatchModel> _cache = [];
  final FakeFirebaseFirestore fakeFirestore; // ★ Firestoreに依存しているコードのための保険

  TestLocalMatchRepository(super.isar, this.fakeFirestore);

  @override
  Stream<List<MatchModel>> watchMatches() async* {
    // ★ 購読された瞬間に必ず「最新のキャッシュ」を流す（Dart標準の完璧なBehaviorSubject）
    yield List.from(_cache);
    yield* _controller.stream;
  }

  @override
  Future<void> saveMatch(MatchModel match) async {
    await super.saveMatch(match); // Isarに保存（整合性チェック）
    
    // ★ matchListProvider がまだ Firestore を見ている可能性を考慮し、FakeFirestore にも同期する
    await fakeFirestore.collection('matches').doc(match.id).set(match.toJson());

    // テスト環境のStream遅延を防ぐため、ここで確実にキャッシュを更新して通知する
    final index = _cache.indexWhere((m) => m.id == match.id);
    if (index >= 0) {
      _cache[index] = match;
    } else {
      _cache.add(match);
    }
    _controller.add(List.from(_cache));
  }
}

// ★ Firestore用のRepositoryを偽装し、強制的にIsar(ローカル)へデータを流し込むためのモッククラス
class TestMatchRepository extends Fake implements MatchRepository {
  final TestLocalMatchRepository localRepo;
  TestMatchRepository(this.localRepo);

  @override
  Stream<List<MatchModel>> watchMatches() => localRepo.watchMatches();

  @override
  Stream<MatchModel> watchSingleMatch(String matchId) {
    return localRepo.watchMatches().map((list) => list.firstWhere((m) => m.id == matchId, orElse: () => const MatchModel(id: '', matchType: '', redName: '', whiteName: '')));
  }

  @override
  Future<void> saveMatch(MatchModel match) => localRepo.saveMatch(match);
}

void main() {
  // ★ CRITICAL: ネイティブ機能（Wi-Fiチェックやバイブなど）をテスト環境でモックアップするために必須の1行
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MatchListProvider (Score Logic) Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late Isar isar;
    late ProviderContainer container;

    setUpAll(() {
      registerFallbackValue(MatchModel(id: 'd', matchType: '', redName: '', whiteName: ''));
    });

    setUp(() async {
      // Isarのコアライブラリを初期化 (テスト実行に必須)
      await Isar.initializeIsarCore(download: true);
      
      // OSの一時フォルダ（tmp）を取得して、そこにテスト用DBを作る
      final tempDir = Directory.systemTemp.createTempSync('isar_test_');
      
      // テスト用のデータベースを構築
      isar = await Isar.open(
        [MatchEntitySchema],
        directory: tempDir.path, // ★ プロジェクト直下ではなく、一時フォルダを指定
        name: 'test_isar_${DateTime.now().microsecondsSinceEpoch}', 
      );

      fakeFirestore = FakeFirebaseFirestore();
      
      final mockAudit = MockAuditService();
      when(() => mockAudit.logAction(
        matchId: any(named: 'matchId'),
        action: any(named: 'action'),
        details: any(named: 'details'),
      )).thenAnswer((_) async => {});

      final testLocalRepo = TestLocalMatchRepository(isar, fakeFirestore);

      container = ProviderContainer(
        overrides: [
          firestoreProvider.overrideWithValue(fakeFirestore),
          isarProvider.overrideWithValue(isar), // ★ Isar の鍵をテスト環境にも注入！
          auditProvider.overrideWithValue(mockAudit),
          soundServiceProvider.overrideWithValue(MockSoundService()),
          // ★ 不足していたオーバーライドを追加
          settingsProvider.overrideWith(() => MockSettingsNotifier(const SettingsModel(confirmBehavior: 'manual'))),
          matchRuleProvider.overrideWith(() => MockMatchRuleNotifier()),
          // ★ 書き込み先（LocalRepo）も拡張版に差し替える
          localMatchRepositoryProvider.overrideWithValue(testLocalRepo),
          // ★ 読み込み側(MatchRepository)もIsarに向けるように強制バイパス
          matchRepositoryProvider.overrideWith((ref) => TestMatchRepository(testLocalRepo)),
          // ★ 追加: Connectivityプラグインによるネイティブ通信エラーを防ぐ
          connectivityProvider.overrideWith((ref) => Stream.value(true)),
        ],
      );

      // ★ テスト中にStreamが途切れてListが空(Bad state)になるのを防ぐため、常に監視状態を維持する
      container.listen(matchListProvider, (_, _) {});
    });

    tearDown(() async {
      container.dispose();
      await isar.close(deleteFromDisk: true); // テストが終わったらIsarを破棄
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
      await controller.processScoreEvent(testMatch, ScoreEvent(id: 'e1', side: Side.red, type: PointType.men, timestamp: DateTime.now(), sequence: 1));
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