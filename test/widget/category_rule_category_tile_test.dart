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

    testWidgets('renders category with subtitle and comment', (tester) async {
      final ruleSet = CategoryRuleSet(
        matchType: '団体戦',
        subtitle: '決勝トーナメント',
        comment: '3人制・代表戦あり',
        normalRule: MatchRule(matchTimeMinutes: 3),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryRuleCategoryTile(
              category: '小学生の部',
              ruleSet: ruleSet,
              isDark: false,
              enableLiquidGlass: false,
              onStartEditing: () {},
              onDeleteCategory: () {},
              onShowRuleDetail: () {},
            ),
          ),
        ),
      );

      expect(find.text('小学生の部 決勝トーナメント'), findsOneWidget);
      expect(find.text('3人制・代表戦あり'), findsOneWidget);
      expect(find.byIcon(Icons.comment_outlined), findsOneWidget);
    });

    testWidgets(
      'omits (2) when subtitle makes it distinguishable, but keeps (2) when duplicated',
      (tester) async {
        final rules = <String, CategoryRuleSet>{
          '小学生の部': const CategoryRuleSet(subtitle: '予選リーグ'),
          '小学生の部 (2)': const CategoryRuleSet(subtitle: '決勝トーナメント'),
          '中学生の部': const CategoryRuleSet(subtitle: '決勝'),
          '中学生の部 (2)': const CategoryRuleSet(subtitle: '決勝'),
        };

        // ① 他と重複しない場合: (2) が省略されて「小学生の部 決勝トーナメント」になる
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CategoryRuleCategoryTile(
                category: '小学生の部 (2)',
                ruleSet: rules['小学生の部 (2)']!,
                allCategoryRules: rules,
                isDark: false,
                enableLiquidGlass: false,
                onStartEditing: () {},
                onDeleteCategory: () {},
                onShowRuleDetail: () {},
              ),
            ),
          ),
        );
        expect(find.text('小学生の部 決勝トーナメント'), findsOneWidget);
        expect(find.text('小学生の部 (2) 決勝トーナメント'), findsNothing);

        // ② 他と重複する場合: (2) が維持されて「中学生の部 (2) 決勝」になる
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CategoryRuleCategoryTile(
                category: '中学生の部 (2)',
                ruleSet: rules['中学生の部 (2)']!,
                allCategoryRules: rules,
                isDark: false,
                enableLiquidGlass: false,
                onStartEditing: () {},
                onDeleteCategory: () {},
                onShowRuleDetail: () {},
              ),
            ),
          ),
        );
        expect(find.text('中学生の部 (2) 決勝'), findsOneWidget);
      },
    );
  });
}
