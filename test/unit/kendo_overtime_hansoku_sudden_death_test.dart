import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_context.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/services/kendo_overtime_evaluator.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';

void main() {
  group('[Unit] 【Unit】全剣連試合規則第34条 延長戦・反則サドンデス完全判定テスト', () {
    late KendoRuleEngine ruleEngine;
    final now = DateTime(2026, 9, 27, 10, 0, 0);

    setUp(() {
      ruleEngine = KendoRuleEngine();
    });

    test('本戦反則（△1回）が延長戦へ持ち越され、延長戦での追加反則で相手に一本が付与されてサドンデス決着すること', () {
      final match = MatchModel(
        id: 'm_encho_1',
        tournamentId: 't1',
        matchType: '延長戦',
        redName: '赤選手',
        whiteName: '白選手',
        matchTimeMinutes: 3.0,
        rule: const MatchRule(isEnchoUnlimited: true),
      );

      // 本戦中: 赤に反則1回 (0-0のまま時間切れ延長へ)
      final events = [
        ScoreEvent(
          id: 'e1',
          side: Side.red,
          isHansoku: true,
          timestamp: now.add(const Duration(minutes: 2)),
        ),
      ];

      // 本戦終了時点の分析
      var analysis = ruleEngine.analyzeHistory(events, match, match.rule);
      expect(analysis.context.redHansoku, 1);
      expect(analysis.context.whiteIppon, 0);

      // 延長戦サドンデス補正
      var overtimeCtx = KendoOvertimeEvaluator.applyOvertimeCorrectionIfNeeded(
        analysis.context,
        match.matchType,
      );
      // 0-0 なので minScore(0) + 1 = 1本先取
      expect(overtimeCtx.targetIppon, 1);

      // 延長戦突入後: 赤がさらに反則（2回目）を犯す
      events.add(
        ScoreEvent(
          id: 'e2',
          side: Side.red,
          isHansoku: true,
          timestamp: now.add(const Duration(minutes: 4)),
        ),
      );

      analysis = ruleEngine.analyzeHistory(events, match, match.rule);
      // 赤の反則累積2回 ➔ 白に一本「反」が付与される
      expect(analysis.context.redHansoku, 2);
      expect(analysis.context.whiteIppon, 1);
      expect(analysis.displays[Side.white]?.first.mark, '反');

      overtimeCtx = KendoOvertimeEvaluator.applyOvertimeCorrectionIfNeeded(
        analysis.context,
        match.matchType,
      );

      // 白の得点が targetIppon(1) に達し、白のサドンデス勝ちが成立
      final result = ruleEngine.decideResult(analysis.context, match.rule);
      expect(result, MatchResultStatus.whiteWin);
    });

    test('本戦で反則2回（相手に一本付与）後に取り返して1-1で延長突入した場合、次の反則累積計算が正しく機能すること', () {
      final match = MatchModel(
        id: 'm_encho_2',
        tournamentId: 't1',
        matchType: '延長戦',
        redName: '赤選手',
        whiteName: '白選手',
        matchTimeMinutes: 3.0,
        rule: const MatchRule(isEnchoUnlimited: true),
      );

      // 本戦中:
      // 1. 赤が反則2回 ➔ 白に一本（0-1）
      // 2. 赤が面を決める ➔ 1-1 同点
      // 本戦終了で 1-1 引き分け ➔ 延長戦へ
      final events = [
        ScoreEvent(
          id: 'e1',
          side: Side.red,
          isHansoku: true,
          timestamp: now.add(const Duration(seconds: 30)),
        ),
        ScoreEvent(
          id: 'e2',
          side: Side.red,
          isHansoku: true,
          timestamp: now.add(const Duration(seconds: 60)),
        ),
        ScoreEvent(
          id: 'e3',
          side: Side.red,
          strikeType: StrikeType.men,
          isIppon: true,
          timestamp: now.add(const Duration(seconds: 120)),
        ),
      ];

      var analysis = ruleEngine.analyzeHistory(events, match, match.rule);
      expect(analysis.context.redIppon, 1);
      expect(analysis.context.whiteIppon, 1);
      expect(analysis.context.redHansoku, 2);

      // 1-1 のため、延長戦サドンデス targetIppon は minScore(1) + 1 = 2本
      var overtimeCtx = KendoOvertimeEvaluator.applyOvertimeCorrectionIfNeeded(
        analysis.context,
        match.matchType,
      );
      expect(overtimeCtx.targetIppon, 2);

      // 延長戦突入後: 赤が反則1回（通算3回目）
      // 全剣連規則第34条: 前の2回で相手に1本入っているため、この1回では相手に点が入らない（△1個状態）
      events.add(
        ScoreEvent(
          id: 'e4',
          side: Side.red,
          isHansoku: true,
          timestamp: now.add(const Duration(minutes: 4)),
        ),
      );

      analysis = ruleEngine.analyzeHistory(events, match, match.rule);
      expect(analysis.context.redHansoku, 3);
      expect(analysis.context.whiteIppon, 1); // まだ白は1本のまま
      expect(
        ruleEngine.decideResult(analysis.context, match.rule),
        isNot(MatchResultStatus.whiteWin),
      );

      // 延長戦で赤がさらに反則（通算4回目、延長2回目）
      // 2回目の反則成立 ➔ 白に2本目「反」付与 ➔ 白の勝利（サドンデス決着）！
      events.add(
        ScoreEvent(
          id: 'e5',
          side: Side.red,
          isHansoku: true,
          timestamp: now.add(const Duration(minutes: 5)),
        ),
      );

      analysis = ruleEngine.analyzeHistory(events, match, match.rule);
      expect(analysis.context.redHansoku, 4);
      expect(analysis.context.whiteIppon, 2); // 白が2本に到達！

      final result = ruleEngine.decideResult(analysis.context, match.rule);
      expect(result, MatchResultStatus.whiteWin);
    });

    test('shouldEnterEncho が判定（Hantei）イベント存在時に延長突入を確実に抑止すること', () {
      final ctx = MatchContext(
        redIppon: 0,
        whiteIppon: 0,
        redHansoku: 0,
        whiteHansoku: 0,
        isTimeUp: true,
        targetIppon: 2,
        hasHantei: true,
      );

      final hanteiEvents = <ScoreEvent>[
        ScoreEvent(id: 'h1', side: Side.red, isHantei: true, timestamp: now),
      ];

      final shouldExtend = KendoOvertimeEvaluator.shouldEnterEncho(
        ctx: ctx,
        allowsEncho: true,
        decideResultIsDraw: (_, _, _) => true,
        events: hanteiEvents,
      );

      expect(shouldExtend, isFalse, reason: '判定決着が存在する場合は絶対に延長戦に入らないこと');
    });
  });
}
