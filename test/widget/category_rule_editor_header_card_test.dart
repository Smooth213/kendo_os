import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_editor_header_card.dart';

void main() {
  testWidgets('CategoryRuleEditorHeaderCard renders category and switches', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CategoryRuleEditorHeaderCard(
              category: '一般男子の部',
              textColor: Colors.black,
              matchType: '個人戦',
              isMultiScene: false,
              useAdvancedRule: false,
              onMatchTypeChanged: (_) {},
              onMultiSceneChanged: (_) {},
              onUseAdvancedRuleChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('対象部門'), findsOneWidget);
    expect(find.text('一般男子の部'), findsOneWidget);
    expect(find.text('試合方式'), findsOneWidget);
    expect(find.text('準決勝・決勝は別ルールにする'), findsOneWidget);
  });
}
