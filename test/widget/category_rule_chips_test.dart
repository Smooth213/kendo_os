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

      expect(find.text('標準ルール'), findsOneWidget);
      expect(find.text('3分'), findsOneWidget);
      expect(find.text('延長無制限'), findsOneWidget);
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

      expect(find.text('⚔️ 錬成会'), findsOneWidget);
      expect(find.text('流し'), findsOneWidget);
      expect(find.text('🏆 本戦'), findsOneWidget);
      expect(find.text('4分'), findsOneWidget);
      expect(find.text('🤝 申し合わせ'), findsOneWidget);
    });
  });
}
