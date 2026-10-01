import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_match_helper.dart';

void main() {
  group('[Widget] CategoryRuleMatchHelper テスト', () {
    test('isAdvancedMatchNameにおいて 決勝・準決勝が正しく検知されること', () {
      expect(CategoryRuleMatchHelper.isAdvancedMatchName('第1コート 決勝戦'), isTrue);
      expect(
        CategoryRuleMatchHelper.isAdvancedMatchName('第2コート 準決勝第1試合'),
        isTrue,
      );
      expect(CategoryRuleMatchHelper.isAdvancedMatchName('第1コート 1回戦'), isFalse);
    });

    test('有効なMatchRuleインスタンスが正しく生成されること', () {
      final rule = CategoryRuleMatchHelper.buildMatchRule(
        category: '一般',
        matchType: '個人戦',
        matchTime: 3.0,
        isRunningTime: false,
        isIpponShobu: false,
        ipponLimit: 2,
        hansokuLimit: 2,
        hasHantei: false,
        hasExtension: true,
        isEnchoUnlimited: true,
        enchoTime: 3.0,
        enchoCount: 0,
        kachinukiUnlimitedType: '大将対大将',
        isDaihyoIpponShobu: true,
        winPoint: 0.0,
        lossPoint: 0.0,
        drawPoint: 0.0,
        isRenseikai: false,
        renseikaiType: '一試合制',
        overallTime: 30,
        daihyoMatchTime: 0.0,
        daihyoHasExtension: true,
        daihyoEnchoTime: 3.0,
        daihyoEnchoCount: -2,
        daihyoHasHantei: false,
      );

      expect(rule.category, '一般');
      expect(rule.matchTimeMinutes, 3.0);
      expect(rule.isEnchoUnlimited, isTrue);
    });
  });
}
