import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rules_list_section.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';

void main() {
  group('🛡️ CategoryRulesListSection Widget Tests', () {
    testWidgets('Renders empty state when no category rules', (tester) async {
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

    testWidgets('Renders categories and trigger callbacks', (tester) async {
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
