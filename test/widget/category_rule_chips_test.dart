import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_chips.dart';

void main() {
  group('🛡️ CategoryRuleChips Widget Tests', () {
    testWidgets('Renders standard rules chips', (WidgetTester tester) async {
      final ruleSet = const CategoryRuleSet(
        normalRule: MatchRule(
          matchTimeMinutes: 3.0,
          enchoCount: 0,
          isEnchoUnlimited: true,
          hasHantei: false,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryRuleChips(ruleSet: ruleSet, isDark: false),
          ),
        ),
      );

      expect(find.text('🥋 個人戦'), findsOneWidget);
      expect(find.text('⏱️ 3分'), findsOneWidget);
      expect(find.text('⏳ 延長無制限'), findsOneWidget);
    });

    testWidgets('Renders multi-scene chips (renseikai, honsen, moushiawase)', (
      WidgetTester tester,
    ) async {
      final ruleSet = const CategoryRuleSet(
        isMultiScene: true,
        useRenseikaiRule: true,
        useHonsenRule: true,
        useMoushiawaseRule: true,
        renseikaiRule: MatchRule(
          matchTimeMinutes: 2.0,
          isRunningTime: true,
          hasHantei: true,
        ),
        normalRule: MatchRule(matchTimeMinutes: 4.0, isEnchoUnlimited: true),
        moushiawaseRule: MatchRule(matchTimeMinutes: 2.0, hasHantei: true),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryRuleChips(ruleSet: ruleSet, isDark: true),
          ),
        ),
      );

      expect(find.text('⚔️ 錬成'), findsOneWidget);
      expect(find.text('🔄 通し'), findsOneWidget);
      expect(find.text('🏆 本戦'), findsOneWidget);
      expect(find.text('⏱️ 4分'), findsOneWidget);
      expect(find.text('🤝 申合せ'), findsOneWidget);
    });

    testWidgets('Renders advancedRule chips with 1本勝負 badge', (
      WidgetTester tester,
    ) async {
      final ruleSet = const CategoryRuleSet(
        useAdvancedRule: true,
        normalRule: MatchRule(matchTimeMinutes: 3.0, isIpponShobu: false),
        advancedRule: MatchRule(
          matchTimeMinutes: 2.5,
          isIpponShobu: true,
          isEnchoUnlimited: true,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryRuleChips(ruleSet: ruleSet, isDark: false),
          ),
        ),
      );

      expect(find.text('🥋 個人戦'), findsOneWidget);
      expect(find.text('⏱️ 3分'), findsOneWidget);
      expect(find.text('🔥 上位戦'), findsOneWidget);
      expect(find.text('⏱️ 2分30秒'), findsOneWidget);
      expect(find.text('⚡ 1本勝負'), findsOneWidget);
      expect(find.text('⏳ 延長無制限'), findsOneWidget);
    });
  });
}
