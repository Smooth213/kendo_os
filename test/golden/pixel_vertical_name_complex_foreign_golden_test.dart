import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/vertical_name_text.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Golden] 外国人複合姓および長音記号縦書き組版視覚ピクセルテスト', () {
    testWidgets('ハイフンや長音符を含む外国人複合姓が90度回転され自然な縦書きレイアウトで描画されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(extensions: [themeColors]),
          home: const Scaffold(
            body: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  VerticalNameText(
                    text: 'Saint-Exupéry',
                    initial: 'A',
                    isDark: false,
                  ),
                  SizedBox(width: 32),
                  VerticalNameText(
                    text: 'Van-Der-Bellen',
                    initial: '',
                    isDark: false,
                  ),
                  SizedBox(width: 32),
                  VerticalNameText(
                    text: 'アンダーソン（大将）',
                    initial: 'C',
                    isDark: false,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(VerticalNameText), findsNWidgets(3));
      // ハイフン、長音記号、括弧の回転ウィジェットが存在すること
      expect(find.byType(RotatedBox), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
