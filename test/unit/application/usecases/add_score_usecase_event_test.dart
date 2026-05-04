import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/application/usecases/match_usecases.dart';
import 'package:kendo_os/domain/entities/match_model.dart';
import 'package:kendo_os/domain/rules/match_rule.dart';
import 'package:kendo_os/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/domain/entities/score_event.dart';
import '../../../helpers/event_factory.dart';

void main() {
  group('AddScoreUseCase - Event Driven Update', () {
    late KendoRuleEngine engine;
    late AddScoreUseCase usecase;

    setUp(() {
      engine = KendoRuleEngine();
      usecase = AddScoreUseCase(engine);
    });

    test('イベントを追加するとMatchModelのeventsとscoreが更新されること', () {
      final initialMatch = MatchModel( // ★ constを外し、コンパイラクラッシュを回避
        id: 'test', tournamentId: 't1', matchOrder: 1,
        redName: 'Red', whiteName: 'White',
        status: 'in_progress', matchType: '個人戦',
        remainingSeconds: 180,
      );
      final newEvent = men(Side.red);
      final rule = MatchRule();

      final updatedMatch = usecase.execute(initialMatch, newEvent, rule);

      expect(updatedMatch.events.length, 1);
      expect(updatedMatch.events.first.strikeType, StrikeType.men);
      expect(updatedMatch.redScore, 1);
    });
  });
}