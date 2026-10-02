import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_context.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/services/kendo_overtime_evaluator.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';

void main() {
  group('[Unit] 延長戦反則引き継ぎルールドメイン検証テスト', () {
    late KendoRuleEngine ruleEngine;
    final baseTime = DateTime(2026, 10, 2, 10, 0, 0);

    setUp(() {
      ruleEngine = KendoRuleEngine();
    });

    test('本戦で反則1回を受け延長戦へ突入後に初手反則で累積2回となり相手反則一本で即時一本勝ちが決着すること', () {
      final match = MatchModel(
        id: 'match_overtime_hansoku_01',
        tournamentId: 'tourney_01',
        matchType: '延長戦',
        redName: '赤選手',
        whiteName: '白選手',
        matchTimeMinutes: 3.0,
        rule: const MatchRule(isEnchoUnlimited: true),
      );

      final events = <ScoreEvent>[
        ScoreEvent(
          id: 'ev_main_red_hansoku_1',
          side: Side.red,
          isHansoku: true,
          timestamp: baseTime.add(const Duration(minutes: 2)),
        ),
      ];

      // 本戦終了時点（0-0、赤反則1回）
      var analysis = ruleEngine.analyzeHistory(events, match, match.rule);
      expect(analysis.context.redHansoku, 1);
      expect(analysis.context.whiteIppon, 0);

      var overtimeCtx = KendoOvertimeEvaluator.applyOvertimeCorrectionIfNeeded(
        analysis.context,
        match.matchType,
      );
      expect(overtimeCtx.targetIppon, 1);

      // 延長戦突入後に赤が初手で反則を犯す（累積2回目）
      events.add(
        ScoreEvent(
          id: 'ev_ot_red_hansoku_2',
          side: Side.red,
          isHansoku: true,
          timestamp: baseTime.add(const Duration(minutes: 4)),
        ),
      );

      analysis = ruleEngine.analyzeHistory(events, match, match.rule);
      expect(analysis.context.redHansoku, 2);
      expect(analysis.context.whiteIppon, 1);
      expect(analysis.displays[Side.white]?.first.mark, '反');

      overtimeCtx = KendoOvertimeEvaluator.applyOvertimeCorrectionIfNeeded(
        analysis.context,
        match.matchType,
      );

      final result = ruleEngine.decideResult(analysis.context, match.rule);
      expect(result, MatchResultStatus.whiteWin);
    });

    test('本戦で両者反則1回ずつ持ち越し延長戦で白が先に反則を犯した場合に赤の反則一本勝ちとなること', () {
      final match = MatchModel(
        id: 'match_overtime_hansoku_02',
        tournamentId: 'tourney_01',
        matchType: '延長戦',
        redName: '赤選手',
        whiteName: '白選手',
        matchTimeMinutes: 3.0,
        rule: const MatchRule(isEnchoUnlimited: true),
      );

      final events = <ScoreEvent>[
        ScoreEvent(
          id: 'ev_red_h1',
          side: Side.red,
          isHansoku: true,
          timestamp: baseTime.add(const Duration(minutes: 1)),
        ),
        ScoreEvent(
          id: 'ev_white_h1',
          side: Side.white,
          isHansoku: true,
          timestamp: baseTime.add(const Duration(minutes: 2)),
        ),
      ];

      var analysis = ruleEngine.analyzeHistory(events, match, match.rule);
      expect(analysis.context.redHansoku, 1);
      expect(analysis.context.whiteHansoku, 1);

      // 延長戦で白が反則
      events.add(
        ScoreEvent(
          id: 'ev_white_h2',
          side: Side.white,
          isHansoku: true,
          timestamp: baseTime.add(const Duration(minutes: 4)),
        ),
      );

      analysis = ruleEngine.analyzeHistory(events, match, match.rule);
      expect(analysis.context.whiteHansoku, 2);
      expect(analysis.context.redIppon, 1);
      expect(analysis.displays[Side.red]?.any((d) => d.mark == '反'), isTrue);

      final result = ruleEngine.decideResult(analysis.context, match.rule);
      expect(result, MatchResultStatus.redWin);
    });
  });
}
