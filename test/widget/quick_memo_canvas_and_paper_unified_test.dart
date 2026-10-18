import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_canvas_painter.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_drawing_canvas.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_paper_view.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  group('[Widget] クイックメモ キャンバス描画 ＆ ペーパービュー 統合検証テスト', () {
    test('基準キャンバス解像度が 800 x 1000 (アスペクト比 4:5) で厳格に定義されていること', () {
      expect(QuickMemoDrawingCanvas.baseCanvasSize.width, equals(800.0));
      expect(QuickMemoDrawingCanvas.baseCanvasSize.height, equals(1000.0));
      expect(
        QuickMemoDrawingCanvas.baseCanvasSize.aspectRatio,
        closeTo(0.8, 0.001),
      );
    });

    testWidgets('ペーパービュー: 白紙時（strokes空・未ズーム）にガイダンスが表示されること', (tester) async {
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                QuickMemoPaperView(
                  paperTopLeft: Offset.zero,
                  totalScale: 1.0,
                  baseCanvasSize: const Size(800, 1000),
                  isDark: false,
                  themeColors: themeColors,
                  strokes: const [],
                  currentPoints: const [],
                  selectedColor: Colors.black,
                  selectedWidth: 3.0,
                  isZoomed: false,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(QuickMemoPaperView), findsOneWidget);
      expect(find.byType(QuickMemoEmptyGuidance), findsOneWidget);
      expect(find.text('ここに指やペンでメモを自由に書けます'), findsOneWidget);
    });

    testWidgets('ペーパービュー: ストロークが存在する場合にガイダンスが非表示になること', (tester) async {
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                QuickMemoPaperView(
                  paperTopLeft: Offset.zero,
                  totalScale: 1.0,
                  baseCanvasSize: const Size(800, 1000),
                  isDark: false,
                  themeColors: themeColors,
                  strokes: const [
                    MemoStroke(
                      points: [Offset(10, 10), Offset(20, 20)],
                      color: Colors.black,
                      strokeWidth: 3.0,
                    ),
                  ],
                  currentPoints: const [],
                  selectedColor: Colors.black,
                  selectedWidth: 3.0,
                  isZoomed: false,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(QuickMemoPaperView), findsOneWidget);
      expect(find.byType(QuickMemoEmptyGuidance), findsNothing);
    });

    testWidgets(
      'キャンバス描画: iPhone縦画面 (390 x 844) でもキャンバスが FittedBox により収まり描画が成功すること',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final strokes = [
          MemoStroke(
            points: const [Offset(750, 950), Offset(780, 980)],
            color: Colors.red,
            strokeWidth: 3.0,
          ),
        ];
        final themeColors = AppThemeColors.ofMode(
          isDark: false,
          mode: 'normal',
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            home: Scaffold(
              body: SizedBox(
                width: 390,
                height: 844,
                child: QuickMemoDrawingCanvas(
                  strokes: strokes,
                  currentPoints: const [],
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
        await tester.pumpAndSettle();

        final fittedBoxFinder = find.byType(FittedBox);
        expect(fittedBoxFinder, findsOneWidget);
        final fittedBox = tester.widget<FittedBox>(fittedBoxFinder);
        expect(fittedBox.fit, equals(BoxFit.contain));
        expect(find.byType(CustomPaint), findsWidgets);
      },
    );

    testWidgets(
      'キャンバス描画: PC横画面 (1600 x 900) でもキャンバスが FittedBox により収まり描画が成功すること',
      (tester) async {
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
        final themeColors = AppThemeColors.ofMode(
          isDark: false,
          mode: 'normal',
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            home: Scaffold(
              body: SizedBox(
                width: 1600,
                height: 900,
                child: QuickMemoDrawingCanvas(
                  strokes: strokes,
                  currentPoints: const [],
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
        await tester.pumpAndSettle();

        final fittedBoxFinder = find.byType(FittedBox);
        expect(fittedBoxFinder, findsOneWidget);
        expect(find.byType(CustomPaint), findsWidgets);
      },
    );
  });
}
