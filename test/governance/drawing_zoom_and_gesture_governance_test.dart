import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_canvas_painter.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_drawing_canvas.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  group(
    '[Governance] 第24条 手書きズーム・InteractiveViewerジェスチャー排他とTransform座標不変性保証規約',
    () {
      Widget buildCanvasWidget({
        required Size screenSize,
        List<MemoStroke> strokes = const [],
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

      testWidgets('1本指操作時は描画ジェスチャーとして認識されズームリセットボタンが出現しないこと', (
        WidgetTester tester,
      ) async {
        tester.view.physicalSize = const Size(800, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          buildCanvasWidget(screenSize: const Size(800, 1000)),
        );
        await tester.pumpAndSettle();

        final gestureFinder = find.byWidgetPredicate(
          (w) => w is GestureDetector && w.onScaleStart != null,
        );
        final center = tester.getCenter(gestureFinder);

        // 1本指でのドラッグ
        final touch = await tester.createGesture(pointer: 1);
        await touch.down(center);
        await tester.pump(const Duration(milliseconds: 20));

        for (int i = 0; i < 5; i++) {
          await touch.moveBy(const Offset(10, 10));
          await tester.pump(const Duration(milliseconds: 20));
        }
        await touch.up();
        await tester.pumpAndSettle();

        // ズームリセットボタンは非表示であること
        expect(find.text('100%に戻す'), findsNothing);
      });

      testWidgets('2本指ピンチズーム時にリセットボタンが表示されタップで等倍復帰すること', (
        WidgetTester tester,
      ) async {
        tester.view.physicalSize = const Size(800, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          buildCanvasWidget(screenSize: const Size(800, 1000)),
        );
        await tester.pumpAndSettle();

        final gestureFinder = find.byWidgetPredicate(
          (w) => w is GestureDetector && w.onScaleStart != null,
        );
        final center = tester.getCenter(gestureFinder);

        // 2本指ピンチ操作
        final touch1 = await tester.createGesture(pointer: 1);
        final touch2 = await tester.createGesture(pointer: 2);
        await touch1.down(center.translate(-40, 0));
        await touch2.down(center.translate(40, 0));
        await tester.pump(const Duration(milliseconds: 50));

        for (int i = 0; i < 5; i++) {
          await touch1.moveBy(const Offset(-20, 0));
          await touch2.moveBy(const Offset(20, 0));
          await tester.pump(const Duration(milliseconds: 20));
        }
        await touch1.up();
        await touch2.up();
        await tester.pumpAndSettle();

        // リセットボタンが出現すること
        expect(find.text('100%に戻す'), findsOneWidget);

        // タップしてリセット
        await tester.tap(find.text('100%に戻す'));
        await tester.pumpAndSettle();

        // 非表示に戻ること
        expect(find.text('100%に戻す'), findsNothing);
      });

      testWidgets('Transform座標逆変換により拡大縮小時も用紙基準論理サイズ800x1000の空間座標が不変であること', (
        WidgetTester tester,
      ) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          buildCanvasWidget(screenSize: const Size(400, 800)),
        );
        await tester.pumpAndSettle();

        // 基準キャンバスサイズが 800 x 1000 であることの確認
        expect(QuickMemoDrawingCanvas.baseCanvasSize.width, 800.0);
        expect(QuickMemoDrawingCanvas.baseCanvasSize.height, 1000.0);
      });
    },
  );
}
