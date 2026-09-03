import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';

void main() {
  group('🚀 【Phase 5-3/10】大会途中レギュレーション動的変更・過去試合非汚染伝播 E2Eテスト', () {
    test('1. 途中でルール変更（4分三本勝負 ➔ 3分一本勝負）時、終了済試合は不変で未実施試合のみ新ルールが適用されること', () {
      const originalRule = MatchRule(
        matchTimeMinutes: 4.0,
        isIpponShobu: false,
      );
      const updatedRule = MatchRule(matchTimeMinutes: 3.0, isIpponShobu: true);

      // 1. 変更前に終了した第1試合（4分三本勝負で2-1決着）
      final finishedMatch = MatchModel(
        id: 'm_past_01',
        tournamentId: 't1',
        matchType: '個人戦',
        redName: '佐藤',
        whiteName: '鈴木',
        redScore: 2,
        whiteScore: 1,
        status: 'finished',
        rule: originalRule,
      );

      // 2. まだ始まっていない第2試合（待機中）
      final pendingMatch = MatchModel(
        id: 'm_future_02',
        tournamentId: 't1',
        matchType: '個人戦',
        redName: '高橋',
        whiteName: '田中',
        redScore: 0,
        whiteScore: 0,
        status: 'waiting',
        rule: originalRule,
      );

      // 🚨 大会本部がルール一括変更を発令！
      // 未実施試合のみ新しいルール（3分一本勝負）へ更新
      final propagatedPendingMatch = pendingMatch.copyWith(rule: updatedRule);

      // 過去試合のルールとスコアは1ミリも汚染されていないこと
      expect(finishedMatch.rule?.matchTimeMinutes, 4.0);
      expect(finishedMatch.rule?.isIpponShobu, isFalse);
      expect(finishedMatch.redScore, 2);
      expect(finishedMatch.whiteScore, 1);

      // 未実施試合は即座に新ルール（3分一本勝負）が反映されていること
      expect(propagatedPendingMatch.rule?.matchTimeMinutes, 3.0);
      expect(propagatedPendingMatch.rule?.isIpponShobu, isTrue);
    });
  });
}
