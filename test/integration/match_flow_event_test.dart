import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/application/usecases/match_usecases.dart';
import 'package:kendo_os/domain/entities/match_model.dart';
import 'package:kendo_os/domain/rules/match_rule.dart';
import 'package:kendo_os/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/domain/entities/score_event.dart';
import '../helpers/event_factory.dart';

void main() {
  group('Event Driven Match Flow Integration', () {
    late KendoRuleEngine engine;
    late AddScoreUseCase addScoreUsecase;
    late UndoScoreUseCase undoUsecase;

    setUp(() {
      engine = KendoRuleEngine();
      addScoreUsecase = AddScoreUseCase(engine);
      undoUsecase = UndoScoreUseCase(engine);
    });

    test('赤が2本先取して試合が終了するまでのフロー', () {
      var match = MatchModel( // ★ constを外し、コンパイラクラッシュを回避
        id: 'test', tournamentId: 't1', matchOrder: 1,
        redName: 'Red', whiteName: 'White',
        status: 'in_progress', matchType: '個人戦'
      );
      final rule = MatchRule();

      // 赤が面を打つ
      match = addScoreUsecase.execute(match, men(Side.red), rule);
      expect(match.redScore, 1);

      // 白が小手を打つ
      match = addScoreUsecase.execute(match, kote(Side.white), rule);
      expect(match.redScore, 1);
      expect(match.whiteScore, 1);

      // 白の小手を取り消す(Undo)
      match = undoUsecase.execute(match, rule);
      expect(match.events.length, 2); // Undoの仕様上、要素は増えずに対象イベントの isCanceled が true になる
      expect(match.events.last.isCanceled, true);
      expect(match.whiteScore, 0);

      // 赤が胴を打って決着
      match = addScoreUsecase.execute(match, dou(Side.red), rule);
      expect(match.redScore, 2);
      
      // ステータスが終了になること
      expect(match.status, 'finished');
    });
  });
}