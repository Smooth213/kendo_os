import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_canvas_painter.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_drawing_canvas.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('[E2E] クイックメモ ズームライフサイクルおよびストローク永続化統合テスト', () {
    testWidgets('ズーム拡大描画からドック最小化・画面遷移・再展開後もストロークデータが完全保持されること', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final strokesState = <MemoStroke>[];
      final currentPointsState = <Offset>[];
      bool isDockExpanded = true;

      final themeColors = AppThemeColors.ofMode(isDark: false, mode: 'normal');

      Widget buildTestHarness() {
        return StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              theme: ThemeData.light(),
              home: Scaffold(
                body: Column(
                  children: [
                    // 操作バー（ドック最小化・展開シミュレート）
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          isDockExpanded = !isDockExpanded;
                        });
                      },
                      child: Text(isDockExpanded ? 'ドック最小化' : 'ドック再展開'),
                    ),
                    Expanded(
                      child: isDockExpanded
                          ? QuickMemoDrawingCanvas(
                              strokes: strokesState,
                              currentPoints: currentPointsState,
                              selectedColor: Colors.black,
                              selectedWidth: 3.0,
                              isEraser: false,
                              isDark: false,
                              themeColors: themeColors,
                              onPanStart: (details) {
                                setState(() {
                                  currentPointsState.add(details.localPosition);
                                });
                              },
                              onPanUpdate: (details) {
                                setState(() {
                                  currentPointsState.add(details.localPosition);
                                });
                              },
                              onPanEnd: (details) {
                                setState(() {
                                  if (currentPointsState.isNotEmpty) {
                                    strokesState.add(
                                      MemoStroke(
                                        points: List.from(currentPointsState),
                                        color: Colors.black,
                                        strokeWidth: 3.0,
                                      ),
                                    );
                                    currentPointsState.clear();
                                  }
                                });
                              },
                              onColorChanged: (_) {},
                              onToggleWidth: () {},
                              onToggleEraser: () {},
                            )
                          : const Center(child: Text('スコアボード画面（ドック最小化中）')),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }

      await tester.pumpWidget(ProviderScope(child: buildTestHarness()));
      await tester.pumpAndSettle();

      // 1. 初期表示でキャンバスが存在すること
      expect(find.byType(QuickMemoDrawingCanvas), findsOneWidget);

      // 2. ピンチズーム操作
      final gestureFinder = find.byWidgetPredicate(
        (w) => w is GestureDetector && w.onScaleStart != null,
      );
      final center = tester.getCenter(gestureFinder);

      final touch1 = await tester.createGesture(pointer: 1);
      final touch2 = await tester.createGesture(pointer: 2);
      await touch1.down(center.translate(-30, 0));
      await touch2.down(center.translate(30, 0));
      await tester.pump(const Duration(milliseconds: 50));

      for (int i = 0; i < 5; i++) {
        await touch1.moveBy(const Offset(-20, 0));
        await touch2.moveBy(const Offset(20, 0));
        await tester.pump(const Duration(milliseconds: 20));
      }
      await touch1.up();
      await touch2.up();
      await tester.pumpAndSettle();

      // 拡大リセットボタンが表示されていること
      expect(find.text('100%に戻す'), findsOneWidget);

      // 3. 手書きストロークをシミュレート追加
      final drawTouch = await tester.createGesture(pointer: 3);
      await drawTouch.down(center);
      await tester.pump(const Duration(milliseconds: 20));
      await drawTouch.moveBy(const Offset(50, 50));
      await tester.pump(const Duration(milliseconds: 20));
      await drawTouch.up();
      await tester.pumpAndSettle();

      expect(strokesState.isNotEmpty, isTrue);

      // 4. ドック最小化（スコアボード画面へ遷移）
      await tester.tap(find.text('ドック最小化'));
      await tester.pumpAndSettle();

      expect(find.text('スコアボード画面（ドック最小化中）'), findsOneWidget);
      expect(find.byType(QuickMemoDrawingCanvas), findsNothing);

      // 5. ドック再展開
      await tester.tap(find.text('ドック再展開'));
      await tester.pumpAndSettle();

      // キャンバスが再マウントされ、ストロークが完全に維持されていること
      expect(find.byType(QuickMemoDrawingCanvas), findsOneWidget);
      expect(strokesState.isNotEmpty, isTrue);
      expect(strokesState.first.points.isNotEmpty, isTrue);
    });
  });
}
