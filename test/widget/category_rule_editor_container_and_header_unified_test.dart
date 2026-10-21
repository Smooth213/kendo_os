import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_editor_container.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_editor_header_card.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rules_form_state.dart';
import 'package:kendo_os/shared/domain/entities/settings_model.dart';
import 'package:kendo_os/shared/domain/entities/tournament_model.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

class _MockSettingsNotifier extends SettingsNotifier {
  @override
  SettingsModel build() => const SettingsModel(enableLiquidGlass: false);
}

void main() {
  group('[Widget] CategoryRuleEditorContainerAndHeader 統合テスト', () {
    testWidgets('CategoryRuleEditorContainer with 部門 nameが正しく描画されること', (
      tester,
    ) async {
      final tournament = TournamentModel(
        id: 't-1',
        organizationId: 'org-1',
        name: 'テスト大会',
        date: DateTime(2026, 9, 3),
        venue: '武道館',
        categoryRules: {},
      );

      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');
      final formState = CategoryRulesFormState()..editingMatchType = '個人戦';
      final keywordsController = TextEditingController();
      final subtitleController = TextEditingController();
      final commentController = TextEditingController();
      bool canceled = false;
      bool saved = false;

      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsProvider.overrideWith(() => _MockSettingsNotifier()),
          ],
          child: MaterialApp(
            theme: ThemeData.light().copyWith(extensions: [themeColors]),
            home: Scaffold(
              body: CategoryRuleEditorContainer(
                tournament: tournament,
                category: '一般の部',
                themeColors: themeColors,
                enableLiquidGlass: false,
                formState: formState,
                keywordsController: keywordsController,
                subtitleController: subtitleController,
                commentController: commentController,
                onCancel: () => canceled = true,
                onSave: () => saved = true,
                setState: (fn) => fn(),
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(find.text('対象部門'), findsOneWidget);
      expect(find.text('一般の部'), findsOneWidget);
      expect(canceled, isFalse);
      expect(saved, isFalse);
    });

    testWidgets('CategoryRuleEditorHeaderCardにおいて 部門情報およびスイッチが正しく描画されること', (
      tester,
    ) async {
      final subtitleController = TextEditingController();
      final commentController = TextEditingController();

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
                subtitleController: subtitleController,
                commentController: commentController,
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
      expect(find.text('🏷️ サブタイトル（任意）'), findsOneWidget);
      expect(find.text('💬 ルールコメント・特記事項（任意）'), findsOneWidget);
      expect(find.text('試合方式'), findsOneWidget);
      expect(find.text('準決勝・決勝は別ルールにする'), findsOneWidget);
    });

    testWidgets(
      'CategoryRuleEditorHeaderCardにおいて 識別可能な場合に(2)を省略してタイトルプレビューが表示されること',
      (tester) async {
        final subtitleController = TextEditingController(text: '決勝トーナメント');
        final commentController = TextEditingController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: CategoryRuleEditorHeaderCard(
                  category: '小学生の部 (2)',
                  textColor: Colors.black,
                  matchType: '個人戦',
                  isMultiScene: false,
                  useAdvancedRule: false,
                  subtitleController: subtitleController,
                  commentController: commentController,
                  allCategoryRules: const {},
                  onMatchTypeChanged: (_) {},
                  onMultiSceneChanged: (_) {},
                  onUseAdvancedRuleChanged: (_) {},
                ),
              ),
            ),
          ),
        );

        expect(find.text('表示名プレビュー: 小学生の部 決勝トーナメント'), findsOneWidget);
        expect(find.text('連番省略中'), findsOneWidget);
      },
    );

    testWidgets('CategoryRuleEditorHeaderCardにおいて 剣道形が選択でき、コールバックが通知されること', (
      tester,
    ) async {
      final subtitleController = TextEditingController();
      final commentController = TextEditingController();
      String selectedType = '個人戦';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return SingleChildScrollView(
                  child: CategoryRuleEditorHeaderCard(
                    category: '形の部',
                    textColor: Colors.black,
                    matchType: selectedType,
                    isMultiScene: false,
                    useAdvancedRule: false,
                    subtitleController: subtitleController,
                    commentController: commentController,
                    onMatchTypeChanged: (val) {
                      setState(() {
                        selectedType = val;
                      });
                    },
                    onMultiSceneChanged: (_) {},
                    onUseAdvancedRuleChanged: (_) {},
                  ),
                );
              },
            ),
          ),
        ),
      );

      // ドロップダウンを開く
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      // 「剣道形」を選択
      await tester.tap(find.text('剣道形').last);
      await tester.pumpAndSettle();

      expect(selectedType, '剣道形');
    });
  });
}
