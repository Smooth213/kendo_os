import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_context.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';

void main() {
  group('🥋 【Phase 1-1/10】全剣連規則第34条 反則4回相手二本勝ち・即座試合終了境界値テスト', () {
    late KendoRuleEngine ruleEngine;
    final dummyMatch = MatchModel(
      id: 'm1',
      tournamentId: 't1',
      matchType: '個人戦',
      redName: '選手A',
      whiteName: '選手B',
      matchTimeMinutes: 3.0,
      rule: const MatchRule(),
    );

    setUp(() {
      ruleEngine = KendoRuleEngine();
    });

    test('1. 反則1回目・2回目（相手に1本目加点）・3回目・4回目（相手に2本目加点）の判定境界', () {
      // 1回目反則
      expect(ruleEngine.isHansokuIppon(1), isFalse);

      // 2回目反則 ➔ 一本成立！
      expect(ruleEngine.isHansokuIppon(2), isTrue);

      // 3回目反則
      expect(ruleEngine.isHansokuIppon(3), isFalse);

      // 4回目反則 ➔ 二本目成立！（相手の二本勝ち確定）
      expect(ruleEngine.isHansokuIppon(4), isTrue);
    });

    test('2. 赤の反則4回連続発生による白の「反」「反」二本勝ちと即座試合終了の検証', () {
      final now = DateTime(2026, 9, 3, 10, 0, 0);

      // 赤に反則を4回連続で付与
      final events = [
        ScoreEvent(
          id: 'h1',
          side: Side.red,
          isHansoku: true,
          timestamp: now.add(const Duration(seconds: 10)),
        ),
        ScoreEvent(
          id: 'h2',
          side: Side.red,
          isHansoku: true,
          timestamp: now.add(const Duration(seconds: 20)),
        ),
        ScoreEvent(
          id: 'h3',
          side: Side.red,
          isHansoku: true,
          timestamp: now.add(const Duration(seconds: 30)),
        ),
        ScoreEvent(
          id: 'h4',
          side: Side.red,
          isHansoku: true,
          timestamp: now.add(const Duration(seconds: 40)),
        ),
      ];

      // イベント履歴から分析
      final analysis = ruleEngine.analyzeHistory(
        events,
        dummyMatch,
        const MatchRule(),
      );

      // 赤のスコアボードには一本表示なし
      expect(analysis.displays[Side.red]?.isEmpty ?? true, isTrue);

      // 白のスコアボードには「反」「反」が2本表示されていること
      final whiteDisplays = analysis.displays[Side.white] ?? [];
      expect(whiteDisplays.length, 2);
      expect(whiteDisplays[0].mark, '反');
      expect(whiteDisplays[1].mark, '反');

      // スコア集計（赤0本 vs 白2本）
      expect(analysis.context.redIppon, 0);
      expect(analysis.context.whiteIppon, 2);

      // 勝敗判定: 白の二本勝ち (whiteWin) が確定していること
      final result = ruleEngine.decideResult(
        analysis.context,
        const MatchRule(),
      );
      expect(result, MatchResultStatus.whiteWin);
    });
  });
}
