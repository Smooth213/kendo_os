import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/domain/entities/score_event.dart';
import 'package:kendo_os/domain/entities/match_model.dart';
import 'package:kendo_os/domain/rules/match_rule.dart';
import 'package:kendo_os/application/usecases/match_usecases.dart';
import '../../../helpers/event_factory.dart';

void main() {
  group('MatchUseCase - イベント駆動版テスト', () {
    late KendoRuleEngine engine;
    late AddScoreUseCase addScoreUseCase;
    late UndoScoreUseCase undoScoreUseCase;
    late RebuildMatchFromEventsUseCase rebuildUseCase;
    late MatchModel dummyMatch;

    setUp(() {
      engine = KendoRuleEngine();
      addScoreUseCase = AddScoreUseCase(engine);
      undoScoreUseCase = UndoScoreUseCase(engine);
      rebuildUseCase = RebuildMatchFromEventsUseCase(engine);
      dummyMatch = MatchModel( // ★ constを外し、コンパイラクラッシュを回避
        id: 'test_m1', tournamentId: 't1', matchOrder: 1,
        redName: 'Red', whiteName: 'White',
        status: 'in_progress', matchType: '個人戦'
      );
    });

    test('ポイント追加によって MatchModel のスコアとイベント履歴が更新されること', () {
      // Arrange
      final initialMatch = dummyMatch.copyWith(events: <ScoreEvent>[]);
      final event = men(Side.red);
      final rule = MatchRule();

      // Act
      final updatedMatch = addScoreUseCase.execute(initialMatch, event, rule);

      // Assert
      expect(updatedMatch.events.length, 1);
      expect(updatedMatch.redScore, 1);
      expect(updatedMatch.isDirty, true);
    });

    test('Undoによって最新のイベントがキャンセル扱いになり、スコアが戻ること', () {
      // Arrange
      final matchWithScore = dummyMatch.copyWith(
        events: [men(Side.red)],
        redScore: 1,
      );
      final rule = MatchRule();

      // Act
      final undoneMatch = undoScoreUseCase.execute(matchWithScore, rule);

      // Assert
      expect(undoneMatch.events.last.isCanceled, true); // 最新イベントがキャンセルされる
      expect(undoneMatch.redScore, 0); // スコアが 0 に戻る
    });

    test('イベント履歴からの再構築 UseCase が正しく機能すること', () {
      // Arrange: 手動でイベントだけを詰め込んだ「不整合な」モデルを用意
      final baseMatch = dummyMatch.copyWith(
        events: [men(Side.red), kote(Side.white)],
        redScore: 0, // スコアがまだ計算されていない状態
        whiteScore: 0,
      );
      final rule = MatchRule();

      // Act
      final rebuiltMatch = rebuildUseCase.execute(baseMatch, rule);

      // Assert
      expect(rebuiltMatch.redScore, 1);
      expect(rebuiltMatch.whiteScore, 1);
      expect(rebuiltMatch.status, 'in_progress');
    });
  });
}