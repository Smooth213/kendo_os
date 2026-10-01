import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_context.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/services/kendo_overtime_evaluator.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/match/domain/services/team_match_calculator.dart';

void main() {
  group('[Unit] 【Unit】団体戦 極限境界・両者同時棄権・相討ち反則失格フォールバック判定テスト', () {
    late KendoRuleEngine ruleEngine;
    final now = DateTime(2026, 9, 27, 10, 0, 0);

    setUp(() {
      ruleEngine = KendoRuleEngine();
    });

    MatchModel createFinishedMatch({
      required String id,
      required int redScore,
      required int whiteScore,
      String matchType = '団体戦',
      int? matchOrder,
      List<ScoreEvent> events = const [],
    }) {
      return MatchModel(
        id: id,
        matchType: matchType,
        matchOrder: matchOrder,
        redName: '赤選手',
        whiteName: '白選手',
        redScore: redScore,
        whiteScore: whiteScore,
        status: 'finished',
        events: events,
      );
    }

    test('5人制団体戦: 先鋒〜副将まで同点・同本数の大将戦で両者同時負傷棄権（不戦）となった場合の決着判定こと', () {
      // 先鋒〜副将: 4戦すべて 0-0 引き分け
      final matches = List.generate(
        4,
        (i) => createFinishedMatch(
          id: 'm_5_${i + 1}',
          matchOrder: i + 1,
          redScore: 0,
          whiteScore: 0,
        ),
      );

      // 大将戦: 双方が同時に負傷棄権（両者不戦・不戦敗相当で 0-0 のまま終了）
      final taishoEvents = <ScoreEvent>[
        ScoreEvent(
          id: 'e_ret_red',
          side: Side.red,
          isFusen: true,
          isRetirement: true,
          timestamp: now.add(const Duration(minutes: 1)),
        ),
        ScoreEvent(
          id: 'e_ret_white',
          side: Side.white,
          isFusen: true,
          isRetirement: true,
          timestamp: now.add(const Duration(minutes: 1, seconds: 1)),
        ),
      ];

      final taishoMatch = MatchModel(
        id: 'm_5_5',
        matchOrder: 5,
        matchType: '団体戦',
        redName: '赤大将',
        whiteName: '白大将',
        status: 'finished',
        events: taishoEvents,
      );

      // RuleEngine での解析がクラッシュせず安全に実行できること
      final analysis = ruleEngine.analyzeHistory(
        taishoEvents,
        taishoMatch,
        const MatchRule(),
      );
      // 両者1本ずつ（双方の棄権により相手に1本ずつ付与され 1-1）
      expect(analysis.context.redIppon, 1);
      expect(analysis.context.whiteIppon, 1);

      // 大将戦スコア反映: 1-1 引き分け
      final finishedTaisho = taishoMatch.copyWith(redScore: 1, whiteScore: 1);
      final allFiveMatches = [...matches, finishedTaisho];

      final teamResult = TeamMatchCalculator.calculate(allFiveMatches);
      expect(teamResult.allFinished, isTrue);
      expect(teamResult.redWins, 0);
      expect(teamResult.whiteWins, 0);
      expect(teamResult.redPoints, 1);
      expect(teamResult.whitePoints, 1);
      expect(teamResult.isTie, isTrue, reason: '勝者数(0=0)・総本数(1=1)で完全同点・代表戦が必要');
      expect(teamResult.teamWinner, 'draw');
    });

    test('7人制団体戦: 先鋒〜副将まで同点・同本数の大将戦で両者反則4回（相反則失格）時の安全フォールバックこと', () {
      // 先鋒〜副将: 6戦すべて 1勝1敗4分（各チーム勝者1、総本数2で完全同点）
      final matches = [
        createFinishedMatch(
          id: 'm_7_1',
          matchOrder: 1,
          redScore: 2,
          whiteScore: 0,
        ),
        createFinishedMatch(
          id: 'm_7_2',
          matchOrder: 2,
          redScore: 0,
          whiteScore: 2,
        ),
        createFinishedMatch(
          id: 'm_7_3',
          matchOrder: 3,
          redScore: 0,
          whiteScore: 0,
        ),
        createFinishedMatch(
          id: 'm_7_4',
          matchOrder: 4,
          redScore: 0,
          whiteScore: 0,
        ),
        createFinishedMatch(
          id: 'm_7_5',
          matchOrder: 5,
          redScore: 0,
          whiteScore: 0,
        ),
        createFinishedMatch(
          id: 'm_7_6',
          matchOrder: 6,
          redScore: 0,
          whiteScore: 0,
        ),
      ];

      // 大将戦: 激しい競り合いで両者に反則が4回ずつ宣告（相打ち反則）
      // 赤2回 -> 白に1本, 白2回 -> 赤に1本, 赤4回 -> 白に2本目, 白4回 -> 赤に2本目
      final events = <ScoreEvent>[];
      for (int i = 1; i <= 4; i++) {
        events.add(
          ScoreEvent(
            id: 'r_h_$i',
            side: Side.red,
            isHansoku: true,
            timestamp: now.add(Duration(seconds: i * 30)),
          ),
        );
        events.add(
          ScoreEvent(
            id: 'w_h_$i',
            side: Side.white,
            isHansoku: true,
            timestamp: now.add(Duration(seconds: i * 30 + 1)),
          ),
        );
      }

      final taishoMatch = MatchModel(
        id: 'm_7_7',
        matchOrder: 7,
        matchType: '団体戦',
        redName: '赤大将',
        whiteName: '白大将',
        status: 'finished',
        events: events,
      );

      final analysis = ruleEngine.analyzeHistory(
        events,
        taishoMatch,
        const MatchRule(),
      );

      // 両者の反則が4回ずつ累積し、相手に2本ずつ付与され 2-2
      expect(analysis.context.redHansoku, 4);
      expect(analysis.context.whiteHansoku, 4);
      expect(analysis.context.redIppon, 2);
      expect(analysis.context.whiteIppon, 2);

      // 大将戦 2-2 引き分けで終了
      final finishedTaisho = taishoMatch.copyWith(redScore: 2, whiteScore: 2);
      final allSevenMatches = [...matches, finishedTaisho];

      final teamResult = TeamMatchCalculator.calculate(allSevenMatches);
      expect(teamResult.allFinished, isTrue);
      expect(teamResult.redWins, 1);
      expect(teamResult.whiteWins, 1);
      expect(teamResult.redPoints, 4);
      expect(teamResult.whitePoints, 4);
      expect(teamResult.isTie, isTrue, reason: '大将戦相討ち反則2-2引き分けにより代表戦へ');
      expect(teamResult.teamWinner, 'draw');
    });

    test('代表戦（延長サドンデス）: 両者に同時に反則2回目が宣告された場合のサドンデス再補正・継続挙動こと', () {
      final daihyoMatch = MatchModel(
        id: 'm_daihyo_double_hansoku',
        tournamentId: 't1',
        matchType: '代表戦',
        redName: '赤代表',
        whiteName: '白代表',
        matchTimeMinutes: 3.0,
        rule: const MatchRule(isEnchoUnlimited: true),
      );

      // 1. 赤・白に反則1回ずつ（0-0, △1ずつ）
      final events = [
        ScoreEvent(
          id: 'dh_r1',
          side: Side.red,
          isHansoku: true,
          timestamp: now.add(const Duration(minutes: 1)),
        ),
        ScoreEvent(
          id: 'dh_w1',
          side: Side.white,
          isHansoku: true,
          timestamp: now.add(const Duration(minutes: 1, seconds: 5)),
        ),
      ];

      var analysis = ruleEngine.analyzeHistory(
        events,
        daihyoMatch,
        daihyoMatch.rule,
      );
      var overtimeCtx = KendoOvertimeEvaluator.applyOvertimeCorrectionIfNeeded(
        analysis.context,
        daihyoMatch.matchType,
      );
      // 0-0 なのでサドンデス targetIppon は 1
      expect(overtimeCtx.targetIppon, 1);

      // 2. 両者がもみ合いとなり、ほぼ同時に反則2回目が宣告された
      events.add(
        ScoreEvent(
          id: 'dh_r2',
          side: Side.red,
          isHansoku: true,
          timestamp: now.add(const Duration(minutes: 2)),
        ),
      );
      events.add(
        ScoreEvent(
          id: 'dh_w2',
          side: Side.white,
          isHansoku: true,
          timestamp: now.add(const Duration(minutes: 2, seconds: 1)),
        ),
      );

      analysis = ruleEngine.analyzeHistory(
        events,
        daihyoMatch,
        daihyoMatch.rule,
      );
      // 双方に反則2回目が入ったため、白・赤双方に1本ずつ付与され 1-1
      expect(analysis.context.redHansoku, 2);
      expect(analysis.context.whiteHansoku, 2);
      expect(analysis.context.redIppon, 1);
      expect(analysis.context.whiteIppon, 1);

      // 延長戦サドンデス補正: 1-1 となったため、minScore(1) + 1 = 2本が新ターゲットとなる
      overtimeCtx = KendoOvertimeEvaluator.applyOvertimeCorrectionIfNeeded(
        analysis.context,
        daihyoMatch.matchType,
      );
      expect(overtimeCtx.targetIppon, 2);

      // 3. 次に赤が面を決めた場合、2本目に到達してサドンデス勝利が確定
      events.add(
        ScoreEvent(
          id: 'dh_r_men',
          side: Side.red,
          strikeType: StrikeType.men,
          isIppon: true,
          timestamp: now.add(const Duration(minutes: 3)),
        ),
      );

      analysis = ruleEngine.analyzeHistory(
        events,
        daihyoMatch,
        daihyoMatch.rule,
      );
      expect(analysis.context.redIppon, 2);
      expect(analysis.context.whiteIppon, 1);

      final result = ruleEngine.decideResult(
        analysis.context,
        daihyoMatch.rule,
      );
      expect(result, MatchResultStatus.redWin);
    });
  });
}
