import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/rules/rule_factory.dart';
import 'package:kendo_os/features/match/domain/rules/rule_serializer.dart';
import 'package:kendo_os/features/match/domain/rules/standard_kendo_rules.dart';
import 'package:kendo_os/features/match/domain/rules/tournament_rule_config.dart';

void main() {
  group('[Unit] ルールシリアライザーおよび動的リゾルバー単体テスト', () {
    test('現行構造のTournamentRuleConfigが完全な可逆性を持ってJSON往復変換されること', () {
      const original = TournamentRuleConfig(
        schemaVersion: 2,
        time: TimeConfig(matchTimeMinutes: 4.5, isRunningTime: true),
        encho: EnchoConfig(isEnchoUnlimited: true, enchoTimeMinutes: 2.0),
        scoring: ScoringConfig(ipponLimit: 1, isIpponShobu: true),
        hansoku: HansokuConfig(hansokuLimit: 4),
        draw: DrawConfig(hasHantei: true),
        team: TeamConfig(isKachinuki: true, kachinukiUnlimitedType: '無制限'),
      );

      final jsonStr = RuleSerializer.serialize(original);
      final restored = RuleSerializer.deserialize(jsonStr);

      expect(restored.schemaVersion, 2);
      expect(restored.time.matchTimeMinutes, 4.5);
      expect(restored.time.isRunningTime, isTrue);
      expect(restored.encho.isEnchoUnlimited, isTrue);
      expect(restored.encho.enchoTimeMinutes, 2.0);
      expect(restored.scoring.isIpponShobu, isTrue);
      expect(restored.scoring.ipponLimit, 1);
      expect(restored.hansoku.hansokuLimit, 4);
      expect(restored.draw.hasHantei, isTrue);
      expect(restored.team.isKachinuki, isTrue);
    });

    test('schemaVersionが存在しない旧MatchRule形式のJSONが安全に新スキーマへ変換されること', () {
      const oldRule = MatchRule(
        matchTimeMinutes: 5,
        enchoTimeMinutes: 3,
        ipponLimit: 2,
        isIpponShobu: false,
        hasHantei: true,
        isKachinuki: false,
      );

      final oldJson = oldRule.toJson();
      expect(oldJson.containsKey('schemaVersion'), isFalse);

      final oldJsonStr =
          '{"matchTimeMinutes":5,"enchoTimeMinutes":3,"ipponLimit":2,"isIpponShobu":false,"hasHantei":true,"isKachinuki":false}';
      final migrated = RuleSerializer.deserialize(oldJsonStr);

      expect(migrated.time.matchTimeMinutes, 5.0);
      expect(migrated.encho.enchoTimeMinutes, 3.0);
      expect(migrated.scoring.ipponLimit, 2);
      expect(migrated.scoring.isIpponShobu, isFalse);
      expect(migrated.draw.hasHantei, isTrue);
      expect(migrated.team.isKachinuki, isFalse);
    });

    test('Nullや空文字や破損JSONが与えられた場合に例外を投げずデフォルト設定が返ること', () {
      final fromNull = RuleSerializer.deserialize(null);
      expect(fromNull.time.matchTimeMinutes, 3.0);

      final fromEmpty = RuleSerializer.deserialize('   ');
      expect(fromEmpty.time.matchTimeMinutes, 3.0);

      final fromBroken = RuleSerializer.deserialize('{不正なJSON構文@@}');
      expect(fromBroken.time.matchTimeMinutes, 3.0);
    });

    test('ルールリゾルバーが設定内容に応じて適切なルールインスタンスをDI注入して構築すること', () {
      const configCustom = TournamentRuleConfig(
        scoring: ScoringConfig(isIpponShobu: true),
        draw: DrawConfig(hasHantei: true),
        hansoku: HansokuConfig(hansokuLimit: 2),
      );

      final ruleSet = RuleResolver.build(configCustom);

      expect(ruleSet.scoring, isA<IpponShobuScoringRule>());
      expect(ruleSet.victory, isA<HanteiVictoryRule>());
      expect(ruleSet.time, isA<StandardTimeRule>());
      expect(ruleSet.hansoku, isA<LimitHansokuRule>());
    });

    test('ルールリゾルバーが判定なし反則制限なしの設定で適切なフォールバック部品を選択すること', () {
      const configStandard = TournamentRuleConfig(
        scoring: ScoringConfig(isIpponShobu: false),
        draw: DrawConfig(hasHantei: false),
        hansoku: HansokuConfig(hansokuLimit: 0),
      );

      final ruleSet = RuleResolver.build(configStandard);

      expect(ruleSet.scoring, isA<LimitScoringRule>());
      expect(ruleSet.victory, isA<DrawVictoryRule>());
      expect(ruleSet.time, isA<StandardTimeRule>());
      expect(ruleSet.hansoku, isA<NoHansokuRule>());
    });
  });
}
