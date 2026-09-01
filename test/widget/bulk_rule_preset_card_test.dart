import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bulk_rule_preset_card.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  group('🛡️ BulkRulePresetCard Widget Tests', () {
    testWidgets('Renders category chips and scene sub chips correctly', (
      WidgetTester tester,
    ) async {
      String? selectedCat;
      String? selectedScene;

      final categoryRules = {
        '一般の部': const CategoryRuleSet(
          normalRule: MatchRule(matchTimeMinutes: 3.0, isIpponShobu: false),
          renseikaiRule: MatchRule(matchTimeMinutes: 2.0, isIpponShobu: true),
          useHonsenRule: true,
          useRenseikaiRule: true,
        ),
        '中学生の部': const CategoryRuleSet(
          normalRule: MatchRule(matchTimeMinutes: 2.0, isIpponShobu: false),
          useHonsenRule: true,
        ),
      };
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [themeColors]),
          home: Scaffold(
            body: BulkRulePresetCard(
              categoryRules: categoryRules,
              selectedCategoryRuleName: '一般の部',
              selectedSceneType: 'normal',
              primaryAccent: Colors.blue,
              isDark: false,
              textColor: Colors.black,
              onSelectCategory: (cat, ruleSet) => selectedCat = cat,
              onSelectScene: (scene, rule) => selectedScene = scene,
            ),
          ),
        ),
      );

      expect(find.text('試合ルール設定から一括セット'), findsOneWidget);
      expect(find.text('一般の部'), findsOneWidget);
      expect(find.text('中学生の部'), findsOneWidget);
      expect(find.text('🏆 本戦 (3分・3本)'), findsOneWidget);
      expect(find.text('⚔️ 錬成 (2分・1本)'), findsOneWidget);

      await tester.tap(find.text('中学生の部'));
      await tester.pump();
      expect(selectedCat, '中学生の部');

      await tester.tap(find.text('⚔️ 錬成 (2分・1本)'));
      await tester.pump();
      expect(selectedScene, 'renseikai');
    });

    testWidgets('Renders empty widget when categoryRules is empty', (
      WidgetTester tester,
    ) async {
      final themeColors = AppThemeColors.ofMode(isDark: true, mode: 'normal');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            brightness: Brightness.dark,
            extensions: [themeColors],
          ),
          home: Scaffold(
            body: BulkRulePresetCard(
              categoryRules: const {},
              selectedCategoryRuleName: null,
              selectedSceneType: 'normal',
              primaryAccent: Colors.purple,
              isDark: true,
              textColor: Colors.white,
              onSelectCategory: (cat, ruleSet) {},
              onSelectScene: (scene, rule) {},
            ),
          ),
        ),
      );

      expect(find.text('部門別ルールから一括セット'), findsNothing);
    });
  });
}
