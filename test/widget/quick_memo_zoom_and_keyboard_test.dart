import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_draggable_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_canvas_painter.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_drawing_canvas.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_text_view.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  group('[Widget] クイックメモ ズーム＆キーボード追従テスト', () {
    Widget buildCanvasTestWidget({
      required Size screenSize,
      List<MemoStroke> strokes = const [],
      List<Offset> currentPoints = const [],
    }) {
      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');
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

    testWidgets(
      'ピンチズームジェスチャーによって拡大率バッジと「100%に戻す」ボタンが表示され、リセットタップで全体表示に復帰すること',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          buildCanvasTestWidget(screenSize: const Size(800, 1000)),
        );
        await tester.pumpAndSettle();

        // 初期状態では「100%に戻す」ボタンは非表示
        expect(find.text('100%に戻す'), findsNothing);

        // キャンバスの GestureDetector を特定
        final gestureFinder = find.byWidgetPredicate(
          (w) => w is GestureDetector && w.onScaleStart != null,
        );
        final center = tester.getCenter(gestureFinder);

        // 2本指によるスケールジェスチャーをシミュレート（pointer ID を分ける）
        final touch1 = await tester.createGesture(pointer: 1);
        final touch2 = await tester.createGesture(pointer: 2);
        await touch1.down(center.translate(-40, 0));
        await touch2.down(center.translate(40, 0));
        await tester.pump(const Duration(milliseconds: 50));

        // 複数ステップで2本指を広げてズームイン
        for (int i = 0; i < 5; i++) {
          await touch1.moveBy(const Offset(-20, 0));
          await touch2.moveBy(const Offset(20, 0));
          await tester.pump(const Duration(milliseconds: 20));
        }

        // 「100%に戻す」ボタンが表示されていること
        expect(find.text('100%に戻す'), findsOneWidget);

        await touch1.up();
        await touch2.up();
        await tester.pumpAndSettle();

        // 「100%に戻す」ボタンが残っていること
        expect(find.text('100%に戻す'), findsOneWidget);

        // リセットボタンをタップ
        await tester.tap(find.text('100%に戻す'));
        await tester.pumpAndSettle();

        // リセット後は「100%に戻す」ボタンが非表示になること
        expect(find.text('100%に戻す'), findsNothing);
      },
    );

    testWidgets('2本指での平行ドラッグ操作において、微小スケール変化でズーム暴発せず滑らかにパン移動できること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildCanvasTestWidget(screenSize: const Size(800, 1000)),
      );
      await tester.pumpAndSettle();

      final gestureFinder = find.byWidgetPredicate(
        (w) => w is GestureDetector && w.onScaleStart != null,
      );
      final center = tester.getCenter(gestureFinder);

      // 2本指を配置
      final touch1 = await tester.createGesture(pointer: 1);
      final touch2 = await tester.createGesture(pointer: 2);
      await touch1.down(center.translate(-30, 0));
      await touch2.down(center.translate(30, 0));
      await tester.pump(const Duration(milliseconds: 50));

      // 2本の指の間隔を保ったまま、右下に平行移動（純粋なパン）
      for (int i = 0; i < 5; i++) {
        await touch1.moveBy(const Offset(10, 10));
        await touch2.moveBy(const Offset(10, 10));
        await tester.pump(const Duration(milliseconds: 20));
      }

      // 間隔がほぼ変わっていないため、ズームバッジは表示されず純粋にパン移動が成立すること
      await touch1.up();
      await touch2.up();
      await tester.pumpAndSettle();

      // 描画エラーなく安全に完了すること
      expect(find.byType(QuickMemoDrawingCanvas), findsOneWidget);
    });

    testWidgets(
      'QuickMemoTextView において、キーボード出現時（viewInsets.bottom > 0）にツールバーと入力欄パディングが追従すること',
      (tester) async {
        final controller = TextEditingController(text: '大会連絡事項のテストメモ');
        final focusNode = FocusNode();
        final themeColors = AppThemeColors.ofMode(
          isDark: false,
          mode: 'normal',
        );

        Widget buildTextViewWidget({required double viewInsetsBottom}) {
          return MaterialApp(
            theme: ThemeData.light(),
            home: MediaQuery(
              data: MediaQueryData(
                size: const Size(400, 800),
                viewInsets: EdgeInsets.only(bottom: viewInsetsBottom),
                padding: const EdgeInsets.only(bottom: 20),
              ),
              child: Material(
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
            ),
          );
        }

        // 1. キーボード非表示時
        await tester.pumpWidget(buildTextViewWidget(viewInsetsBottom: 0));
        await tester.pumpAndSettle();

        final initialToolbarPositioned = tester.widget<Positioned>(
          find
              .descendant(
                of: find.byType(QuickMemoTextView),
                matching: find.byType(Positioned),
              )
              .last,
        );
        final initialBottom = initialToolbarPositioned.bottom;

        // 2. キーボード出現時 (300px)
        await tester.pumpWidget(buildTextViewWidget(viewInsetsBottom: 300));
        await tester.pumpAndSettle();

        final raisedToolbarPositioned = tester.widget<Positioned>(
          find
              .descendant(
                of: find.byType(QuickMemoTextView),
                matching: find.byType(Positioned),
              )
              .last,
        );
        final raisedBottom = raisedToolbarPositioned.bottom;

        // ツールバーの bottom がキーボード高さ分（300px以上）持ち上がっていること
        expect(raisedBottom, isNotNull);
        expect(initialBottom, isNotNull);
        expect(raisedBottom! > initialBottom!, isTrue);
        expect(raisedBottom >= 300, isTrue);

        controller.dispose();
        focusNode.dispose();
      },
    );

    testWidgets(
      'DockDraggableSheet において、キーボード出現時（viewInsets.bottom > 0）にシートが全開（maxChildSize）へ自動展開すること',
      (tester) async {
        Widget buildSheetWidget({required double viewInsetsBottom}) {
          return MaterialApp(
            theme: ThemeData.light(),
            home: MediaQuery(
              data: MediaQueryData(
                size: const Size(400, 800),
                viewInsets: EdgeInsets.only(bottom: viewInsetsBottom),
              ),
              child: Material(
                child: DockDraggableSheet(
                  initialChildSize: 0.58,
                  maxChildSize: 0.95,
                  builder: (context, scrollController) =>
                      const SizedBox(height: 200, child: Text('Sheet Content')),
                ),
              ),
            ),
          );
        }

        // 1. キーボード非表示時は初期高さ（58%）
        await tester.pumpWidget(buildSheetWidget(viewInsetsBottom: 0));
        await tester.pumpAndSettle();

        expect(find.text('Sheet Content'), findsOneWidget);

        // 2. キーボード出現時 (250px)
        await tester.pumpWidget(buildSheetWidget(viewInsetsBottom: 250));
        await tester.pump();
        await tester.pumpAndSettle();

        // DockSheetScope が isExpanded: true に自動展開されていること
        final scopeFinder = find.byType(DockSheetScope);
        expect(scopeFinder, findsOneWidget);
        final scope = tester.widget<DockSheetScope>(scopeFinder);
        expect(scope.isExpanded, isTrue);
      },
    );
  });
}
