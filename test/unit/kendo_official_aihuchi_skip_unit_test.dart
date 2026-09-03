import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/score/score_event.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';

void main() {
  group('🥋 【Phase 1-5/10】全剣連規則 相打ち・無効打突時のスコア不変性＆タイマー再開制御テスト', () {
    late KendoRuleEngine ruleEngine;
    final startTime = DateTime(2026, 9, 3, 10, 0, 0);

    final match = MatchModel(
      id: 'm_aihuchi',
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

    test('1. 相打ち（同時打突）発生時、有効打突不成立としてスコアに変化がないこと', () {
      // 相打ち時はスコアイベントを記録しない（審判は「相打ち」と宣告して始めに戻す）
      final List<ScoreEvent> activeEvents = [];

      final analysis = ruleEngine.analyzeHistory(
        activeEvents,
        match,
        const MatchRule(),
      );

      expect(analysis.context.redIppon, 0);
      expect(analysis.context.whiteIppon, 0);
      expect(analysis.displays[Side.red]?.isEmpty ?? true, isTrue);
      expect(analysis.displays[Side.white]?.isEmpty ?? true, isTrue);
    });

    test('2. 相打ちによる時計停止（中段）➔ 再開後、タイマー経過秒数が正しく積算されること', () {
      // 30秒経過時点で相打ち発生、時計停止（10:00:30）
      // 停止時間: 15秒間（合議・位置戻し）
      // 10:00:45 に「始め」で再開
      final pausedMatch = match.copyWith(
        timerStartedAt: null,
        accumulatedPauseDurationMs: 30 * 1000,
      );

      // 停止中の残り時間: 180 - 30 = 150秒
      expect(
        pausedMatch.calculateRemainingSeconds(
          startTime.add(const Duration(seconds: 40)),
        ),
        150,
      );

      // 再開（timerStartedAt = 10:00:45）
      final resumedMatch = pausedMatch.copyWith(
        timerStartedAt: startTime.add(const Duration(seconds: 45)),
      );

      // 再開から10秒後（10:00:55） ➔ 合計40秒経過 ➔ 残り140秒
      expect(
        resumedMatch.calculateRemainingSeconds(
          startTime.add(const Duration(seconds: 55)),
        ),
        140,
      );
    });
  });
}
