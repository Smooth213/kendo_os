import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_canvas_painter.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_drawing_canvas.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  group(
    '📐 QuickMemoDrawingCanvas Responsive & Resolution Integrity Tests',
    () {
      test('基準キャンバス解像度が 800 x 1000 (アスペクト比 4:5) で厳格に定義されていること', () {
        expect(QuickMemoDrawingCanvas.baseCanvasSize.width, equals(800.0));
        expect(QuickMemoDrawingCanvas.baseCanvasSize.height, equals(1000.0));
        expect(
          QuickMemoDrawingCanvas.baseCanvasSize.aspectRatio,
          closeTo(0.8, 0.001),
        );
      });

      Widget createTestWidget({
        required Size screenSize,
        required List<MemoStroke> strokes,
        List<Offset> currentPoints = const [],
      }) {
        final themeColors = AppThemeColors.ofMode(
          isDark: false,
          mode: 'normal',
        );
        return MaterialApp(
          theme: ThemeData.light(),
          home: MediaQuery(
            data: MediaQueryData(size: screenSize),
            child: Scaffold(
              body: SizedBox(
                width: screenSize.width,
                height: screenSize.height,
                child: QuickMemoDrawingCanvas(
                  strokes: strokes,
                  currentPoints: currentPoints,
                  selectedColor: Colors.black,
                  selectedWidth: 3.0,
                  isEraser: false,
                  isDark: false,
                  themeColors: themeColors,
                  onPanStart: (_) {},
                  onPanUpdate: (_) {},
                  onPanEnd: (_) {},
                  onColorChanged: (_) {},
                  onToggleWidth: () {},
                  onToggleEraser: () {},
                ),
              ),
            ),
          ),
        );
      }

      testWidgets('iPhone縦画面 (390 x 844) でもキャンバスが FittedBox により収まり描画が成功すること', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        // PCの右下(780, 980)に描いた線を含むストローク
        final strokes = [
          MemoStroke(
            points: const [Offset(750, 950), Offset(780, 980)],
            color: Colors.red,
            strokeWidth: 3.0,
          ),
        ];

        await tester.pumpWidget(
          createTestWidget(screenSize: const Size(390, 844), strokes: strokes),
        );
        await tester.pumpAndSettle();

        // FittedBox が存在し、BoxFit.contain でフィットされていること
        final fittedBoxFinder = find.byType(FittedBox);
        expect(fittedBoxFinder, findsOneWidget);
        final fittedBox = tester.widget<FittedBox>(fittedBoxFinder);
        expect(fittedBox.fit, equals(BoxFit.contain));

        // CustomPaint が描画されていること
        expect(find.byType(CustomPaint), findsWidgets);
      });

      testWidgets('PC横画面 (1600 x 900) でもキャンバスが FittedBox により収まり描画が成功すること', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(1600, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final strokes = [
          MemoStroke(
            points: const [Offset(10, 10), Offset(790, 990)],
            color: Colors.blue,
            strokeWidth: 2.0,
          ),
        ];

        await tester.pumpWidget(
          createTestWidget(screenSize: const Size(1600, 900), strokes: strokes),
        );
        await tester.pumpAndSettle();

        final fittedBoxFinder = find.byType(FittedBox);
        expect(fittedBoxFinder, findsOneWidget);
        expect(find.byType(CustomPaint), findsWidgets);
      });

      testWidgets('iPad/タブレット画面 (820 x 1180) でもアスペクト比を維持して安全にレンダリングされること', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(820, 1180);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          createTestWidget(screenSize: const Size(820, 1180), strokes: []),
        );
        await tester.pumpAndSettle();

        expect(find.byType(QuickMemoDrawingCanvas), findsOneWidget);
        expect(find.byType(FittedBox), findsOneWidget);
      });
    },
  );
}
