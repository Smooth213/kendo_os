import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kendo_os/application/usecases/match_usecases.dart';
import 'package:kendo_os/domain/entities/match_model.dart';
import 'package:kendo_os/domain/rules/match_rule.dart';
import 'package:kendo_os/domain/entities/score_event.dart';
import 'package:kendo_os/infrastructure/repository/local_match_repository.dart';
import '../helpers/event_factory.dart';
import 'package:kendo_os/application/mappers/score_event_legacy_adapter.dart'; // ★ Adapterのimport追加
import 'package:kendo_os/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/domain/entities/role_permission.dart'; // ★ 追加

class MockLocalMatchRepository extends Mock implements LocalMatchRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(const MatchModel(id: 'dummy', matchType: '', redName: '', whiteName: ''));
  });

  late RebuildMatchFromEventsUseCase rebuildUseCase;
  final testUser = const User(id: 'test_user', role: Role.admin, organizationId: 'test_org'); // ★ 追加
  
  setUp(() {
    final container = ProviderContainer();
    rebuildUseCase = container.read(rebuildMatchFromEventsUseCaseProvider);
  });

  group('PHASE 4: 統合テスト - イベント駆動による試合フルシナリオ', () {
    late ProviderContainer container;
    late MockLocalMatchRepository mockRepo;
    late AddScoreUseCase addScoreUseCase;
    late UndoScoreUseCase undoScoreUseCase;
    late TimeUpUseCase timeUpUseCase;
    late MatchModel dummyMatch;

    setUp(() {
      dummyMatch = MatchModel( 
        id: 'test',
        tournamentId: 't1',
        matchOrder: 1,
        redName: 'Red',
        whiteName: 'White',
        status: 'in_progress',
        matchType: '個人戦',
        remainingSeconds: 180,
      );

      mockRepo = MockLocalMatchRepository();
      when(() => mockRepo.getMatch(any())).thenAnswer((_) async => dummyMatch);
      when(() => mockRepo.saveMatch(any())).thenAnswer((_) async {});

      container = ProviderContainer(
        overrides: [
          localMatchRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      addScoreUseCase = container.read(addScoreUseCaseProvider);
      undoScoreUseCase = container.read(undoScoreUseCaseProvider);
      timeUpUseCase = container.read(timeUpUseCaseProvider);
    });

    tearDown(() {
      container.dispose();
    });

    test('二本勝ち: men(red) -> kote(red) -> finished', () {
      final rule = MatchRule();
      var match = dummyMatch;

      match = addScoreUseCase.execute(testUser, match, men(Side.red), rule); // ★ 変更
      expect(match.redScore, 1);

      match = addScoreUseCase.execute(testUser, match, kote(Side.red), rule); // ★ 変更
      expect(match.redScore, 2);
      expect(match.status, 'finished');
    });

    test('反則負け: hansoku(white) x 4回 -> redWin', () {
      final rule = MatchRule();
      var match = dummyMatch;

      match = addScoreUseCase.execute(testUser, match, hansoku(Side.white), rule); // ★ 変更
      expect(match.redScore, 0); 

      match = addScoreUseCase.execute(testUser, match, hansoku(Side.white), rule); // ★ 変更
      expect(match.redScore, 1); 

      match = addScoreUseCase.execute(testUser, match, hansoku(Side.white), rule); // ★ 変更
      expect(match.redScore, 1); 

      match = addScoreUseCase.execute(testUser, match, hansoku(Side.white), rule); // ★ 変更
      expect(match.redScore, 2); 
      expect(match.status, 'finished');
    });

    test('Undoからの逆転: men(red) -> undo -> men(white) x 2 -> whiteWin', () {
      final rule = MatchRule();
      var match = dummyMatch;

      match = addScoreUseCase.execute(testUser, match, men(Side.red), rule); // ★ 変更
      expect(match.redScore, 1);

      match = undoScoreUseCase.execute(testUser, match, rule); // ★ 変更
      expect(match.redScore, 0);
      expect(match.events.last.isCanceled, isTrue);

      match = addScoreUseCase.execute(testUser, match, men(Side.white), rule); // ★ 変更
      expect(match.whiteScore, 1);

      match = addScoreUseCase.execute(testUser, match, men(Side.white), rule); // ★ 変更
      expect(match.whiteScore, 2);
      expect(match.status, 'finished');
    });

    test('不戦勝: fusen(red) -> redScore: 2 & finished', () {
      final rule = MatchRule();
      var match = dummyMatch;

      final fusenEvent = ScoreEvent(
        id: 'fusen',
        side: Side.red,
        isFusen: true,
        timestamp: DateTime.now(),
      );

      match = addScoreUseCase.execute(testUser, match, fusenEvent, rule); // ★ 変更
      expect(match.redScore, 2);
      expect(match.status, 'finished');
    });

    test('延長戦の死闘シナリオ: 同点で時間切れ -> 延長突入 -> 1本先取で即決着', () {
      final rule = MatchRule(isEnchoUnlimited: true);
      var match = dummyMatch.copyWith(events: <ScoreEvent>[]);

      match = addScoreUseCase.execute(testUser, match, men(Side.red), rule); // ★ 変更
      match = addScoreUseCase.execute(testUser, match, kote(Side.white), rule); // ★ 変更
      expect(match.redScore, 1);
      expect(match.whiteScore, 1);

      match = timeUpUseCase.execute(testUser, match, true, rule); // ★ 変更
      expect(match.matchType, '延長戦');
      expect(match.status, 'in_progress'); 

      match = addScoreUseCase.execute(testUser, match, men(Side.red), rule); // ★ 変更
      
      expect(match.redScore, 2);
      expect(match.status, 'finished');
    });

    test('勝ち抜き戦シナリオ: 大将戦での引き分け判定', () {
      var match = dummyMatch.copyWith(
        matchType: '勝ち抜き戦',
        isKachinuki: true,
        redRemaining: <String>[], 
        whiteRemaining: <String>[], 
      );
      final rule = MatchRule(kachinukiUnlimitedType: '大将引き分け延長なし');

      match = timeUpUseCase.execute(testUser, match, false, rule); // ★ 変更

      expect(match.status, 'finished');
    });

    test('PHASE 8: 勝敗確定後にUndoして技を入れても、残り時間が0秒にリセットされず維持されること', () {
      final rule = const MatchRule();
      var match = dummyMatch.copyWith(events: <ScoreEvent>[], remainingSeconds: 45);

      match = addScoreUseCase.execute(testUser, match, men(Side.red), rule); // ★ 変更
      match = addScoreUseCase.execute(testUser, match, kote(Side.red), rule); // ★ 変更
      expect(match.status, 'finished');
      expect(match.remainingSeconds, 45, reason: '残り時間は0にリセットされないべき');

      match = undoScoreUseCase.execute(testUser, match, rule); // ★ 変更
      expect(match.status, 'in_progress');
      expect(match.remainingSeconds, 45);

      match = addScoreUseCase.execute(testUser, match, dou(Side.white), rule); // ★ 変更
      expect(match.status, 'in_progress', reason: '時間切れではないため進行中であるべき');
      expect(match.remainingSeconds, 45);
    });
  });

  group('PHASE 6 & 7: 一連のバグ修正の回帰テスト（デグレ防止）', () {
    late KendoRuleEngine engine;
    late AddScoreUseCase addScoreUseCase;
    late UndoScoreUseCase undoScoreUseCase;
    late MatchModel dummyMatch;

    setUp(() {
      engine = KendoRuleEngine();
      final permission = PermissionService(); // ★ 関所を追加
      addScoreUseCase = AddScoreUseCase(engine, permission); // ★ 引数追加
      undoScoreUseCase = UndoScoreUseCase(engine, permission); // ★ 引数追加
      dummyMatch = const MatchModel(
        id: 'test_regression',
        tournamentId: 't1',
        matchOrder: 1,
        redName: 'Red',
        whiteName: 'White',
        status: 'in_progress',
        matchType: '個人戦',
        remainingSeconds: 180,
      );
    });

    test('手動終了(終了マーカー追加)後のUndoで、直前の取得部位が消えずに進行中に戻ること', () {
      final rule = MatchRule();
      var match = dummyMatch.copyWith(events: <ScoreEvent>[]);

      match = addScoreUseCase.execute(testUser, match, men(Side.red), rule); // ★ 変更
      expect(match.redScore, 1);
      expect(match.status, 'in_progress');

      final finishMarker = ScoreEventLegacyAdapter.fromLegacy(
        id: 'marker-1', type: PointType.hantei, side: Side.none, timestamp: DateTime.now(),
      );
      match = addScoreUseCase.execute(testUser, match, finishMarker, rule); // ★ 変更
      match = match.copyWith(status: 'finished'); 

      match = undoScoreUseCase.execute(testUser, match, rule); // ★ 変更
      
      expect(match.status, 'in_progress', reason: '終了マーカーが取り消され、進行中に戻るべき');
      expect(match.redScore, 1, reason: '直前のメンは取り消されず、スコア1が維持されるべき');
      expect(match.events.last.isCanceled, isTrue, reason: '最新のマーカーイベントのみがキャンセルされるべき');
      expect(match.events.first.isCanceled, isFalse, reason: '最初のメンは有効なままであるべき');
    });

    test('終了ステータスからでも判定(hantei)を入力でき、スコアに反映されて終了状態を維持すること', () {
      final rule = MatchRule(hasHantei: true);
      var match = dummyMatch.copyWith(events: <ScoreEvent>[], status: 'finished', remainingSeconds: 0); 

      final hanteiEvent = ScoreEventLegacyAdapter.fromLegacy(
        id: 'hantei-1', type: PointType.hantei, side: Side.white, timestamp: DateTime.now(),
      );

      match = addScoreUseCase.execute(testUser, match, hanteiEvent, rule); // ★ 変更

      expect(match.whiteScore, 1, reason: '判定によって白に1ポイント入るべき');
      expect(match.status, 'finished', reason: '判定決着後は終了ステータスになるべき');
    });
  });

  test('PHASE 5: バグ修正の回帰テスト - 判定や引き分けで終了した試合が、再構築されても進行中に巻き戻らないこと', () {
      final rule = MatchRule( 
        matchTimeMinutes: 3,
        positions: ['個人戦'],
        isDaihyoIpponShobu: false,
        hasRepresentativeMatch: false,
        isEnchoUnlimited: false,
        enchoTimeMinutes: 0,
        enchoCount: 0,
        hasHantei: true, 
        isLeague: false,
        isKachinuki: false,
        renseikaiType: '',
        overallTimeMinutes: 0,
        isRunningTime: false,
      );
      
      var match = MatchModel(
        id: 'bug-fix-test-1',
        matchType: '個人戦',
        redName: '赤',
        whiteName: '白',
        status: 'in_progress',
        order: 1,
        matchTimeMinutes: 3,
        rule: rule,
      );

      final hanteiEvent = ScoreEventLegacyAdapter.fromLegacy(
        id: 'hantei-1',
        type: PointType.hantei,
        side: Side.red,
        timestamp: DateTime.now(),
      );

      match = match.copyWith(
        status: 'finished', 
        timerIsRunning: false,
        hasExtension: false,
        events: [hanteiEvent],
      );

      final rebuiltMatch = rebuildUseCase.execute(match, rule); // ★ 再構築は読み取りなのでUser不要のまま

      expect(rebuiltMatch.status, 'finished', reason: '判定イベントがある場合、再構築してもfinishedを維持すべき');
      expect(rebuiltMatch.redScore, greaterThan(rebuiltMatch.whiteScore), reason: '赤の判定勝ちは、赤のスコア優位として計算されるべき');
    });
}