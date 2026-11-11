import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/dojo_security_form_widgets.dart';
import '../../helpers/safe_pump_helper.dart';

void main() {
  group('[Widget] DojoSecurityFormWidgets 共通コンポーネントテスト', () {
    testWidgets('DojoSecurityField と Banner / Card がカプセル形状・メッセージを表示すること', (
      tester,
    ) async {
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(extensions: [themeColors]),
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  DojoSecurityTargetBanner(
                    themeColors: themeColors,
                    dojoId: 'dojo_shared',
                    message: 'テスト案内メッセージ',
                  ),
                  DojoSecuritySectionCard(
                    themeColors: themeColors,
                    title: 'カード見出し',
                    child: DojoSecurityField(
                      themeColors: themeColors,
                      controller: controller,
                      label: 'PIN入力ラベル',
                      hint: '4桁数字',
                      prefixIcon: Icons.lock_outline,
                    ),
                  ),
                  const DojoSecurityErrorBanner(message: 'エラー通知テスト'),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.safePumpAndSettle();

      expect(find.text('対象道場: dojo_shared'), findsOneWidget);
      expect(find.text('テスト案内メッセージ'), findsOneWidget);
      expect(find.text('カード見出し'), findsOneWidget);
      expect(find.text('PIN入力ラベル'), findsOneWidget);
      expect(find.text('エラー通知テスト'), findsOneWidget);

      final field = tester.widget<TextField>(find.byType(TextField));
      final border = field.decoration?.enabledBorder as OutlineInputBorder?;
      expect(border?.borderRadius, AppRadius.capsule);
    });
  });
}
