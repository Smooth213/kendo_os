import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/admin/presentation/components/master_register_organization_bottom_sheet.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Golden] マスター組織登録ボトムシート視覚ピクセルテスト', () {
    testWidgets('ライトモードで組織登録シートが美しく描画されオーバーフローがないこと', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData(
              extensions: [
                AppThemeColors.ofMode(isDark: false, mode: 'normal'),
              ],
            ),
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  return Center(
                    child: ElevatedButton(
                      onPressed: () =>
                          MasterRegisterOrganizationBottomSheet.show(
                            context,
                            ref,
                          ),
                      child: const Text('開く'),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('開く'));
      await tester.pumpAndSettle();

      expect(find.text('道場名・学校名の登録'), findsOneWidget);
      expect(find.text('登録'), findsOneWidget);
      expect(find.text('キャンセル'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ダークモードで組織登録シートが美しく描画されオーバーフローがないこと', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData.dark().copyWith(
              extensions: [AppThemeColors.ofMode(isDark: true, mode: 'normal')],
            ),
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  return Center(
                    child: ElevatedButton(
                      onPressed: () =>
                          MasterRegisterOrganizationBottomSheet.show(
                            context,
                            ref,
                          ),
                      child: const Text('開く'),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('開く'));
      await tester.pumpAndSettle();

      expect(find.text('道場名・学校名の登録'), findsOneWidget);
      expect(find.text('選手を追加する前に、道場名または学校名を入力してください。'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
