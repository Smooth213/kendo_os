import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_category_tile.dart';

void main() {
  group('CategoryRuleCategoryTile Widget Tests', () {
    testWidgets('renders category name and triggers onShowRuleDetail on tap', (
      tester,
    ) async {
      bool detailCalled = false;
      bool editCalled = false;
      bool deleteCalled = false;

      final ruleSet = CategoryRuleSet(
        matchType: '個人戦',
        normalRule: MatchRule(matchTimeMinutes: 3),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryRuleCategoryTile(
              category: '中学生男子の部',
              ruleSet: ruleSet,
              isDark: false,
              enableLiquidGlass: false,
              onStartEditing: () => editCalled = true,
              onDeleteCategory: () => deleteCalled = true,
              onShowRuleDetail: () => detailCalled = true,
            ),
          ),
        ),
      );

      expect(find.text('中学生男子の部'), findsOneWidget);

      await tester.tap(find.text('中学生男子の部'));
      await tester.pump();
      expect(detailCalled, isTrue);
      expect(editCalled, isFalse);
      expect(deleteCalled, isFalse);
    });
  });
}
