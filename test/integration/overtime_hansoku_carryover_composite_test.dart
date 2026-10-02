import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_context.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/services/kendo_overtime_evaluator.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';

void main() {
  group('[E2E] 延長戦反則引き継ぎ即時決着複合連動テスト', () {
    late KendoRuleEngine ruleEngine;
    final baseTime = DateTime(2026, 10, 2, 14, 0, 0);

    setUp(() {
      ruleEngine = KendoRuleEngine();
    });

    test('本戦反則持ち越しから延長戦初手反則による反則一本で即時決着しモデルとルールエンジンが完全整合すること', () {
      MatchModel match = MatchModel(
        id: 'composite_match_ot_hansoku',
        tournamentId: 'tourney_composite_01',
        organizationId: 'org_composite',
        matchType: '延長戦',
        redName: '神崎 剣士',
        whiteName: '一条 剣士',
        matchTimeMinutes: 3.0,
        status: 'in_progress',
        rule: const MatchRule(isEnchoUnlimited: true),
      );

      // 本戦中盤で赤が反則1回
      final h1 = ScoreEvent(
        id: 'ev_comp_h1',
        side: Side.red,
        isHansoku: true,
        timestamp: baseTime.add(const Duration(minutes: 2)),
      );

      match = match.copyWith(events: [h1], lastUpdatedAt: h1.timestamp);

      var analysis = ruleEngine.analyzeHistory(match.events, match, match.rule);
      expect(analysis.context.redHansoku, 1);
      expect(analysis.context.whiteIppon, 0);
      expect(match.status, 'in_progress');

      // 本戦時間終了 -> 引き分けで延長戦へ
      var overtimeCtx = KendoOvertimeEvaluator.applyOvertimeCorrectionIfNeeded(
        analysis.context,
        match.matchType,
      );
      expect(overtimeCtx.targetIppon, 1); // 延長戦は一本勝負

      // 延長戦突入後、赤が再度反則（累積2回）
      final h2 = ScoreEvent(
        id: 'ev_comp_h2',
        side: Side.red,
        isHansoku: true,
        timestamp: baseTime.add(const Duration(minutes: 4)),
      );

      match = match.copyWith(
        events: [...match.events, h2],
        lastUpdatedAt: h2.timestamp,
      );

      analysis = ruleEngine.analyzeHistory(match.events, match, match.rule);
      final result = ruleEngine.decideResult(analysis.context, match.rule);

      // 判定結果の検証: 白の反則一本勝ちで即時決着
      expect(analysis.context.redHansoku, 2);
      expect(analysis.context.whiteIppon, 1);
      expect(analysis.displays[Side.white]?.first.mark, '反');
      expect(result, MatchResultStatus.whiteWin);

      // 試合状態を完了へ更新
      match = match.copyWith(status: 'completed', whiteScore: 1);

      expect(match.status, 'completed');
      expect(match.whiteScore, 1);
      expect(match.events.length, 2);
    });
  });
}
