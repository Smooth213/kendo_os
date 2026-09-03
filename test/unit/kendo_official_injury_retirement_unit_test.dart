import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_context.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';

void main() {
  group('🥋 【Phase 1-2/10】全剣連規則第33条 負傷棄権時のスコア算定＆取得本数保全境界値テスト', () {
    late KendoRuleEngine ruleEngine;
    final dummyMatch = MatchModel(
      id: 'm_injury',
      tournamentId: 't1',
      matchType: '個人戦',
      redName: '赤:佐藤',
      whiteName: '白:鈴木',
      matchTimeMinutes: 3.0,
      rule: const MatchRule(),
    );

    setUp(() {
      ruleEngine = KendoRuleEngine();
    });

    test('1. 赤が1本先取した後に負傷棄権した場合、白に必要勝利本数(2本)が付与され白勝ちとなるが、赤の「メ」は保全されること', () {
      final now = DateTime(2026, 9, 3, 10, 0, 0);

      // 三本勝負（targetIppon: 2）
      // 1. 赤が正当に面を取得（赤1 - 白0）
      // 2. 赤がアキレス腱断裂等により負傷棄権 ➔ 白の勝利に必要な2本分が付与される
      final events = [
        ScoreEvent(
          id: 'e1',
          side: Side.red,
          strikeType: StrikeType.men,
          isIppon: true,
          timestamp: now.add(const Duration(seconds: 45)),
        ),
        ScoreEvent(
          id: 'e2_ret1',
          side: Side.white,
          isFusen: true,
          isRetirement: true,
          timestamp: now.add(const Duration(seconds: 90)),
        ),
        ScoreEvent(
          id: 'e2_ret2',
          side: Side.white,
          isFusen: true,
          isRetirement: true,
          timestamp: now.add(const Duration(seconds: 91)),
        ),
      ];

      final analysis = ruleEngine.analyzeHistory(
        events,
        dummyMatch,
        const MatchRule(),
      );

      // 赤のスコアボード: 棄権前の一本「メ」が消えずに保全されていること
      final redDisplays = analysis.displays[Side.red] ?? [];
      expect(redDisplays.length, 1);
      expect(redDisplays.first.mark, 'メ');
      expect(analysis.context.redIppon, 1);

      // 白のスコアボード: 負傷棄権による不戦勝マークが2本付与されていること
      final whiteDisplays = analysis.displays[Side.white] ?? [];
      expect(whiteDisplays.length, 2);
      expect(whiteDisplays[0].mark, '◯');
      expect(whiteDisplays[1].mark, '◯');
      expect(analysis.context.whiteIppon, 2);

      // 勝敗判定: 白の勝ち (whiteWin) が確定していること
      final result = ruleEngine.decideResult(
        analysis.context,
        const MatchRule(),
      );
      expect(result, MatchResultStatus.whiteWin);
    });

    test('2. 一本勝負（代表戦等）で赤が負傷棄権した場合、白に1本のみ付与され即座に白勝ちとなること', () {
      final now = DateTime(2026, 9, 3, 10, 0, 0);
      const ipponRule = MatchRule(matchTimeMinutes: 3.0, isIpponShobu: true);

      final events = [
        ScoreEvent(
          id: 'e_single_ret',
          side: Side.white,
          isFusen: true,
          isRetirement: true,
          timestamp: now.add(const Duration(seconds: 30)),
        ),
      ];

      final analysis = ruleEngine.analyzeHistory(events, dummyMatch, ipponRule);
      expect(analysis.context.whiteIppon, 1);
      final result = ruleEngine.decideResult(analysis.context, ipponRule);
      expect(result, MatchResultStatus.whiteWin);
    });
  });
}
