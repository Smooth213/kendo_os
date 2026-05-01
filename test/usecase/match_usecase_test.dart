import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/domain/kendo_rule_engine.dart';
// ★ 修正: 移動したScoreEventとMatchRuleの絶対パス（住所）を追加
import 'package:kendo_os/domain/match/score_event.dart';
import 'package:kendo_os/application/usecase/match_usecases.dart';
import '../helpers/test_match_factory.dart';

void main() {
  late KendoRuleEngine engine;
  late AddScoreUseCase addScoreUseCase;
  late UndoScoreUseCase undoScoreUseCase;

  setUp(() {
    engine = KendoRuleEngine();
    addScoreUseCase = AddScoreUseCase(engine);
    undoScoreUseCase = UndoScoreUseCase(engine);
  });

  group('MatchUseCase - スコア操作テスト', () {
    test('ポイント追加によって MatchModel のスコアが更新されること', () {
      // Given: 初期状態の試合とルール
      final match = TestMatchFactory.createIndividualMatch();
      final rule = TestMatchFactory.createDefaultRule();
      final event = TestMatchFactory.createEvent(
        side: Side.red,
        type: PointType.men,
      );

      // When: UseCase経由でスコアを追加
      final updatedMatch = addScoreUseCase.execute(match, event, rule);

      // Then: MatchModel の状態が更新されていること
      expect(updatedMatch.redScore, 1);
      expect(updatedMatch.events.length, 1);
      expect(updatedMatch.events.first.type, PointType.men);
    });

    test('2本先取した瞬間に試合ステータスが finished になること', () {
      final match = TestMatchFactory.createIndividualMatch();
      final rule = TestMatchFactory.createDefaultRule();
      
      final e1 = TestMatchFactory.createEvent(side: Side.red, type: PointType.men, sequence: 1);
      final e2 = TestMatchFactory.createEvent(side: Side.red, type: PointType.kote, sequence: 2);

      final matchAfter1 = addScoreUseCase.execute(match, e1, rule);
      final matchAfter2 = addScoreUseCase.execute(matchAfter1, e2, rule);

      expect(matchAfter2.redScore, 2);
      expect(matchAfter2.status, 'finished');
    });
  });

  group('MatchUseCase - Undo操作テスト', () {
    test('Undoによってスコアが1手前の状態に戻ること', () {
      // Given: 1本取った状態の試合
      final match = TestMatchFactory.createIndividualMatch();
      final rule = TestMatchFactory.createDefaultRule();
      final e1 = TestMatchFactory.createEvent(side: Side.red, type: PointType.men);
      final matchWithScore = addScoreUseCase.execute(match, e1, rule);
      expect(matchWithScore.redScore, 1);

      // When: Undoを実行
      final undoneMatch = undoScoreUseCase.execute(matchWithScore, rule);

      // Then: スコアが0に戻り、対象イベントが「論理削除（isCanceled = true）」されていること
      expect(undoneMatch.redScore, 0);
      expect(undoneMatch.events.last.isCanceled, true); // ★ 非破壊Undoの検証
      expect(undoneMatch.events.last.type, PointType.men); // ★ イベント自体は消えず残っていること
    });

    test('2本取って終了した試合でもUndoで再開できること', () {
      final match = TestMatchFactory.createIndividualMatch();
      final rule = TestMatchFactory.createDefaultRule();
      
      final e1 = TestMatchFactory.createEvent(side: Side.red, type: PointType.men, sequence: 1);
      final e2 = TestMatchFactory.createEvent(side: Side.red, type: PointType.kote, sequence: 2);
      final matchFinished = addScoreUseCase.execute(addScoreUseCase.execute(match, e1, rule), e2, rule);
      expect(matchFinished.status, 'finished');

      // When: Undoを実行
      final resumedMatch = undoScoreUseCase.execute(matchFinished, rule);

      // Then: スコアが1に戻り、ステータスが in_progress に戻ること
      expect(resumedMatch.redScore, 1);
      expect(resumedMatch.status, 'in_progress');
    });
  });

  group('MatchUseCase - 試合終了ガードテスト', () {
    test('試合終了状態（finished）では、追加のスコアが無視されるか例外を投げること', () {
      // Given: 既に終了した試合
      final match = TestMatchFactory.createIndividualMatch().copyWith(status: 'finished');
      final rule = TestMatchFactory.createDefaultRule();
      final event = TestMatchFactory.createEvent(side: Side.red, type: PointType.men);

      // When & Then: DomainException が投げられることを確認
      // (UseCaseがエンジンを使用してバリデーションを行っている前提)
      expect(
        () => addScoreUseCase.execute(match, event, rule),
        throwsA(isA<DomainException>()),
      );
    });

    test('規定本数に達して自動終了した試合に、さらにスコアを重ねることはできないこと', () {
      // Given: 2本取って終了した試合
      final match = TestMatchFactory.createIndividualMatch();
      final rule = TestMatchFactory.createDefaultRule();
      final e1 = TestMatchFactory.createEvent(side: Side.red, type: PointType.men, sequence: 1);
      final e2 = TestMatchFactory.createEvent(side: Side.red, type: PointType.kote, sequence: 2);
      final finishedMatch = addScoreUseCase.execute(addScoreUseCase.execute(match, e1, rule), e2, rule);
      
      expect(finishedMatch.status, 'finished');

      // When: 3本目を追加しようとする
      final e3 = TestMatchFactory.createEvent(side: Side.red, type: PointType.doIdo, sequence: 3);

      // Then: バリデーションにより阻止される
      expect(
        () => addScoreUseCase.execute(finishedMatch, e3, rule),
        throwsA(isA<DomainException>()),
      );
    });
  });

  group('MatchUseCase - 連続・複雑操作テスト', () {
    test('複数のイベントが連続して追加された際、sequence とスコアが正しく整合すること', () {
      // Given
      final match = TestMatchFactory.createIndividualMatch();
      final rule = TestMatchFactory.createDefaultRule();
      
      // When
      final e1 = TestMatchFactory.createEvent(side: Side.red, type: PointType.men, sequence: 1);
      final e2 = TestMatchFactory.createEvent(side: Side.white, type: PointType.kote, sequence: 2);
      final e3 = TestMatchFactory.createEvent(side: Side.red, type: PointType.doIdo, sequence: 3);

      var currentMatch = addScoreUseCase.execute(match, e1, rule);
      currentMatch = addScoreUseCase.execute(currentMatch, e2, rule);
      currentMatch = addScoreUseCase.execute(currentMatch, e3, rule);

      // Then
      expect(currentMatch.redScore, 2);
      expect(currentMatch.whiteScore, 1);
      expect(currentMatch.events.length, 3);
      expect(currentMatch.status, 'finished');
      expect(currentMatch.events.last.sequence, 3);
    });

    test('スコア追加とUndoを交互に行っても、最終的な歴史が正しく再構築されること', () {
      final match = TestMatchFactory.createIndividualMatch();
      final rule = TestMatchFactory.createDefaultRule();

      final e1 = TestMatchFactory.createEvent(side: Side.red, type: PointType.men, sequence: 1);
      final m1 = addScoreUseCase.execute(match, e1, rule);
      final m2 = undoScoreUseCase.execute(m1, rule);
      final e2 = TestMatchFactory.createEvent(side: Side.white, type: PointType.kote, sequence: 2);
      final m3 = addScoreUseCase.execute(m2, e2, rule);

      expect(m3.redScore, 0);
      expect(m3.whiteScore, 1);
      // ★ ダミーイベントは追加されなくなったため、全体の長さは2
      expect(m3.events.length, 2); 
      // ★ 1つ目のイベント（面）がキャンセルされていること
      expect(m3.events[0].isCanceled, true); 
      expect(m3.events[1].type, PointType.kote);
    });
  });
}