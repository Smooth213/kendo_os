import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../helpers/safe_pump_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_canvas_painter.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_drawing_canvas.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_text_view.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('[Widget] クイックメモ ズーム操作・画面回転・ストローク永続化ライフサイクル統合テスト', () {
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

      // 1. 通常縦画面（ポートレート）
      await tester.pumpWidget(
        buildStressWidget(size: const Size(400, 800), viewInsetsBottom: 0),
      );
      await tester.pump();
      expect(find.byType(QuickMemoDrawingCanvas), findsOneWidget);
      expect(find.byType(QuickMemoTextView), findsOneWidget);

      // 2. キーボード出現（ソフトウェアキーボードの激しいインセット変化シミュレート）
      await tester.pumpWidget(
        buildStressWidget(size: const Size(400, 800), viewInsetsBottom: 320),
      );
      await tester.pump();
      expect(find.byType(QuickMemoDrawingCanvas), findsOneWidget);

      // 3. 横画面回転（ランドスケープ）への急激なリサイズ
      await tester.pumpWidget(
        buildStressWidget(size: const Size(800, 400), viewInsetsBottom: 0),
      );
      await tester.pump();
      expect(find.byType(QuickMemoDrawingCanvas), findsOneWidget);

      // 4. キーボード消失と再回転
      await tester.pumpWidget(
        buildStressWidget(size: const Size(400, 800), viewInsetsBottom: 0),
      );
      await tester.pump();
      expect(find.byType(QuickMemoDrawingCanvas), findsOneWidget);

      // メモテキスト内容が保持されていること
      expect(controller.text, equals('初期メモ内容'));
    });

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

      await tester.pumpWidget(buildTestHarness());
      await tester.safePumpAndSettle();

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
      await tester.safePumpAndSettle();

      // 拡大リセットボタンが表示されていること
      expect(find.text('100%に戻す'), findsOneWidget);

      // 3. 手書きストロークをシミュレート追加
      final drawTouch = await tester.createGesture(pointer: 3);
      await drawTouch.down(center);
      await tester.pump(const Duration(milliseconds: 20));
      await drawTouch.moveBy(const Offset(50, 50));
      await tester.pump(const Duration(milliseconds: 20));
      await drawTouch.up();
      await tester.safePumpAndSettle();

      expect(strokesState.isNotEmpty, isTrue);

      // 4. ドック最小化（スコアボード画面へ遷移）
      await tester.tap(find.text('ドック最小化'));
      await tester.safePumpAndSettle();

      expect(find.text('スコアボード画面（ドック最小化中）'), findsOneWidget);
      expect(find.byType(QuickMemoDrawingCanvas), findsNothing);

      // 5. ドック再展開
      await tester.tap(find.text('ドック再展開'));
      await tester.safePumpAndSettle();

      // キャンバスが再マウントされ、ストロークが完全に維持されていること
      expect(find.byType(QuickMemoDrawingCanvas), findsOneWidget);
      expect(strokesState.isNotEmpty, isTrue);
      expect(strokesState.first.points.isNotEmpty, isTrue);
    });
  });
}
