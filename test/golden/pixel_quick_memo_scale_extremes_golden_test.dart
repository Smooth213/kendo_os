import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_canvas_painter.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_drawing_canvas.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Golden] クイック手書きメモ極小および極大スケール描画安定性テスト', () {
    testWidgets('極小スケール0.5倍および極大スケール3.0倍において描画が破綻せず正常にレイアウトされること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');
      final sampleStrokes = [
        MemoStroke(
          points: [
            const Offset(50, 50),
            const Offset(100, 100),
            const Offset(150, 75),
          ],
          color: Colors.blue,
          strokeWidth: 3.0,
        ),
      ];

      // 1. 極小スケール（0.5倍）
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(extensions: [themeColors]),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 800,
                height: 600,
                child: Transform.scale(
                  scale: 0.5,
                  child: QuickMemoDrawingCanvas(
                    strokes: sampleStrokes,
                    currentPoints: const [],
                    selectedColor: Colors.blue,
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
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(QuickMemoDrawingCanvas), findsOneWidget);
      expect(tester.takeException(), isNull);

      // 2. 極大スケール（3.0倍）
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light().copyWith(extensions: [themeColors]),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 800,
                height: 600,
                child: Transform.scale(
                  scale: 3.0,
                  child: QuickMemoDrawingCanvas(
                    strokes: sampleStrokes,
                    currentPoints: const [],
                    selectedColor: Colors.blue,
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
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(QuickMemoDrawingCanvas), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
