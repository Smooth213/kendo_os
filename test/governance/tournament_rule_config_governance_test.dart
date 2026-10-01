import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/rules/rule_config_validator.dart';
import 'package:kendo_os/features/match/domain/rules/rule_factory.dart';
import 'package:kendo_os/features/match/domain/rules/rule_serializer.dart';
import 'package:kendo_os/features/match/domain/rules/standard_kendo_rules.dart';
import 'package:kendo_os/features/match/domain/rules/tournament_rule_config.dart';

void main() {
  group('[Governance] 大会ルール設定バリデーションおよび永続化マイグレーション保証規約', () {
    test('ルール設定バリデータが無効な試合時間や不正な延長設定を検知して遮断すること', () {
      // 正常系
      const validConfig = TournamentRuleConfig();
      expect(RuleConfigValidator.validate(validConfig), isEmpty);

      // 試合時間が0以下
      const zeroTimeConfig = TournamentRuleConfig(
        time: TimeConfig(matchTimeMinutes: 0),
      );
      final zeroTimeErrors = RuleConfigValidator.validate(zeroTimeConfig);
      expect(zeroTimeErrors, contains('試合時間は0分より大きい必要があります。'));

      // 延長戦ありなのに延長時間が0以下
      const zeroEnchoConfig = TournamentRuleConfig(
        encho: EnchoConfig(isEnchoUnlimited: true, enchoTimeMinutes: 0),
      );
      final zeroEnchoErrors = RuleConfigValidator.validate(zeroEnchoConfig);
      expect(zeroEnchoErrors, contains('延長戦を行う場合、延長時間は0分より大きい必要があります。'));

      // 勝ち抜き戦大将延長で延長も判定も未設定
      const invalidKachinukiConfig = TournamentRuleConfig(
        team: TeamConfig(isKachinuki: true, kachinukiUnlimitedType: '大将引き分け延長'),
        encho: EnchoConfig(isEnchoUnlimited: false, enchoCount: 0),
        draw: DrawConfig(hasHantei: false),
      );
      final kachinukiErrors = RuleConfigValidator.validate(
        invalidKachinukiConfig,
      );
      expect(
        kachinukiErrors,
        contains('勝ち抜き戦(大将延長)が有効ですが、延長ルールまたは判定が設定されていません。'),
      );
    });

    test('ルールシリアライザーが新旧スキーマおよび破損JSONに対して安全にマイグレーションと復元を行うこと', () {
      // 1. 新スキーマのシリアライズ＆デシリアライズ
      const originalConfig = TournamentRuleConfig(
        schemaVersion: 2,
        time: TimeConfig(matchTimeMinutes: 5),
      );
      final jsonStr = RuleSerializer.serialize(originalConfig);
      final restored = RuleSerializer.deserialize(jsonStr);
      expect(restored.schemaVersion, 2);
      expect(restored.time.matchTimeMinutes, 5);

      // 2. 旧スキーマ (MatchRule) からの自動マイグレーション
      const oldRule = MatchRule(
        matchTimeMinutes: 3,
        ipponLimit: 1,
        isIpponShobu: true,
      );
      final oldJsonStr =
          '{"matchTimeMinutes": ${oldRule.matchTimeMinutes.toInt()}, "ipponLimit": ${oldRule.ipponLimit}, "isIpponShobu": ${oldRule.isIpponShobu}}';
      final migrated = RuleSerializer.deserialize(oldJsonStr);
      expect(migrated.time.matchTimeMinutes, 3.0);
      expect(migrated.scoring.isIpponShobu, isTrue);

      // 3. 不正文字列や空文字での安全なデフォルト復元
      final fromEmpty = RuleSerializer.deserialize('');
      expect(fromEmpty.time.matchTimeMinutes, 3.0);

      final fromCorrupt = RuleSerializer.deserialize('{corrupted_json_syntax}');
      expect(fromCorrupt.time.matchTimeMinutes, 3.0);
    });

    test('ルールリゾルバーが大会設定から適切なルール部品を動的に組み立てること', () {
      // 1本勝負・判定あり設定
      const config1 = TournamentRuleConfig(
        scoring: ScoringConfig(isIpponShobu: true, ipponLimit: 1),
        draw: DrawConfig(hasHantei: true),
        hansoku: HansokuConfig(hansokuLimit: 2),
      );
      final ruleSet1 = RuleResolver.build(config1);
      expect(ruleSet1.scoring, isA<IpponShobuScoringRule>());
      expect(ruleSet1.victory, isA<HanteiVictoryRule>());
      expect(ruleSet1.time, isA<StandardTimeRule>());
      expect(ruleSet1.hansoku, isA<LimitHansokuRule>());

      // 通常勝負・判定なし設定
      const config2 = TournamentRuleConfig(
        scoring: ScoringConfig(isIpponShobu: false, ipponLimit: 2),
        draw: DrawConfig(hasHantei: false),
        hansoku: HansokuConfig(hansokuLimit: 0),
      );
      final ruleSet2 = RuleResolver.build(config2);
      expect(ruleSet2.scoring, isA<LimitScoringRule>());
      expect(ruleSet2.victory, isA<DrawVictoryRule>());
      expect(ruleSet2.hansoku, isA<NoHansokuRule>());
    });
  });
}
