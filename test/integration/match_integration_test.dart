import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kendo_os/providers/match_provider.dart';
import 'package:kendo_os/providers/match_command_provider.dart';
import 'package:kendo_os/providers/audit_provider.dart';
import 'package:kendo_os/services/sound_service.dart';
import 'package:kendo_os/providers/settings_provider.dart';
import 'package:kendo_os/providers/match_rule_provider.dart'; // 追加
import 'package:kendo_os/providers/match_list_provider.dart';
import 'package:kendo_os/models/score_event.dart';
import 'package:kendo_os/models/match_model.dart';
import 'package:kendo_os/models/match_rule.dart';
import 'package:kendo_os/models/settings_model.dart';
import '../helpers/test_match_factory.dart';

class MockMatchCommand extends Mock implements MatchCommand {}
class MockAuditService extends Mock implements AuditService {}
class MockSoundService extends Mock implements SoundService {}

// ★ Step 4-1 修正: NotifierProvider 用のモッククラス
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

final mockMatchListProvider = StateProvider<List<MatchModel>>((ref) => []);

void main() {
  late ProviderContainer container;
  late MockMatchCommand mockCommand;
  late MockAuditService mockAudit;
  
  setUpAll(() {
    registerFallbackValue(MatchModel(id: 'dummy', matchType: '', redName: '', whiteName: ''));
  });

  setUp(() {
    mockCommand = MockMatchCommand();
    mockAudit = MockAuditService();
    
    container = ProviderContainer(
      overrides: [
        matchCommandProvider.overrideWithValue(mockCommand),
        auditProvider.overrideWithValue(mockAudit),
        soundServiceProvider.overrideWithValue(MockSoundService()),
        settingsProvider.overrideWith(() => MockSettingsNotifier(const SettingsModel(confirmBehavior: 'manual'))),
        // ルールもデフォルト値でオーバーライド
        matchRuleProvider.overrideWith(() => MockMatchRuleNotifier()),
        matchListProvider.overrideWith((ref) => ref.watch(mockMatchListProvider)),
      ],
    );

    when(() => mockCommand.saveMatch(any())).thenAnswer((_) async => {});
    when(() => mockAudit.logAction(
      matchId: any(named: 'matchId'),
      action: any(named: 'action'),
      details: any(named: 'details'),
    )).thenAnswer((_) async => {});
  });

  tearDown(() {
    container.dispose();
  });

  group('PHASE 4: 統合テスト - Step 4-1: 試合フルシナリオ', () {
    test('赤(面) -> 白(小手) -> 赤(面) の順で試合が決着する流れを完遂できること', () async {
      final controller = container.read(matchActionProvider);
      var match = TestMatchFactory.createIndividualMatch(id: 'match-101');
      container.read(mockMatchListProvider.notifier).state = [match];

      // 1. 赤が面
      await controller.processScoreEvent(match, TestMatchFactory.createEvent(side: Side.red, type: PointType.men));
      match = verify(() => mockCommand.saveMatch(captureAny())).captured.last as MatchModel;
      container.read(mockMatchListProvider.notifier).state = [match];

      // 2. 白が小手
      await controller.processScoreEvent(match, TestMatchFactory.createEvent(side: Side.white, type: PointType.kote));
      match = verify(() => mockCommand.saveMatch(captureAny())).captured.last as MatchModel;
      container.read(mockMatchListProvider.notifier).state = [match];

      // 3. 赤が面
      await controller.processScoreEvent(match, TestMatchFactory.createEvent(side: Side.red, type: PointType.men));
      match = verify(() => mockCommand.saveMatch(captureAny())).captured.last as MatchModel;
      container.read(mockMatchListProvider.notifier).state = [match];

      expect(match.redScore, 2);
      expect(match.status, 'finished');

      // 修正：名前付き引数に named API を適用
      verify(() => mockAudit.logAction(
        matchId: 'match-101',
        action: 'add_score',
        details: any(named: 'details'),
      )).called(3);
    });
  });

  group('PHASE 4: 統合テスト - Step 4-2: 延長戦の死闘シナリオ', () {
    test('同点で時間切れ -> 延長突入 -> 1本先取で即決着の流れが正しく動作すること', () async {
      final controller = container.read(matchActionProvider);
      
      var match = TestMatchFactory.createIndividualMatch(id: 'match-ext-01');
      container.read(mockMatchListProvider.notifier).state = [match];
      await controller.handleTimeUp(match, true); 

      match = verify(() => mockCommand.saveMatch(captureAny())).captured.last as MatchModel;
      container.read(mockMatchListProvider.notifier).state = [match];
      expect(match.note, contains('延長'));
      expect(match.status, 'in_progress');

      await controller.processScoreEvent(match, TestMatchFactory.createEvent(side: Side.red, type: PointType.kote));
      match = verify(() => mockCommand.saveMatch(captureAny())).captured.last as MatchModel;
      container.read(mockMatchListProvider.notifier).state = [match];

      expect(match.redScore, 1);
      expect(match.status, 'finished');
    });
  });

  group('PHASE 4: 統合テスト - Step 4-3: 反則・不戦勝シナリオ', () {
    test('赤の反則が2回重なった時、白に一本（反）が入り、保存されること', () async {
      final controller = container.read(matchActionProvider);
      var match = TestMatchFactory.createIndividualMatch(id: 'match-hansoku-01');
      container.read(mockMatchListProvider.notifier).state = [match];

      // 1. 赤が反則1回目
      await controller.processScoreEvent(match, TestMatchFactory.createEvent(side: Side.red, type: PointType.hansoku, sequence: 1));
      match = verify(() => mockCommand.saveMatch(captureAny())).captured.last as MatchModel;
      container.read(mockMatchListProvider.notifier).state = [match];
      expect(match.whiteScore, 0);

      // 2. 赤が反則2回目
      await controller.processScoreEvent(match, TestMatchFactory.createEvent(side: Side.red, type: PointType.hansoku, sequence: 2));
      match = verify(() => mockCommand.saveMatch(captureAny())).captured.last as MatchModel;
      container.read(mockMatchListProvider.notifier).state = [match];

      expect(match.whiteScore, 1);
      expect(match.events.length, 2);
    });

    test('不戦勝（Fusen）が入力された際、即座に2本先取で試合が終了すること', () async {
      final controller = container.read(matchActionProvider);
      var match = TestMatchFactory.createIndividualMatch(id: 'match-fusen-01');
      container.read(mockMatchListProvider.notifier).state = [match];

      await controller.processScoreEvent(match, TestMatchFactory.createEvent(side: Side.white, type: PointType.fusen));
      match = verify(() => mockCommand.saveMatch(captureAny())).captured.last as MatchModel;
      container.read(mockMatchListProvider.notifier).state = [match];

      expect(match.whiteScore, 2);
      expect(match.status, 'finished');
    });
  });

  group('PHASE 4: 統合テスト - Step 4-4: Undoを織り交ぜたリカバリシナリオ', () {
    test('誤入力を Undo し、その後正しく試合が決着する一連の動作を保証すること', () async {
      final controller = container.read(matchActionProvider);
      var match = TestMatchFactory.createIndividualMatch(id: 'match-recovery-01');
      container.read(mockMatchListProvider.notifier).state = [match];

      // 1. 赤が面を決める (1-0)
      await controller.processScoreEvent(match, TestMatchFactory.createEvent(side: Side.red, type: PointType.men, sequence: 1));
      match = verify(() => mockCommand.saveMatch(captureAny())).captured.last as MatchModel;
      container.read(mockMatchListProvider.notifier).state = [match];
      expect(match.redScore, 1);

      // 2. 白が小手と誤入力される (1-1)
      await controller.processScoreEvent(match, TestMatchFactory.createEvent(side: Side.white, type: PointType.kote, sequence: 2));
      match = verify(() => mockCommand.saveMatch(captureAny())).captured.last as MatchModel;
      container.read(mockMatchListProvider.notifier).state = [match];
      expect(match.whiteScore, 1);

      // 3. Undoを実行して白の小手を取り消す (1-0)
      await controller.undoEvent(match);
      match = verify(() => mockCommand.saveMatch(captureAny())).captured.last as MatchModel;
      container.read(mockMatchListProvider.notifier).state = [match];
      expect(match.redScore, 1);
      expect(match.whiteScore, 0);
      // ★ 白の小手イベントが「論理削除」されていることを検証
      expect(match.events.last.isCanceled, true);
      expect(match.events.last.type, PointType.kote);

      // 4. 赤が胴を決めて決着 (2-0)
      await controller.processScoreEvent(match, TestMatchFactory.createEvent(side: Side.red, type: PointType.doIdo, sequence: 4));
      match = verify(() => mockCommand.saveMatch(captureAny())).captured.last as MatchModel;
      container.read(mockMatchListProvider.notifier).state = [match];

      expect(match.redScore, 2);
      expect(match.status, 'finished');
      
      // 監査ログに undo と add_score が正しく記録されているか検証
      verify(() => mockAudit.logAction(matchId: 'match-recovery-01', action: 'undo', details: any(named: 'details'))).called(1);
      verify(() => mockAudit.logAction(matchId: 'match-recovery-01', action: 'add_score', details: any(named: 'details'))).called(3);
    });
  });
}