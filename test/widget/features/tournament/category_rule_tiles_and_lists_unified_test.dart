import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_category_tile.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rules_list_section.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';

void main() {
  group('[Widget] CategoryRuleTilesAndLists 統合テスト', () {
    testWidgets('部門名が表示されタップ時にルール詳細コールバックが正しく実行されること', (tester) async {
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

    testWidgets('部門 with subtitle and commentが正しく描画されること', (tester) async {
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

    testWidgets('サブタイトルで区別可能な場合は(2)が省略され、重複時は(2)が保持されること', (tester) async {
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
    });

    testWidgets('no 部門 ルール設定において 空状態が正しく描画されること', (tester) async {
      final tournament = TournamentModel(
        id: 't1',
        organizationId: 'org1',
        name: '第1回 大会',
        date: DateTime(2026, 8, 20),
        venue: '武道館',
        categoryRules: {},
      );

      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryRulesListSection(
              tournament: tournament,
              isDark: false,
              enableLiquidGlass: false,
              newCategoryController: controller,
              presetCategories: ['小学生低学年の部', '中学生男子の部'],
              isFromSetup: false,
              tournamentId: 't1',
              onAddCategory: (_) {},
              onStartEditing: (_, _) {},
              onDeleteCategory: (_) {},
              onShowRuleDetail: (_, _) {},
            ),
          ),
        ),
      );

      expect(find.text('部門別ルールが未登録です。\n上の入力欄から部門を追加してください。'), findsOneWidget);
      expect(find.text('小学生低学年の部'), findsOneWidget);
    });

    testWidgets('部門一覧 and trigger callbacksが正しく描画されること', (tester) async {
      final tournament = TournamentModel(
        id: 't1',
        organizationId: 'org1',
        name: '第1回 大会',
        date: DateTime(2026, 8, 20),
        venue: '武道館',
        categoryRules: {
          '一般男子の部': CategoryRuleSet(
            matchType: '個人戦',
            normalRule: MatchRule(matchTimeMinutes: 3, isIpponShobu: false),
          ),
        },
      );

      final controller = TextEditingController();
      bool tappedDetail = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryRulesListSection(
              tournament: tournament,
              isDark: false,
              enableLiquidGlass: false,
              newCategoryController: controller,
              presetCategories: ['小学生低学年の部'],
              isFromSetup: false,
              tournamentId: 't1',
              onAddCategory: (_) {},
              onStartEditing: (_, _) {},
              onDeleteCategory: (_) {},
              onShowRuleDetail: (_, _) {
                tappedDetail = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('一般男子の部'), findsOneWidget);
      await tester.tap(find.text('一般男子の部'));
      await tester.pump();
      expect(tappedDetail, isTrue);
    });
  });
}
