import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bulk_rule_apply_helper.dart';

void main() {
  group('[Unit] 大会コート全体ルール一括適用エンジン単体テスト', () {
    test('computeRuleParamsにおいて団体戦および個人戦のルール条件が正確に計算されること', () {
      const teamRule = MatchRule(
        matchTimeMinutes: 4.0,
        isIpponShobu: false,
        enchoTimeMinutes: 3.0,
        enchoCount: 1,
        isEnchoUnlimited: false,
        hasHantei: true,
        hasRepresentativeMatch: true,
        isDaihyoIpponShobu: true,
        daihyoMatchTimeMinutes: 4.0,
        daihyoHasExtension: true,
        daihyoEnchoTimeMinutes: 3.0,
        daihyoEnchoCount: -2, // 無制限
      );

      final teamParams = BulkRuleApplyHelper.computeRuleParams(
        targetRule: teamRule,
        isTeam: true,
        isIndiv: false,
      );

      expect(teamParams.matchTime, 4.0);
      expect(teamParams.isIpponShobu, isFalse);
      expect(teamParams.hasExtension, isTrue);
      expect(teamParams.hasHantei, isTrue);
      expect(teamParams.hasRepresentativeMatch, isTrue);
      expect(teamParams.isDaihyoIpponShobu, isTrue);
      expect(teamParams.isDaihyoEnchoUnlimited, isTrue);

      // 個人戦では代表戦フラグが自動的に無効化されること
      final indivParams = BulkRuleApplyHelper.computeRuleParams(
        targetRule: teamRule,
        isTeam: false,
        isIndiv: true,
      );
      expect(indivParams.hasRepresentativeMatch, isFalse);
    });

    test('錬成会および申合せシーンにおいて専用パラメータが自動適用されること', () {
      const renseikaiRule = MatchRule(
        matchTimeMinutes: 3.0,
        matchScene: 'renseikai',
        isRenseikai: true,
        renseikaiType: '勝ち残り制',
        overallTimeMinutes: 45,
      );

      final params = BulkRuleApplyHelper.computeRuleParams(
        targetRule: renseikaiRule,
        isTeam: false,
        isIndiv: false,
        sceneKey: 'renseikai',
      );

      expect(params.isRenseikai, isTrue);
      expect(params.renseikaiType, '勝ち残り制');
      expect(params.overallTimeMinutes, 45);
    });
  });
}
