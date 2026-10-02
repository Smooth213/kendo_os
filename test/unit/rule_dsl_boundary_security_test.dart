import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/rules/rule_dsl_boundary.dart';
import 'package:kendo_os/features/match/domain/rules/tournament_rule_config.dart';
import 'package:kendo_os/shared/config/beta_feature_flags.dart';

void main() {
  group('[Unit] RuleDslMapper 境界および動的改ざん完全遮断テスト', () {
    test('ルール設定から完全かつ決定論的なテキスト形式のDSL文字列が出力されること', () {
      const config = TournamentRuleConfig(
        time: TimeConfig(matchTimeMinutes: 3.5, isRunningTime: false),
        scoring: ScoringConfig(isIpponShobu: true, ipponLimit: 1),
        encho: EnchoConfig(
          isEnchoUnlimited: false,
          enchoTimeMinutes: 2.0,
          enchoCount: 3,
        ),
        draw: DrawConfig(hasHantei: true),
        hansoku: HansokuConfig(hansokuLimit: 2),
        team: TeamConfig(isKachinuki: true),
      );

      final dsl = RuleDslMapper.exportToDsl(config);

      expect(dsl, contains('TournamentRule (v1) {'));
      expect(dsl, contains('matchTimeMinutes: 3.5'));
      expect(dsl, contains('isRunningTime: false'));
      expect(dsl, contains('isIpponShobu: true'));
      expect(dsl, contains('ipponLimit: 1'));
      expect(dsl, contains('isEnchoUnlimited: false'));
      expect(dsl, contains('enchoTimeMinutes: 2.0'));
      expect(dsl, contains('enchoCount: 3'));
      expect(dsl, contains('hasHantei: true'));
      expect(dsl, contains('hansokuLimit: 2'));
      expect(dsl, contains('isKachinuki: true'));
    });

    test('通常環境において外部DSLからのルール動的読み込みが拒絶され例外を送出すること', () {
      expect(BetaFeatureFlags.showRuleDslEditor, isFalse);

      const fakeDsl = '''
TournamentRule (v1) {
  Time { matchTimeMinutes: 10.0 }
}
''';

      expect(
        () => RuleDslMapper.importFromDsl(fakeDsl),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('ルールスキーマレジストリの全メタデータ定義が空文字なく完全に登録されていること', () {
      final schemas = RuleSchemaRegistry.schemas;
      expect(schemas, isNotEmpty);
      expect(schemas.length, greaterThanOrEqualTo(9));

      for (final schema in schemas) {
        expect(schema.property, isNotEmpty);
        expect(schema.displayName, isNotEmpty);
        expect(schema.description, isNotEmpty);
      }
    });
  });
}
