import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_advanced_tabs_card.dart';

void main() {
  testWidgets('CategoryRuleAdvancedTabsCard renders tabs and views', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CategoryRuleAdvancedTabsCard(
              normalRuleSection: Text('通常戦ビュー'),
              advancedRuleSection: Text('上位戦ビュー'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('通常戦のルール'), findsOneWidget);
    expect(find.text('上位戦（準決勝・決勝）'), findsOneWidget);
    expect(find.text('通常戦ビュー'), findsOneWidget);
  });
}
