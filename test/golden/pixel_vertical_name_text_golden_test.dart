import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/widgets/vertical_name_text.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Golden] 選手名縦書き表示視覚ピクセルテスト', () {
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

      await tester.pumpAndSettle();

      expect(find.byType(VerticalNameText), findsNWidgets(2));
      expect(find.byType(RotatedBox), findsWidgets); // 長音符や括弧の回転
      expect(tester.takeException(), isNull);
    });
  });
}
