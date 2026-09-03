import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';

void main() {
  group('🥋 【Phase 1-4/10】審判合議による直前の一本取り消し（Undo）＆タイマー巻き戻しテスト', () {
    late KendoRuleEngine ruleEngine;
    final startTime = DateTime(2026, 9, 3, 10, 0, 0);

    final initialMatch = MatchModel(
      id: 'm_gogi',
      tournamentId: 't1',
      matchType: '個人戦',
      redName: '選手A',
      whiteName: '選手B',
      matchTimeMinutes: 3.0,
      timerStartedAt: startTime,
      accumulatedPauseDurationMs: 0,
      rule: const MatchRule(),
    );

    setUp(() {
      ruleEngine = KendoRuleEngine();
    });

    test('1. 赤面宣告 ➔ 審判合議によるUndoイベント付与で、赤面が完全に無効化され0-0に戻ること', () {
      // 1. 赤面イベント
      final scoreEvent = ScoreEvent(
        id: 'ev_men_1',
        side: Side.red,
        strikeType: StrikeType.men,
        isIppon: true,
        timestamp: startTime.add(const Duration(seconds: 40)),
        sequence: 1,
        logicalClock: 1,
      );

      // 赤面のみの状態
      final analysisBefore = ruleEngine.analyzeHistory(
        [scoreEvent],
        initialMatch,
        const MatchRule(),
      );
      expect(analysisBefore.context.redIppon, 1);
      expect(analysisBefore.displays[Side.red]?.first.mark, 'メ');

      // 2. 合議による取り消し（Undo）イベント
      final undoEvent = ScoreEvent(
        id: 'ev_undo_1',
        side: Side.none,
        isUndo: true,
        targetId: 'ev_men_1',
        timestamp: startTime.add(const Duration(seconds: 50)),
        sequence: 2,
        logicalClock: 2,
      );

      // 取り消し適用後の履歴分析
      final analysisAfter = ruleEngine.analyzeHistory(
        [scoreEvent, undoEvent],
        initialMatch,
        const MatchRule(),
      );

      // 赤の一本が完全に取り消され 0本に戻ること
      expect(analysisAfter.context.redIppon, 0);
      expect(analysisAfter.displays[Side.red]?.isEmpty ?? true, isTrue);
      expect(analysisAfter.context.whiteIppon, 0);
    });

    test('2. タイマー手動修正（残り時間巻き戻し・進め）で絶対時間が正しく再計算されること', () {
      // 初期状態: 3分（180秒）
      expect(initialMatch.calculateRemainingSeconds(startTime), 180);

      // タイマーを残り150秒（30秒経過時点）へ手動巻き戻し・修正
      final rewoundMatch = initialMatch.updateRemainingSeconds(150, startTime);

      // 残り秒数が150秒として計算されること
      expect(rewoundMatch.calculateRemainingSeconds(startTime), 150);

      // 10秒経過後 ➔ 140秒
      expect(
        rewoundMatch.calculateRemainingSeconds(
          startTime.add(const Duration(seconds: 10)),
        ),
        140,
      );
    });
  });
}
