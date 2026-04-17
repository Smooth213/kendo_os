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
import 'package:kendo_os/providers/match_provider.dart';
import 'package:kendo_os/providers/audit_provider.dart';
import 'package:kendo_os/providers/settings_provider.dart';
import 'package:kendo_os/providers/match_rule_provider.dart';
import 'package:kendo_os/services/sound_service.dart';

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

void main() {
  group('MatchListProvider (Score Logic) Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late ProviderContainer container;

    setUpAll(() {
      registerFallbackValue(MatchModel(id: 'd', matchType: '', redName: '', whiteName: ''));
    });

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      
      final mockAudit = MockAuditService();
      when(() => mockAudit.logAction(
        matchId: any(named: 'matchId'),
        action: any(named: 'action'),
        details: any(named: 'details'),
      )).thenAnswer((_) async => {});

      container = ProviderContainer(
        overrides: [
          firestoreProvider.overrideWithValue(fakeFirestore),
          auditProvider.overrideWithValue(mockAudit),
          soundServiceProvider.overrideWithValue(MockSoundService()),
          // ★ 不足していたオーバーライドを追加
          settingsProvider.overrideWith(() => MockSettingsNotifier(const SettingsModel(confirmBehavior: 'manual'))),
          matchRuleProvider.overrideWith(() => MockMatchRuleNotifier()),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('addScoreEventで「面」が正しく追加され、スコアが増えるか', () async {
      final testMatch = const MatchModel(id: 'test_1', matchType: '先鋒', redName: '赤', whiteName: '白');
      await fakeFirestore.collection('matches').doc('test_1').set(testMatch.toJson());
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
      await fakeFirestore.collection('matches').doc('test_2').set(testMatch.toJson());
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
      await fakeFirestore.collection('matches').doc('test_3').set(testMatch.toJson());
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
      await fakeFirestore.collection('matches').doc('test_4').set(testMatch.toJson());
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
      await fakeFirestore.collection('matches').doc('test_5').set(testMatch.toJson());
      container.read(matchListProvider);
      await Future.delayed(const Duration(milliseconds: 100));

      await container.read(matchTimerProvider).toggleTimer('test_5');
      await Future.delayed(const Duration(milliseconds: 100));

      final match = container.read(matchListProvider).firstWhere((m) => m.id == 'test_5');
      expect(match.timerIsRunning, false);
    });

    test('異常系ガード: イベントが0件の時にUndoを押してもクラッシュしないか', () async {
      final testMatch = const MatchModel(id: 'test_6', matchType: '先鋒', redName: '赤', whiteName: '白', events: []);
      await fakeFirestore.collection('matches').doc('test_6').set(testMatch.toJson());
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
      await fakeFirestore.collection('matches').doc('test_8').set(testMatch.toJson());
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