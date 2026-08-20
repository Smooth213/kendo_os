import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/order_setup/order_setup_info_banner.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/order_setup/order_setup_static_header.dart';
import 'package:kendo_os/features/tournament/presentation/operate/components/order_setup/order_setup_team_autocomplete_field.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  group('🛡️ OrderSetup Components Widget Tests', () {
    testWidgets('OrderSetupStaticHeader renders header texts and progress', (
      tester,
    ) async {
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OrderSetupStaticHeader(themeColors: themeColors),
          ),
        ),
      );

      expect(find.text('最終ステップ: オーダー編成'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('OrderSetupInfoBanner renders info text and icon', (
      tester,
    ) async {
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: OrderSetupInfoBanner(themeColors: themeColors)),
        ),
      );

      expect(
        find.text('自チームの選手を選択し、必要に応じて相手のチーム・選手名を入力してください。'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets(
      'OrderSetupTeamAutocompleteField renders text field with label and hints',
      (tester) async {
        final controller = TextEditingController();
        final focusNode = FocusNode();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: OrderSetupTeamAutocompleteField(
                controller: controller,
                focusNode: focusNode,
                suggestions: const ['洗心道場', '修道館'],
                labelText: '参加チーム名を追加',
                hintText: '入力または履歴から選択',
                fillColor: Colors.white,
                borderColor: Colors.grey,
                textColor: Colors.black,
                subTextColor: Colors.grey,
                primaryAccent: Colors.blue,
                isDark: false,
              ),
            ),
          ),
        );

        expect(find.text('参加チーム名を追加'), findsOneWidget);
        expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
      },
    );
  });
}
