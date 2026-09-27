import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_context.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/services/kendo_overtime_evaluator.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';

void main() {
  group('🥋 【Unit】相互同時反則・2-2サドンデス突入＆合議Undo完全復元テスト', () {
    late KendoRuleEngine ruleEngine;
    final now = DateTime(2026, 9, 27, 10, 0, 0);

    setUp(() {
      ruleEngine = KendoRuleEngine();
    });

    test('1. 相一本(1-1)＋双方反則1回からの相互同時反則発生で2-2同点サドンデス突入判定', () {
      final match = MatchModel(
        id: 'm_simultaneous_hansoku_1',
        tournamentId: 't1',
        matchType: '延長戦',
        redName: '赤選手',
        whiteName: '白選手',
        matchTimeMinutes: 3.0,
        rule: const MatchRule(isEnchoUnlimited: true),
      );

      // 初期状態: 赤面(1-0)、白小手(1-1)、赤反則1回(△)、白反則1回(△)
      final events = <ScoreEvent>[
        ScoreEvent(
          id: 'e_red_men',
          side: Side.red,
          strikeType: StrikeType.men,
          isIppon: true,
          timestamp: now.add(const Duration(seconds: 30)),
        ),
        ScoreEvent(
          id: 'e_white_kote',
          side: Side.white,
          strikeType: StrikeType.kote,
          isIppon: true,
          timestamp: now.add(const Duration(seconds: 60)),
        ),
        ScoreEvent(
          id: 'e_red_h1',
          side: Side.red,
          isHansoku: true,
          timestamp: now.add(const Duration(seconds: 90)),
        ),
        ScoreEvent(
          id: 'e_white_h1',
          side: Side.white,
          isHansoku: true,
          timestamp: now.add(const Duration(seconds: 120)),
        ),
      ];

      var analysis = ruleEngine.analyzeHistory(events, match, match.rule);
      expect(analysis.context.redIppon, 1);
      expect(analysis.context.whiteIppon, 1);
      expect(analysis.context.redHansoku, 1);
      expect(analysis.context.whiteHansoku, 1);

      // ここで相互同時反則が発生:
      // 赤に2回目の反則 ➔ 白に一本「反」付与
      final redH2 = ScoreEvent(
        id: 'e_red_h2',
        side: Side.red,
        isHansoku: true,
        timestamp: now.add(const Duration(seconds: 150)),
      );
      // 白に2回目の反則 ➔ 赤に一本「反」付与
      final whiteH2 = ScoreEvent(
        id: 'e_white_h2',
        side: Side.white,
        isHansoku: true,
        timestamp: now.add(const Duration(seconds: 150)),
      );

      events.add(redH2);
      events.add(whiteH2);

      analysis = ruleEngine.analyzeHistory(events, match, match.rule);
      // 双方に「反」が1本ずつ付与され 2 - 2 同点！
      expect(analysis.context.redIppon, 2);
      expect(analysis.context.whiteIppon, 2);
      expect(analysis.context.redHansoku, 2);
      expect(analysis.context.whiteHansoku, 2);

      // 表示マークに「反」が含まれていること
      expect(analysis.displays[Side.red]?.any((d) => d.mark == '反'), isTrue);
      expect(analysis.displays[Side.white]?.any((d) => d.mark == '反'), isTrue);

      // 延長戦サドンデス補正: 2-2 なので targetIppon は minScore(2) + 1 = 3本
      final overtimeCtx =
          KendoOvertimeEvaluator.applyOvertimeCorrectionIfNeeded(
            analysis.context,
            match.matchType,
          );
      expect(overtimeCtx.targetIppon, 3);
      expect(
        ruleEngine.decideResult(overtimeCtx, match.rule),
        MatchResultStatus.inProgress,
        reason: '2-2同点のためサドンデス継続中',
      );
    });

    test('2. 相互同時反則直後の合議Undoによる反則相殺・スコア完全ロールバック検証', () {
      final match = MatchModel(
        id: 'm_simultaneous_hansoku_undo',
        tournamentId: 't1',
        matchType: '延長戦',
        redName: '赤選手',
        whiteName: '白選手',
        matchTimeMinutes: 3.0,
        rule: const MatchRule(isEnchoUnlimited: true),
      );

      final redMen = ScoreEvent(
        id: 'ev_men',
        side: Side.red,
        strikeType: StrikeType.men,
        isIppon: true,
        timestamp: now.add(const Duration(seconds: 30)),
      );
      final whiteKote = ScoreEvent(
        id: 'ev_kote',
        side: Side.white,
        strikeType: StrikeType.kote,
        isIppon: true,
        timestamp: now.add(const Duration(seconds: 60)),
      );
      final redH1 = ScoreEvent(
        id: 'ev_rh1',
        side: Side.red,
        isHansoku: true,
        timestamp: now.add(const Duration(seconds: 90)),
      );
      final whiteH1 = ScoreEvent(
        id: 'ev_wh1',
        side: Side.white,
        isHansoku: true,
        timestamp: now.add(const Duration(seconds: 120)),
      );
      final redH2 = ScoreEvent(
        id: 'ev_rh2',
        side: Side.red,
        isHansoku: true,
        timestamp: now.add(const Duration(seconds: 150)),
      );
      final whiteH2 = ScoreEvent(
        id: 'ev_wh2',
        side: Side.white,
        isHansoku: true,
        timestamp: now.add(const Duration(seconds: 150)),
      );

      final events = <ScoreEvent>[
        redMen,
        whiteKote,
        redH1,
        whiteH1,
        redH2,
        whiteH2,
      ];

      var analysis = ruleEngine.analyzeHistory(events, match, match.rule);
      expect(analysis.context.redIppon, 2);
      expect(analysis.context.whiteIppon, 2);

      // ── 審判合議: 白の2回目反則を取り消し（Undo） ──
      final undoWhiteH2 = ScoreEvent(
        id: 'undo_wh2',
        side: Side.white,
        targetId: 'ev_wh2',
        isUndo: true,
        timestamp: now.add(const Duration(seconds: 160)),
      );
      events.add(undoWhiteH2);

      analysis = ruleEngine.analyzeHistory(events, match, match.rule);
      // 白の2回目反則が取り消されたため、赤の「反」がなくなり赤1本に戻る。白は2本のまま
      expect(analysis.context.redIppon, 1);
      expect(analysis.context.whiteIppon, 2);
      expect(analysis.context.whiteHansoku, 1);

      // ── 審判合議: 赤の2回目反則も取り消し（Undo） ──
      final undoRedH2 = ScoreEvent(
        id: 'undo_rh2',
        side: Side.red,
        targetId: 'ev_rh2',
        isUndo: true,
        timestamp: now.add(const Duration(seconds: 170)),
      );
      events.add(undoRedH2);

      analysis = ruleEngine.analyzeHistory(events, match, match.rule);
      // 双方の同時反則が完全に取り消され、元の相一本(1-1)＆反則各1回に完全復元！
      expect(analysis.context.redIppon, 1);
      expect(analysis.context.whiteIppon, 1);
      expect(analysis.context.redHansoku, 1);
      expect(analysis.context.whiteHansoku, 1);
      // 表示マークから双方の「反」が消滅していること
      expect(analysis.displays[Side.red]?.any((d) => d.mark == '反'), isFalse);
      expect(analysis.displays[Side.white]?.any((d) => d.mark == '反'), isFalse);
      // △が双方に1つずつ存在すること
      expect(analysis.displays[Side.red]?.any((d) => d.mark == '△'), isTrue);
      expect(analysis.displays[Side.white]?.any((d) => d.mark == '△'), isTrue);
    });
  });
}
