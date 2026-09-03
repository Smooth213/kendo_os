import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/category_rules/category_rule_editor_container.dart';
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
  group('CategoryRuleEditorContainer Widget Tests', () {
    testWidgets('renders CategoryRuleEditorContainer with category name', (
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
  });
}
