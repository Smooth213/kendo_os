import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_advanced_settings_section.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_advanced_tabs_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_dialogs.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_editor_bottom_bar.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('[Widget] 部門ルールエディタ 補助UIコンポーネント群 統合検証テスト', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('一括適用および部門削除のダイアログが正しく表示されること', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    CategoryRuleDialogs.showBulkApplyConfirmDialog(
                      context: context,
                      category: '一般',
                      matchCount: 5,
                    );
                  },
                  child: const Text('Open Bulk Dialog'),
                ),
                ElevatedButton(
                  onPressed: () {
                    CategoryRuleDialogs.showDeleteCategoryDialog(
                      context: context,
                      category: '一般',
                    );
                  },
                  child: const Text('Open Delete Dialog'),
                ),
              ],
            ),
          ),
        ),
      );

      // 一括適用ダイアログ
      await tester.tap(find.text('Open Bulk Dialog'));
      await tester.pumpAndSettle();
      expect(find.text('作成済みの試合に一括適用しますか？'), findsOneWidget);
      expect(find.text('一括適用する'), findsOneWidget);

      await tester.tap(find.text('適用しない（新規試合のみ）'));
      await tester.pumpAndSettle();

      // 削除ダイアログ
      await tester.tap(find.text('Open Delete Dialog'));
      await tester.pumpAndSettle();
      expect(find.text('部門を削除しますか？'), findsOneWidget);
      expect(find.text('削除'), findsOneWidget);
    });

    testWidgets('エディタボトムバーの各種ボタン描画とコールバックが正しく動作すること', (tester) async {
      bool saved = false;
      bool cancelled = false;
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            theme: ThemeData.light().copyWith(extensions: [themeColors]),
            home: Scaffold(
              body: CategoryRuleEditorBottomBar(
                enableLiquidGlass: false,
                onCancel: () => cancelled = true,
                onSave: () => saved = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('キャンセル'), findsOneWidget);
      expect(find.text('設定を保存'), findsOneWidget);

      await tester.tap(find.text('キャンセル'));
      await tester.pump();
      expect(cancelled, isTrue);

      await tester.tap(find.text('設定を保存'));
      await tester.pump();
      expect(saved, isTrue);
    });

    testWidgets('アドバンスドタブカードで通常戦・上位戦のタブが正しく描画されること', (tester) async {
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

    testWidgets('アドバンスド設定セクションで上限設定および判別キーワード欄が正しく描画されること', (tester) async {
      final controller = TextEditingController(text: '準決勝, 決勝');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CategoryRuleAdvancedSettingsSection(
                isNormal: false,
                categoryKey: '一般',
                ipponLimit: 2,
                hansokuLimit: 2,
                keywordsController: controller,
                onIpponLimitChanged: (_) {},
                onHansokuLimitChanged: (_) {},
                onKeywordsChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('詳細設定（反則ルール・上位戦設定）'), findsOneWidget);
      expect(find.text('自動判別用キーワード設定'), findsOneWidget);
      expect(find.text('準決勝以上'), findsOneWidget);
      expect(find.text('決勝のみ'), findsOneWidget);
    });
  });
}
