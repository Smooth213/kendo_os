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

class MockLocalMatchRepository extends Mock implements LocalMatchRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(const MatchModel(id: 'dummy', matchType: '', redName: '', whiteName: ''));
  });

  // ★ バグ修正回帰テスト用の UseCase インスタンスを準備
  late RebuildMatchFromEventsUseCase rebuildUseCase;
  
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
      dummyMatch = MatchModel( // ★ constを外し、コンパイラクラッシュを回避
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

      match = addScoreUseCase.execute(match, men(Side.red), rule);
      expect(match.redScore, 1);

      match = addScoreUseCase.execute(match, kote(Side.red), rule);
      expect(match.redScore, 2);
      expect(match.status, 'finished');
    });

    test('反則負け: hansoku(white) x 4回 -> redWin', () {
      final rule = MatchRule();
      var match = dummyMatch;

      match = addScoreUseCase.execute(match, hansoku(Side.white), rule);
      expect(match.redScore, 0); // 1回目

      match = addScoreUseCase.execute(match, hansoku(Side.white), rule);
      expect(match.redScore, 1); // 2回目で1本

      match = addScoreUseCase.execute(match, hansoku(Side.white), rule);
      expect(match.redScore, 1); // 3回目

      match = addScoreUseCase.execute(match, hansoku(Side.white), rule);
      expect(match.redScore, 2); // 4回目で2本目
      expect(match.status, 'finished');
    });

    test('Undoからの逆転: men(red) -> undo -> men(white) x 2 -> whiteWin', () {
      final rule = MatchRule();
      var match = dummyMatch;

      match = addScoreUseCase.execute(match, men(Side.red), rule);
      expect(match.redScore, 1);

      match = undoScoreUseCase.execute(match, rule);
      expect(match.redScore, 0);
      expect(match.events.last.isCanceled, isTrue);

      match = addScoreUseCase.execute(match, men(Side.white), rule);
      expect(match.whiteScore, 1);

      match = addScoreUseCase.execute(match, men(Side.white), rule);
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

      match = addScoreUseCase.execute(match, fusenEvent, rule);
      expect(match.redScore, 2);
      expect(match.status, 'finished');
    });

    test('延長戦の死闘シナリオ: 同点で時間切れ -> 延長突入 -> 1本先取で即決着', () {
      final rule = MatchRule(isEnchoUnlimited: true);
      var match = dummyMatch.copyWith(events: <ScoreEvent>[]);

      // 1. 本戦: 1-1 の同点
      match = addScoreUseCase.execute(match, men(Side.red), rule);
      match = addScoreUseCase.execute(match, kote(Side.white), rule);
      expect(match.redScore, 1);
      expect(match.whiteScore, 1);

      // 2. 時間切れ -> 延長戦へ
      match = timeUpUseCase.execute(match, true, rule);
      expect(match.matchType, '延長戦');
      expect(match.status, 'in_progress'); // 続行中

      // 3. 延長戦: 赤が面を決める
      match = addScoreUseCase.execute(match, men(Side.red), rule);
      
      // Assert: 延長戦なので1本決まった瞬間に finished になること
      expect(match.redScore, 2);
      expect(match.status, 'finished');
    });

    test('勝ち抜き戦シナリオ: 大将戦での引き分け判定', () {
      // 勝ち抜き戦特有のプロパティ（残人数など）を持つ MatchModel を用意
      var match = dummyMatch.copyWith(
        matchType: '勝ち抜き戦',
        isKachinuki: true,
        redRemaining: <String>[], // 赤は大将のみ（残り0人）
        whiteRemaining: <String>[], // 白も大将のみ（残り0人）
      );
      final rule = MatchRule(kachinukiUnlimitedType: '大将引き分け延長なし');

      // スコア 0-0 で時間切れ
      match = timeUpUseCase.execute(match, false, rule);

      // Assert: 大将同士で引き分け、延長なし設定なら試合終了
      expect(match.status, 'finished');
    });

    test('PHASE 8: 勝敗確定後にUndoして技を入れても、残り時間が0秒にリセットされず維持されること', () {
      final rule = const MatchRule();
      var match = dummyMatch.copyWith(events: <ScoreEvent>[], remainingSeconds: 45);

      // 1. 赤が2本先取して勝負あり
      match = addScoreUseCase.execute(match, men(Side.red), rule);
      match = addScoreUseCase.execute(match, kote(Side.red), rule);
      expect(match.status, 'finished');
      expect(match.remainingSeconds, 45, reason: '残り時間は0にリセットされないべき');

      // 2. Undoして進行中に戻す
      match = undoScoreUseCase.execute(match, rule);
      expect(match.status, 'in_progress');
      expect(match.remainingSeconds, 45);

      // 3. 次の技が入っても、残り時間が残っているため即終了にならない
      match = addScoreUseCase.execute(match, dou(Side.white), rule);
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
      addScoreUseCase = AddScoreUseCase(engine);
      undoScoreUseCase = UndoScoreUseCase(engine);
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

      // 1. 赤がメンを先制
      match = addScoreUseCase.execute(match, men(Side.red), rule);
      expect(match.redScore, 1);
      expect(match.status, 'in_progress');

      // 2. 1本勝ちとして手動終了（UI側で finishMatchManually を呼ぶと hantei マーカーが追加される仕様を模倣）
      final finishMarker = ScoreEventLegacyAdapter.fromLegacy(
        id: 'marker-1', type: PointType.hantei, side: Side.none, timestamp: DateTime.now(),
      );
      match = addScoreUseCase.execute(match, finishMarker, rule);
      match = match.copyWith(status: 'finished'); // Service層で行われるステータスの強制上書きを模倣

      // 3. 終了を取り消す(Undo)
      match = undoScoreUseCase.execute(match, rule);
      
      // Assert: ここが崩れると「取得部位が消えるバグ」や「進行中に戻らないバグ」が再発する
      expect(match.status, 'in_progress', reason: '終了マーカーが取り消され、進行中に戻るべき');
      expect(match.redScore, 1, reason: '直前のメンは取り消されず、スコア1が維持されるべき');
      expect(match.events.last.isCanceled, isTrue, reason: '最新のマーカーイベントのみがキャンセルされるべき');
      expect(match.events.first.isCanceled, isFalse, reason: '最初のメンは有効なままであるべき');
    });

    test('終了ステータスからでも判定(hantei)を入力でき、スコアに反映されて終了状態を維持すること', () {
      final rule = MatchRule(hasHantei: true);
      // 時間切れ等で既に終了している状態を模倣
      var match = dummyMatch.copyWith(events: <ScoreEvent>[], status: 'finished', remainingSeconds: 0); 

      // 判定勝ち（白）の入力
      final hanteiEvent = ScoreEventLegacyAdapter.fromLegacy(
        id: 'hantei-1', type: PointType.hantei, side: Side.white, timestamp: DateTime.now(),
      );

      // 終了ステータスでもAddScoreUseCaseで弾かれないこと（validateEventのガード緩和の確認）
      match = addScoreUseCase.execute(match, hanteiEvent, rule);

      // Assert: ここが崩れると「時間切れ後に判定が入力できないバグ」が再発する
      expect(match.whiteScore, 1, reason: '判定によって白に1ポイント入るべき');
      expect(match.status, 'finished', reason: '判定決着後は終了ステータスになるべき');
    });
  });

  test('PHASE 5: バグ修正の回帰テスト - 判定や引き分けで終了した試合が、再構築されても進行中に巻き戻らないこと', () {
      // 1. 試合の準備 (判定ありのルール)
      final rule = MatchRule( // ★ KendoMatchRule から MatchRule に修正
        matchTimeMinutes: 3,
        positions: ['個人戦'],
        isDaihyoIpponShobu: false,
        hasRepresentativeMatch: false,
        isEnchoUnlimited: false,
        enchoTimeMinutes: 0,
        enchoCount: 0,
        hasHantei: true, // 判定あり
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

      // 2. 判定勝ちイベントを作成し、試合を「手動で終了(finished)」状態にする
      // これは match_screen.dart で判定ダイアログから確定した時の状態を模倣しています
      final hanteiEvent = ScoreEventLegacyAdapter.fromLegacy(
        id: 'hantei-1',
        type: PointType.hantei,
        side: Side.red,
        timestamp: DateTime.now(),
      );

      match = match.copyWith(
        status: 'finished', // ここで終了にしている
        timerIsRunning: false,
        hasExtension: false,
        events: [hanteiEvent],
      );

      // 3. 【最も重要なテスト】イベント履歴から試合状態を再構築(Rebuild)する
      // （※バグ発生時は、ここで PointType.hantei が無視され、2本取ってないとみなされて in_progress に降格していました）
      final rebuiltMatch = rebuildUseCase.execute(match, rule);

      // 4. 検証（Assert）
      // ① 再構築されても、ステータスが 'finished' のままであること（巻き戻っていないこと）
      expect(rebuiltMatch.status, 'finished', reason: '判定イベントがある場合、再構築してもfinishedを維持すべき');
      // ② 赤のスコアが白を上回っていること（判定がスコアとしてカウントされていること）
      expect(rebuiltMatch.redScore, greaterThan(rebuiltMatch.whiteScore), reason: '赤の判定勝ちは、赤のスコア優位として計算されるべき');
    });
}