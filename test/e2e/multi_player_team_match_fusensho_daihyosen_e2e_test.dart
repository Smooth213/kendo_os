import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_context.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/services/kendo_overtime_evaluator.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/match/domain/services/team_match_calculator.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/setup_match_format/match_format_setup_helper.dart';

void main() {
  group('🥋 【E2E】8人制団体戦 不戦勝（各2本）混在・4-4/8-8同点 ➔ 代表戦サドンデス完全決着E2Eテスト', () {
    late KendoRuleEngine ruleEngine;
    final now = DateTime(2026, 9, 27, 10, 0);

    setUp(() {
      ruleEngine = KendoRuleEngine();
    });

    test('8人制団体戦: 四将・六将不戦勝を含む4勝4敗・8本対8本同点から、代表戦自動トリガー＆サドンデス決着', () {
      // 8人制ポジション: ['先鋒', '次鋒', '六将', '五将', '四将', '三将', '副将', '大将']
      final positions = MatchFormatSetupHelper.generatePositions(8);
      expect(positions, ['先鋒', '次鋒', '六将', '五将', '四将', '三将', '副将', '大将']);

      final matches = <MatchModel>[];

      // スコア配分設計 (4-4 / 8-8 同点):
      // 0. 先鋒: 赤2本勝ち (2-0) [赤1勝, 赤2本]
      // 1. 次鋒: 白2本勝ち (0-2) [白1勝, 白2本]
      // 2. 六将: 赤不戦勝 (2-0) [赤2勝, 赤4本]
      // 3. 五将: 白2本勝ち (0-2) [白2勝, 白4本]
      // 4. 四将: 白不戦勝 (0-2) [白3勝, 白6本]
      // 5. 三将: 赤2本勝ち (2-0) [赤3勝, 赤6本]
      // 6. 副将: 赤2本勝ち (2-0) [赤4勝, 赤8本]
      // 7. 大将: 白2本勝ち (0-2) [白4勝, 白8本]
      // 合計: 勝者数 赤4 - 白4, 取得本数 赤8 - 白8 ➔ 完全同点！

      final matchScores = [
        (rScore: 2, wScore: 0, isFusenRed: false, isFusenWhite: false), // 先鋒
        (rScore: 0, wScore: 2, isFusenRed: false, isFusenWhite: false), // 次鋒
        (
          rScore: 2,
          wScore: 0,
          isFusenRed: true,
          isFusenWhite: false,
        ), // 六将 (赤不戦勝)
        (rScore: 0, wScore: 2, isFusenRed: false, isFusenWhite: false), // 五将
        (
          rScore: 0,
          wScore: 2,
          isFusenRed: false,
          isFusenWhite: true,
        ), // 四将 (白不戦勝)
        (rScore: 2, wScore: 0, isFusenRed: false, isFusenWhite: false), // 三将
        (rScore: 2, wScore: 0, isFusenRed: false, isFusenWhite: false), // 副将
        (rScore: 0, wScore: 2, isFusenRed: false, isFusenWhite: false), // 大将
      ];

      for (int i = 0; i < 8; i++) {
        final config = matchScores[i];
        final events = <ScoreEvent>[];

        if (config.isFusenRed) {
          // 不戦勝: 規定により2本付与
          events.add(
            ScoreEvent(
              id: 'fusen_r1',
              side: Side.red,
              isFusen: true,
              isIppon: true,
              timestamp: now,
            ),
          );
          events.add(
            ScoreEvent(
              id: 'fusen_r2',
              side: Side.red,
              isFusen: true,
              isIppon: true,
              timestamp: now,
            ),
          );
        } else if (config.isFusenWhite) {
          events.add(
            ScoreEvent(
              id: 'fusen_w1',
              side: Side.white,
              isFusen: true,
              isIppon: true,
              timestamp: now,
            ),
          );
          events.add(
            ScoreEvent(
              id: 'fusen_w2',
              side: Side.white,
              isFusen: true,
              isIppon: true,
              timestamp: now,
            ),
          );
        }

        matches.add(
          MatchModel(
            id: 'bout_$i',
            tournamentId: 'tour_8_fusen',
            groupName: '赤心館 vs 養正館',
            matchType: positions[i],
            order: (i + 1).toDouble(),
            redName: '赤心館: 選手$i',
            whiteName: '養正館: 選手$i',
            redScore: config.rScore,
            whiteScore: config.wScore,
            events: events,
            status: 'finished',
          ),
        );
      }

      // 1. チーム勝敗集計
      final result = TeamMatchCalculator.calculate(matches);
      expect(result.allFinished, isTrue);
      expect(result.redWins, 4);
      expect(result.whiteWins, 4);
      expect(result.redPoints, 8);
      expect(result.whitePoints, 8);
      expect(result.isTie, isTrue);
      expect(result.teamWinner, 'draw');

      // 2. KendoOvertimeEvaluator によるグループ状況解析
      final groupStatus = KendoOvertimeEvaluator.analyzeTeamMatchStatus(
        matches,
      );
      expect(groupStatus.isAllDone, isTrue);
      expect(groupStatus.isTie, isTrue, reason: '4-4 / 8-8 同点のため代表戦トリガー要件が成立');

      // 3. 代表戦（任意指名）の生成と突入
      final daihyoMatch = MatchModel(
        id: 'bout_daihyo',
        tournamentId: 'tour_8_fusen',
        groupName: '赤心館 vs 養正館',
        matchType: '代表戦',
        order: 9.0,
        redName: '赤心館: 大将選手 (任意指名)',
        whiteName: '養正館: 副将選手 (任意指名)',
        status: 'finished',
        matchTimeMinutes: 3.0,
        rule: const MatchRule(
          isDaihyoIpponShobu: true,
          daihyoHasExtension: true,
          daihyoEnchoCount: -2, // 無制限
        ),
        events: [
          // 赤が延長サドンデスで鋭い面を決める
          ScoreEvent(
            id: 'e_daihyo_men',
            side: Side.red,
            strikeType: StrikeType.men,
            isIppon: true,
            timestamp: now.add(const Duration(minutes: 4)),
          ),
        ],
        redScore: 1,
        whiteScore: 0,
      );

      // 代表戦のサドンデス判定
      final daihyoAnalysis = ruleEngine.analyzeHistory(
        daihyoMatch.events,
        daihyoMatch,
        daihyoMatch.rule,
      );
      final daihyoCtx = KendoOvertimeEvaluator.applyOvertimeCorrectionIfNeeded(
        daihyoAnalysis.context,
        daihyoMatch.matchType,
      );

      expect(daihyoCtx.targetIppon, 1, reason: '代表戦は1本先取サドンデス');
      expect(daihyoCtx.redIppon, 1);
      final matchStatus = ruleEngine.decideResult(daihyoCtx, daihyoMatch.rule);
      expect(matchStatus, MatchResultStatus.redWin);

      // 4. 代表戦を含めたチーム全体再集計
      final finalMatches = [...matches, daihyoMatch];
      final finalResult = TeamMatchCalculator.calculate(finalMatches);
      expect(finalResult.hasDaihyo, isTrue);
      expect(finalResult.isTie, isFalse);
      expect(finalResult.teamWinner, 'red', reason: '代表戦勝利により赤心館の勝利確定！');
    });
  });
}
