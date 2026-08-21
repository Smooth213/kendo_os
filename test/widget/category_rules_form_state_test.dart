import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rules_form_state.dart';

void main() {
  group('CategoryRulesFormState Tests', () {
    test(
      'populateFromRuleSet fills state and buildCategoryRuleSet reproduces it',
      () {
        final formState = CategoryRulesFormState();
        final initialRule = CategoryRuleSet(
          matchType: '団体戦',
          normalRule: MatchRule(
            matchTimeMinutes: 4.0,
            isRunningTime: true,
            enchoCount: 2,
          ),
          advancedRule: MatchRule(
            matchTimeMinutes: 5.0,
            isEnchoUnlimited: true,
          ),
          useAdvancedRule: true,
          advancedKeywords: ['決勝', '準決勝'],
        );

        formState.populateFromRuleSet('小学生の部', initialRule);

        expect(formState.editingCategory, '小学生の部');
        expect(formState.normalTime, 4.0);
        expect(formState.normalIsRunningTime, isTrue);
        expect(formState.advancedTime, 5.0);
        expect(formState.useAdvancedRule, isTrue);

        final generated = formState.buildCategoryRuleSet('小学生の部');
        expect(generated.normalRule.matchTimeMinutes, 4.0);
        expect(generated.normalRule.isRunningTime, isTrue);
        expect(generated.advancedRule.matchTimeMinutes, 5.0);
        expect(generated.useAdvancedRule, isTrue);
        expect(generated.advancedKeywords, contains('決勝'));
      },
    );
  });
}
