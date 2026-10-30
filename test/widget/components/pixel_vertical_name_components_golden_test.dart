import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/vertical_name_text.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Golden] 選手名縦書き組版視覚ピクセル統合テスト', () {
    testWidgets('外国人複合姓や長音記号が90度回転され自然な縦書きレイアウトで描画されること', (
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

      await tester.pump();

      expect(find.byType(VerticalNameText), findsNWidgets(3));
      expect(find.byType(RotatedBox), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('長音符や記号を含む選手名が美しく縦書きレイアウトされること', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  VerticalNameText(
                    text: 'リーダー（主将）',
                    initial: 'A',
                    isDark: false,
                  ),
                  SizedBox(width: 40),
                  VerticalNameText(text: '山田太郎', initial: '', isDark: true),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(VerticalNameText), findsNWidgets(2));
      expect(find.byType(RotatedBox), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
