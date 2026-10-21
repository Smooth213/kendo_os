import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/rules/category_rule_set.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bulk_rule_preset_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/bulk_rule_target_select_section.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  group('[Widget] BulkRulePresetAndTargetSelect 統合テスト', () {
    testWidgets('部門 チップ一覧 and scene sub チップ一覧 correctlyが正しく描画されること', (
      WidgetTester tester,
    ) async {
      String? selectedCat;
      String? selectedScene;

      final categoryRules = {
        '一般の部': const CategoryRuleSet(
          normalRule: MatchRule(matchTimeMinutes: 3.0, isIpponShobu: false),
          renseikaiRule: MatchRule(matchTimeMinutes: 2.0, isIpponShobu: true),
          isMultiScene: true,
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

    testWidgets('部門チップ一覧がサブタイトルとともに正しく描画されること', (WidgetTester tester) async {
      final categoryRules = {
        '小学生の部': const CategoryRuleSet(
          subtitle: '予選リーグ',
          normalRule: MatchRule(matchTimeMinutes: 3.0),
          useHonsenRule: true,
        ),
        '小学生の部 (2)': const CategoryRuleSet(
          subtitle: '決勝トーナメント',
          normalRule: MatchRule(matchTimeMinutes: 3.0),
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
              selectedCategoryRuleName: '小学生の部 (2)',
              selectedSceneType: 'normal',
              primaryAccent: Colors.blue,
              isDark: false,
              textColor: Colors.black,
              onSelectCategory: (cat, ruleSet) {},
              onSelectScene: (scene, rule) {},
            ),
          ),
        ),
      );

      // 小学生の部 (2) は見分けがつくため (2) が省略されて「小学生の部 (決勝トーナメント)」と表示される
      expect(find.text('小学生の部 (決勝トーナメント)'), findsOneWidget);
      expect(find.text('小学生の部 (予選リーグ)'), findsOneWidget);
    });

    testWidgets('categoryRules is emptyにおいて empty widgetが正しく描画されること', (
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

    testWidgets('フィルターとユニットが表示されコールバックが正常に実行されること', (tester) async {
      String selectedCategory = 'すべて';
      String selectedType = 'すべて';
      bool toggleAllCalled = false;
      final selectedIds = <String>['m1'];

      final units = [
        const MatchGroupUnit(
          id: 'u1',
          displayName: '1回戦: チームA vs チームB',
          matchIds: ['m1', 'm2'],
          category: '一般の部',
          resolvedType: '団体戦',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return BulkRuleTargetSelectSection(
                  categories: const ['すべて', '一般の部'],
                  matchTypes: const ['すべて', '団体戦'],
                  selectedCategoryFilter: selectedCategory,
                  selectedTypeFilter: selectedType,
                  filteredUnits: units,
                  selectedMatchIds: selectedIds,
                  primaryAccent: Colors.blue,
                  isDark: false,
                  textColor: Colors.black,
                  onCategoryChanged: (cat) {
                    setState(() => selectedCategory = cat ?? 'すべて');
                  },
                  onTypeChanged: (type) {
                    setState(() => selectedType = type ?? 'すべて');
                  },
                  onToggleUnit: (unit, checked) {
                    if (checked == true) {
                      selectedIds.addAll(unit.matchIds);
                    } else {
                      selectedIds.clear();
                    }
                  },
                  onToggleAll: () => toggleAllCalled = true,
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('STEP 1: 変更対象の試合を選択'), findsOneWidget);
      expect(find.text('カテゴリ'), findsOneWidget);
      expect(find.text('形式・種別'), findsOneWidget);
      expect(find.text('1回戦: チームA vs チームB'), findsOneWidget);
      expect(find.text('現在 0 件を選択中 / 全 1 件中'), findsOneWidget);

      await tester.tap(find.text('全選択'));
      await tester.pumpAndSettle();
      expect(toggleAllCalled, isTrue);
    });

    testWidgets(
      'ダークモード視認性保証テストにおいて ダークモード時、チェックリスト背景が白にならず、白テキストとのコントラストが保たれること',
      (tester) async {
        final units = [
          const MatchGroupUnit(
            id: 'u1',
            displayName: '1回戦: チームA vs チームB',
            matchIds: ['m1', 'm2'],
            category: '一般の部',
            resolvedType: '団体戦',
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              body: BulkRuleTargetSelectSection(
                categories: const ['すべて', '一般の部'],
                matchTypes: const ['すべて', '団体戦'],
                selectedCategoryFilter: 'すべて',
                selectedTypeFilter: 'すべて',
                filteredUnits: units,
                selectedMatchIds: const ['m1', 'm2'],
                primaryAccent: Colors.indigo,
                isDark: true,
                textColor: const Color(0xFFFFFFFF),
                onCategoryChanged: (_) {},
                onTypeChanged: (_) {},
                onToggleUnit: (_, _) {},
                onToggleAll: () {},
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 1. チェックリストのMaterial背景色が白（Color(0xFFFFFFFF)）ではないことを検証
        final materialFinder = find.descendant(
          of: find.byType(Container),
          matching: find.byType(Material),
        );
        expect(materialFinder, findsWidgets);
        final materials = tester.widgetList<Material>(materialFinder);
        for (final m in materials) {
          if (m.borderRadius == BorderRadius.circular(12) ||
              m.borderRadius == BorderRadius.circular(8)) {
            // 背景色が白でないこと
            expect(m.color, isNot(equals(const Color(0xFFFFFFFF))));
            expect(m.color, isNot(equals(Colors.white)));
          }
        }

        // 2. 試合名テキストが描画され、文字色が白（textColor）であることを検証
        final matchTitleFinder = find.text('1回戦: チームA vs チームB');
        expect(matchTitleFinder, findsOneWidget);
        final matchTitle = tester.widget<Text>(matchTitleFinder);
        expect(matchTitle.style?.color, equals(const Color(0xFFFFFFFF)));

        // 3. フィルターラベルのテキスト色が正しく反映されていること
        final categoryLabel = tester.widget<Text>(find.text('カテゴリ'));
        expect(categoryLabel.style?.color, equals(const Color(0xFFFFFFFF)));
      },
    );

    testWidgets('ライトモード視認性保証テストにおいて ライトモード時、適切な背景と文字色で描画されること', (tester) async {
      final units = [
        const MatchGroupUnit(
          id: 'u1',
          displayName: '1回戦: チームA vs チームB',
          matchIds: ['m1', 'm2'],
          category: '一般の部',
          resolvedType: '団体戦',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: BulkRuleTargetSelectSection(
              categories: const ['すべて', '一般の部'],
              matchTypes: const ['すべて', '団体戦'],
              selectedCategoryFilter: 'すべて',
              selectedTypeFilter: 'すべて',
              filteredUnits: units,
              selectedMatchIds: const ['m1', 'm2'],
              primaryAccent: Colors.indigo,
              isDark: false,
              textColor: const Color(0xFF0F172A),
              onCategoryChanged: (_) {},
              onTypeChanged: (_) {},
              onToggleUnit: (_, _) {},
              onToggleAll: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final matchTitleFinder = find.text('1回戦: チームA vs チームB');
      expect(matchTitleFinder, findsOneWidget);
      final matchTitle = tester.widget<Text>(matchTitleFinder);
      expect(matchTitle.style?.color, equals(const Color(0xFF0F172A)));
    });
  });
}
