import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_canvas_painter.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_paper_view.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  group('[Widget] QuickMemoPaperView テスト', () {
    testWidgets('白紙時（strokes空・未ズーム）にガイダンスが表示されること', (tester) async {
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

    testWidgets('ストロークが存在する場合にガイダンスが非表示になること', (tester) async {
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
  });
}
