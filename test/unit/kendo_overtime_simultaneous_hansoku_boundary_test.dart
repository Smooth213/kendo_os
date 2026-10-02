import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_context.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/services/kendo_overtime_evaluator.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';

void main() {
  group('[Unit] 延長戦における両者同時反則境界テスト', () {
    late KendoRuleEngine ruleEngine;
    final now = DateTime(2026, 10, 2, 10, 0);

    setUp(() {
      ruleEngine = KendoRuleEngine();
    });

    test('延長戦で両者が同時に反則2回目（相手に一本ずつ付与）となった場合、同点のまま勝敗決着せず延長継続となること', () {
      final overtimeMatch = MatchModel(
        id: 'ot_simultaneous_hansoku',
        matchType: '延長戦',
        redName: '選手赤',
        whiteName: '選手白',
        status: 'in_progress',
        rule: const MatchRule(isEnchoUnlimited: true),
      );

      // 本戦 1-1、双方反則1回ずつで延長突入
      // 延長戦中に双方が場外に出て同時に反則2回目となったケース
      final events = <ScoreEvent>[
        ScoreEvent(
          id: 'e1',
          side: Side.red,
          strikeType: StrikeType.men,
          isIppon: true,
          timestamp: now.add(const Duration(seconds: 30)),
        ),
        ScoreEvent(
          id: 'e2',
          side: Side.white,
          strikeType: StrikeType.kote,
          isIppon: true,
          timestamp: now.add(const Duration(seconds: 60)),
        ),
        // 本戦中の反則1回目
        ScoreEvent(
          id: 'h_r1',
          side: Side.red,
          isHansoku: true,
          timestamp: now.add(const Duration(seconds: 90)),
        ),
        ScoreEvent(
          id: 'h_w1',
          side: Side.white,
          isHansoku: true,
          timestamp: now.add(const Duration(seconds: 120)),
        ),
        // 延長戦中の反則2回目（両者同時）
        ScoreEvent(
          id: 'h_r2',
          side: Side.red,
          isHansoku: true,
          timestamp: now.add(const Duration(seconds: 200)),
        ),
        ScoreEvent(
          id: 'h_w2',
          side: Side.white,
          isHansoku: true,
          timestamp: now.add(const Duration(seconds: 200)),
        ),
      ];

      final analysis = ruleEngine.analyzeHistory(
        events,
        overtimeMatch,
        overtimeMatch.rule,
      );

      // 検証:
      // 赤の反則2回で白に一本加算(whiteIppon=2)
      // 白の反則2回で赤に一本加算(redIppon=2)
      // 結果は 2-2 の同点となり、試合は勝敗未決着（延長戦継続）
      expect(analysis.context.redIppon, 2);
      expect(analysis.context.whiteIppon, 2);

      final overtimeCtx =
          KendoOvertimeEvaluator.applyOvertimeCorrectionIfNeeded(
            analysis.context,
            overtimeMatch.matchType,
          );
      expect(
        ruleEngine.decideResult(overtimeCtx, overtimeMatch.rule),
        MatchResultStatus.inProgress,
        reason: '2-2同点のためサドンデス延長継続中',
      );
    });
  });
}
