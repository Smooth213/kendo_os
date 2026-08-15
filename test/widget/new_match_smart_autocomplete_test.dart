import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/new_match/new_match_smart_autocomplete.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  group('🛡️ NewMatchSmartAutocomplete Widget Tests', () {
    testWidgets('Renders text field with label and icons', (
      WidgetTester tester,
    ) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [themeColors]),
          home: Scaffold(
            body: NewMatchSmartAutocomplete(
              controller: controller,
              focusNode: focusNode,
              suggestions: const ['山田', '佐藤', '田中'],
              labelText: '赤の選手名',
              isDark: false,
            ),
          ),
        ),
      );

      expect(find.text('赤の選手名'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
    });

    testWidgets('Shows suggestions on tap and selects an item', (
      WidgetTester tester,
    ) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [themeColors]),
          home: Scaffold(
            body: NewMatchSmartAutocomplete(
              controller: controller,
              focusNode: focusNode,
              suggestions: const ['山田', '佐藤', '田中'],
              labelText: '赤の選手名',
              isDark: false,
            ),
          ),
        ),
      );

      // タップしてサジェストリストを表示
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      expect(find.text('山田'), findsOneWidget);
      expect(find.text('佐藤'), findsOneWidget);
      expect(find.text('田中'), findsOneWidget);

      // 「山田」を選択
      await tester.tap(find.text('山田'));
      await tester.pumpAndSettle();

      expect(controller.text, '山田');
    });
  });
}
