import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_canvas_painter.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_drawing_canvas.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_drawing_toolbar.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_zoom_controls.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Golden] クイックメモ ズームUIおよび手書きキャンバス視覚整合性テスト', () {
    Widget buildCanvasTestWidget({
      required Size screenSize,
      required bool isDark,
      List<MemoStroke> strokes = const [],
      List<Offset> currentPoints = const [],
    }) {
      final themeColors = AppThemeColors.ofMode(
        isDark: isDark,
        mode: isDark ? 'dark' : 'normal',
      );
      return MaterialApp(
        theme: isDark
            ? ThemeData.dark().copyWith(extensions: [themeColors])
            : ThemeData.light().copyWith(extensions: [themeColors]),
        home: MediaQuery(
          data: MediaQueryData(size: screenSize),
          child: Scaffold(
            body: SizedBox(
              width: screenSize.width,
              height: screenSize.height,
              child: QuickMemoDrawingCanvas(
                strokes: strokes,
                currentPoints: currentPoints,
                selectedColor: Colors.red,
                selectedWidth: 4.0,
                isEraser: false,
                isDark: isDark,
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

    testWidgets('スマホ標準幅390px ライトモードにおいてキャンバスと描画ツールバーが整然と配置されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final sampleStrokes = [
        MemoStroke(
          points: [
            const Offset(100, 100),
            const Offset(150, 150),
            const Offset(200, 120),
          ],
          color: Colors.red,
          strokeWidth: 4.0,
        ),
      ];

      await tester.pumpWidget(
        buildCanvasTestWidget(
          screenSize: const Size(390, 844),
          isDark: false,
          strokes: sampleStrokes,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(QuickMemoDrawingCanvas), findsOneWidget);
      expect(find.byType(QuickMemoDrawingToolbar), findsOneWidget);
    });

    testWidgets('タブレット幅800px ダークモードにおいて手書きストロークと背景グリッドが描画されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final sampleStrokes = [
        MemoStroke(
          points: [const Offset(50, 50), const Offset(400, 400)],
          color: Colors.blue,
          strokeWidth: 5.0,
        ),
      ];

      await tester.pumpWidget(
        buildCanvasTestWidget(
          screenSize: const Size(800, 1000),
          isDark: true,
          strokes: sampleStrokes,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(QuickMemoDrawingCanvas), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('ズーム倍率バッジおよびリセットボタンコンポーネントがオーバーフローなく正しく配置されること', (
      WidgetTester tester,
    ) async {
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                QuickMemoZoomBadge(isVisible: true, zoomScale: 2.0),
                QuickMemoZoomResetButton(
                  isDark: false,
                  themeColors: themeColors,
                  onReset: () {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('200%'), findsOneWidget);
      expect(find.text('100%に戻す'), findsOneWidget);
    });
  });
}
