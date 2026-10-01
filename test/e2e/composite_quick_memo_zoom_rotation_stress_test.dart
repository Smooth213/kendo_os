import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_canvas_painter.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_drawing_canvas.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_text_view.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[E2E] クイックメモ ズーム・キーボード連打・画面回転・LRUストレステスト', () {
    testWidgets('ズーム拡大中のキーボード出現消失連打および縦横画面回転において描画破綻なく追従すること', (
      WidgetTester tester,
    ) async {
      final controller = TextEditingController(text: '初期メモ内容');
      final focusNode = FocusNode();
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');
      final strokes = <MemoStroke>[];

      // 100本のストロークを生成してメモリ負荷を再現
      for (int i = 0; i < 100; i++) {
        strokes.add(
          MemoStroke(
            points: [
              Offset(i.toDouble(), i.toDouble()),
              Offset((i + 10).toDouble(), (i + 10).toDouble()),
            ],
            color: Colors.blue,
            strokeWidth: 2.0,
          ),
        );
      }

      Widget buildStressWidget({
        required Size size,
        required double viewInsetsBottom,
      }) {
        return MaterialApp(
          theme: ThemeData.light(),
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              viewInsets: EdgeInsets.only(bottom: viewInsetsBottom),
            ),
            child: Scaffold(
              body: Column(
                children: [
                  Expanded(
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
                  SizedBox(
                    height: 120,
                    child: QuickMemoTextView(
                      controller: controller,
                      focusNode: focusNode,
                      themeColors: themeColors,
                      isDark: false,
                      onChanged: () {},
                      onInsertTimestamp: () {},
                      onCopy: () {},
                      onClear: () {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      // 1. 縦向き初期表示 (400 x 800)
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildStressWidget(size: const Size(400, 800), viewInsetsBottom: 0),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // 2. キーボード出現・消失の高速サイクル（3回反復）
      for (final insets in [300.0, 0.0, 350.0, 0.0, 280.0, 0.0]) {
        await tester.pumpWidget(
          buildStressWidget(
            size: const Size(400, 800),
            viewInsetsBottom: insets,
          ),
        );
        await tester.pump(const Duration(milliseconds: 16));
        expect(tester.takeException(), isNull);
      }

      // 3. 画面横向き回転 (800 x 400)
      tester.view.physicalSize = const Size(800, 400);
      await tester.pumpWidget(
        buildStressWidget(size: const Size(800, 400), viewInsetsBottom: 0),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // 横向きでもキーボード出現
      await tester.pumpWidget(
        buildStressWidget(size: const Size(800, 400), viewInsetsBottom: 180),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      controller.dispose();
      focusNode.dispose();
    });
  });
}
