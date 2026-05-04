import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/domain/entities/match_model.dart';
import 'package:kendo_os/domain/entities/score_event.dart';
import 'package:kendo_os/domain/rules/match_rule.dart';
import 'package:kendo_os/domain/services/kendo_rule_engine.dart'; 
import '../../../helpers/event_factory.dart';

void main() {
  group('KendoRuleEngine - Event Driven Score Tests', () {
    late KendoRuleEngine engine;
    late MatchModel dummyMatch;
    late MatchRule dummyRule;

    setUp(() {
      engine = KendoRuleEngine();
      dummyMatch = MatchModel( // ★ constを外し、コンパイラクラッシュを回避
        id: 'test', tournamentId: 't1', matchOrder: 1,
        redName: 'Red', whiteName: 'White',
        status: 'in_progress', matchType: '個人戦',
        remainingSeconds: 180,
      );
      dummyRule = MatchRule(); // デフォルト設定
    });

    test('赤が面を打った時、赤のスコアが1本になること', () {
      final events = [men(Side.red)];
      final analysis = engine.analyzeHistory(events, dummyMatch, dummyRule);

      expect(analysis.context.redIppon, 1);
      expect(analysis.context.whiteIppon, 0);
    });

    test('反則2回で、相手に1本入ること', () {
      final events = [hansoku(Side.red), hansoku(Side.red)];
      final analysis = engine.analyzeHistory(events, dummyMatch, dummyRule);

      expect(analysis.context.redIppon, 0);
      expect(analysis.context.whiteIppon, 1);
      expect(analysis.context.redHansoku, 2);
    });
  });
}