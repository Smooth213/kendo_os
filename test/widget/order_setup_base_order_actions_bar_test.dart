import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/order_setup/order_setup_base_order_actions_bar.dart';

void main() {
  testWidgets(
    'OrderSetupBaseOrderActionsBar triggers save and load callbacks',
    (tester) async {
      bool saved = false;
      bool loaded = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OrderSetupBaseOrderActionsBar(
              themeColors: AppThemeColors.ofMode(isDark: false, mode: 'normal'),
              isDark: false,
              canLoadBaseOrder: true,
              onSaveBaseOrder: () => saved = true,
              onLoadBaseOrder: () => loaded = true,
            ),
          ),
        ),
      );

      expect(find.text('基本オーダーに登録'), findsOneWidget);
      expect(find.text('基本オーダーを呼出'), findsOneWidget);

      await tester.tap(find.text('基本オーダーに登録'));
      expect(saved, isTrue);

      await tester.tap(find.text('基本オーダーを呼出'));
      expect(loaded, isTrue);
    },
  );
}
