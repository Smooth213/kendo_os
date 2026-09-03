import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_context.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';

void main() {
  group('🥋 【Phase 1-3/10】全剣連規則第32条 不戦勝の自動2本付与＆チーム勝敗数決定論的積算テスト', () {
    late KendoRuleEngine ruleEngine;
    final dummyMatch = MatchModel(
      id: 'm_fusen',
      tournamentId: 't1',
      matchType: '個人戦',
      redName: '赤:不戦勝選手',
      whiteName: '白:欠席選手',
      matchTimeMinutes: 3.0,
      rule: const MatchRule(),
    );

    setUp(() {
      ruleEngine = KendoRuleEngine();
    });

    test('1. 赤の不戦勝（相手欠席）時、自動的に「◯」「◯」の2本が付与され赤の二本勝ちとなること', () {
      final now = DateTime(2026, 9, 3, 10, 0, 0);

      // 通常不戦勝イベント（isRetirement: false）
      final events = [
        ScoreEvent(
          id: 'fusen_event_1',
          side: Side.red,
          isFusen: true,
          isRetirement: false,
          timestamp: now,
        ),
      ];

      final analysis = ruleEngine.analyzeHistory(
        events,
        dummyMatch,
        const MatchRule(),
      );

      // 赤のスコアボード: 自動的に「◯」「◯」が2本付与されていること
      final redDisplays = analysis.displays[Side.red] ?? [];
      expect(redDisplays.length, 2);
      expect(redDisplays[0].mark, '◯');
      expect(redDisplays[1].mark, '◯');

      // 白のスコアボード: 0本
      final whiteDisplays = analysis.displays[Side.white] ?? [];
      expect(whiteDisplays.isEmpty, isTrue);

      // 取得本数の積算（赤: 2本, 白: 0本）
      expect(analysis.context.redIppon, 2);
      expect(analysis.context.whiteIppon, 0);

      // 勝敗判定: 赤の勝ち (redWin)
      final result = ruleEngine.decideResult(
        analysis.context,
        const MatchRule(),
      );
      expect(result, MatchResultStatus.redWin);
    });
  });
}
