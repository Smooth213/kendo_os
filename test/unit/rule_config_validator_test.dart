import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/rules/rule_config_validator.dart';
import 'package:kendo_os/features/match/domain/rules/tournament_rule_config.dart';

void main() {
  group('[Unit] 大会ルール設定バリデーター境界値検証テスト', () {
    test('デフォルト設定ではエラーが一切検知されず正常判定されること', () {
      const config = TournamentRuleConfig();
      final errors = RuleConfigValidator.validate(config);
      expect(errors, isEmpty);
    });

    test('試合時間が0分または負数の場合に適切なエラーメッセージが返却されること', () {
      const zeroConfig = TournamentRuleConfig(
        time: TimeConfig(matchTimeMinutes: 0),
      );
      final zeroErrors = RuleConfigValidator.validate(zeroConfig);
      expect(zeroErrors, contains('試合時間は0分より大きい必要があります。'));

      const negativeConfig = TournamentRuleConfig(
        time: TimeConfig(matchTimeMinutes: -1.0),
      );
      final negativeErrors = RuleConfigValidator.validate(negativeConfig);
      expect(negativeErrors, contains('試合時間は0分より大きい必要があります。'));
    });

    test('延長戦あり設定で延長時間が0分以下の場合にエラーが検知されること', () {
      const invalidUnlimited = TournamentRuleConfig(
        encho: EnchoConfig(isEnchoUnlimited: true, enchoTimeMinutes: 0),
      );
      final errors1 = RuleConfigValidator.validate(invalidUnlimited);
      expect(errors1, contains('延長戦を行う場合、延長時間は0分より大きい必要があります。'));

      const invalidCount = TournamentRuleConfig(
        encho: EnchoConfig(
          isEnchoUnlimited: false,
          enchoCount: 1,
          enchoTimeMinutes: -0.5,
        ),
      );
      final errors2 = RuleConfigValidator.validate(invalidCount);
      expect(errors2, contains('延長戦を行う場合、延長時間は0分より大きい必要があります。'));
    });

    test('規定本数が0本以下かつ一本勝負でない場合にエラーが検知されること', () {
      const invalidScoring = TournamentRuleConfig(
        scoring: ScoringConfig(ipponLimit: 0, isIpponShobu: false),
      );
      final errors = RuleConfigValidator.validate(invalidScoring);
      expect(errors, contains('規定本数は1本以上である必要があります。'));
    });

    test('反則回数上限が負数の場合にエラーが検知されること', () {
      const invalidHansoku = TournamentRuleConfig(
        hansoku: HansokuConfig(hansokuLimit: -1),
      );
      final errors = RuleConfigValidator.validate(invalidHansoku);
      expect(errors, contains('反則回数の上限は0以上である必要があります。'));
    });

    test('勝ち抜き戦大将引き分け延長時の依存関係矛盾が正確に検知されること', () {
      // 矛盾ケース: 勝ち抜き戦大将引き分け延長なのに延長回数0・無制限オフ・判定なし
      const conflicted = TournamentRuleConfig(
        team: TeamConfig(isKachinuki: true, kachinukiUnlimitedType: '大将引き分け延長'),
        encho: EnchoConfig(isEnchoUnlimited: false, enchoCount: 0),
        draw: DrawConfig(hasHantei: false),
      );
      final errors = RuleConfigValidator.validate(conflicted);
      expect(errors, contains('勝ち抜き戦(大将延長)が有効ですが、延長ルールまたは判定が設定されていません。'));

      // 解消ケース1: 延長無制限がオン
      final resolvedByUnlimited = conflicted.copyWith(
        encho: conflicted.encho.copyWith(isEnchoUnlimited: true),
      );
      expect(RuleConfigValidator.validate(resolvedByUnlimited), isEmpty);

      // 解消ケース2: 延長回数が1回以上
      final resolvedByCount = conflicted.copyWith(
        encho: conflicted.encho.copyWith(enchoCount: 1),
      );
      expect(RuleConfigValidator.validate(resolvedByCount), isEmpty);

      // 解消ケース3: 判定が有効
      final resolvedByHantei = conflicted.copyWith(
        draw: conflicted.draw.copyWith(hasHantei: true),
      );
      expect(RuleConfigValidator.validate(resolvedByHantei), isEmpty);
    });
  });
}
