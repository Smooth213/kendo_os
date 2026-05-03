import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kendo_os/application/usecases/match_usecases.dart';
import 'package:kendo_os/domain/entities/match_model.dart';
import 'package:kendo_os/domain/rules/match_rule.dart';
import 'package:kendo_os/domain/entities/score_event.dart';
import 'package:kendo_os/infrastructure/repository/local_match_repository.dart';
import '../helpers/event_factory.dart';

class MockLocalMatchRepository extends Mock implements LocalMatchRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(const MatchModel(id: 'dummy', matchType: '', redName: '', whiteName: ''));
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
  });
}