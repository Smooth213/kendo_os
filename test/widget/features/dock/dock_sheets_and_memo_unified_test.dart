import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../helpers/safe_pump_helper.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_bottom_sheet_header.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/dock_draggable_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/manual_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_drawing_canvas.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_screen.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_storage_service.dart';
import 'package:kendo_os/features/viewer/presentation/components/viewer_settings_bottom_sheet.dart';
import 'package:kendo_os/shared/presentation/providers/settings_provider.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';
import 'package:kendo_os/shared/widgets/app_text_field.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('[Widget] DockSheetsAndMemo 統合テスト', () {
    testWidgets('DockBottomSheetHeader がタイトル、アイコン、全画面ボタンを表示すること', (
      tester,
    ) async {
      bool fullScreenTapped = false;
      bool closeTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DockBottomSheetHeader(
              title: 'テスト機能',
              icon: Icons.star_rounded,
              onFullScreen: () => fullScreenTapped = true,
              onClose: () => closeTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('テスト機能'), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
      expect(find.byIcon(Icons.open_in_full_rounded), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.open_in_full_rounded));
      expect(fullScreenTapped, isTrue);

      await tester.tap(find.byIcon(Icons.close_rounded));
      expect(closeTapped, isTrue);
    });

    testWidgets('QuickMemoBottomSheet がボトムシートとして起動し、全画面ボタンが表示されること', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: QuickMemoBottomSheet(tournamentId: 'test_t1')),
          ),
        ),
      );
      await tester.safePumpAndSettle();

      expect(find.text('クイックメモ'), findsOneWidget);
      expect(find.byIcon(Icons.brush_rounded), findsWidgets);
      expect(find.byIcon(Icons.open_in_full_rounded), findsOneWidget);
      expect(find.text('手書きメモ'), findsOneWidget);
      expect(find.text('テキストメモ'), findsOneWidget);
    });

    testWidgets('ManualBottomSheet がボトムシートとして起動し、マニュアルタイトルと全画面ボタンが表示されること', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: ManualBottomSheet(isViewerMode: false)),
          ),
        ),
      );
      await tester.safePumpAndSettle();

      expect(find.text('操作マニュアル・ヘルプ'), findsOneWidget);
      expect(find.byIcon(Icons.open_in_full_rounded), findsWidgets);
    });

    testWidgets('ViewerSettingsBottomSheet が表示設定とテーマ切り替えを表示すること', (
      tester,
    ) async {
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: const MaterialApp(
            home: Scaffold(body: ViewerSettingsBottomSheet()),
          ),
        ),
      );
      await tester.safePumpAndSettle();

      expect(find.text('表示設定'), findsOneWidget);
      expect(find.text('テーマの切り替え'), findsOneWidget);
    });

    testWidgets('DockDraggableSheet の拡大ボタンをタップすると全開になり、再タップで半分に戻ること', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DockDraggableSheet(
              initialChildSize: 0.58,
              maxChildSize: 0.95,
              builder: (context, controller) => Column(
                children: [
                  DockBottomSheetHeader(
                    title: '伸縮テスト',
                    icon: Icons.info_outline,
                    onFullScreen: () {},
                  ),
                  const Expanded(child: Text('コンテンツ')),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.safePumpAndSettle();

      expect(find.byIcon(Icons.expand_less_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.expand_less_rounded));
      await tester.safePumpAndSettle();

      expect(find.byIcon(Icons.expand_more_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.expand_more_rounded));
      await tester.safePumpAndSettle();

      expect(find.byIcon(Icons.expand_less_rounded), findsOneWidget);
    });

    testWidgets('DockDraggableSheet を上にドラッグすると全開へスムーズに拡大すること', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DockDraggableSheet(
              initialChildSize: 0.58,
              maxChildSize: 0.95,
              builder: (context, controller) => Column(
                children: [
                  DockBottomSheetHeader(
                    title: 'ドラッグテスト',
                    icon: Icons.touch_app,
                    onFullScreen: () {},
                  ),
                  const Expanded(child: Text('コンテンツ')),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.safePumpAndSettle();

      expect(find.byIcon(Icons.expand_less_rounded), findsOneWidget);

      await tester.drag(find.text('ドラッグテスト'), const Offset(0, -300));
      await tester.safePumpAndSettle();

      expect(find.byIcon(Icons.expand_more_rounded), findsOneWidget);
    });

    testWidgets('クイックメモにおいてズーム操作やテキスト入力および全画面遷移時に状態が保持されること', (tester) async {
      const testTournamentId = 'e2e_quick_memo_tournament_001';

      Widget buildTestApp({
        required Widget child,
        double viewInsetsBottom = 0,
      }) {
        return MaterialApp(
          theme: ThemeData(
            extensions: [AppThemeColors.ofMode(isDark: false, mode: 'normal')],
          ),
          home: MediaQuery(
            data: MediaQueryData(
              size: const Size(600, 900),
              viewInsets: EdgeInsets.only(bottom: viewInsetsBottom),
              padding: const EdgeInsets.only(bottom: 20),
            ),
            child: Scaffold(resizeToAvoidBottomInset: false, body: child),
          ),
        );
      }

      await tester.pumpWidget(
        buildTestApp(
          child: const QuickMemoBottomSheet(tournamentId: testTournamentId),
        ),
      );
      await tester.safePumpAndSettle();

      expect(find.text('クイックメモ'), findsOneWidget);
      expect(find.byType(QuickMemoDrawingCanvas), findsOneWidget);

      final initialScope = tester.widget<DockSheetScope>(
        find.byType(DockSheetScope),
      );
      expect(initialScope.isExpanded, isFalse);

      final canvasGestureFinder = find.byWidgetPredicate(
        (w) => w is GestureDetector && w.onScaleStart != null,
      );
      final center = tester.getCenter(canvasGestureFinder);

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

      expect(find.text('100%に戻す'), findsOneWidget);

      for (int i = 0; i < 5; i++) {
        await touch1.moveBy(const Offset(10, 10));
        await touch2.moveBy(const Offset(10, 10));
        await tester.pump(const Duration(milliseconds: 20));
      }

      await touch1.up();
      await touch2.up();
      await tester.safePumpAndSettle();

      final drawTouch = await tester.startGesture(center);
      await tester.pump();
      await drawTouch.moveBy(const Offset(50, 50));
      await tester.pump();
      await drawTouch.up();
      await tester.safePumpAndSettle();

      final savedMemo = await QuickMemoStorageService.instance.loadMemo(
        testTournamentId,
      );
      expect(savedMemo.strokes.isNotEmpty, isTrue);

      await tester.tap(find.text('テキストメモ'));
      await tester.safePumpAndSettle();

      await tester.pumpWidget(
        buildTestApp(
          viewInsetsBottom: 280,
          child: const QuickMemoBottomSheet(tournamentId: testTournamentId),
        ),
      );
      await tester.pump();
      await tester.safePumpAndSettle();

      final expandedScope = tester.widget<DockSheetScope>(
        find.byType(DockSheetScope),
      );
      expect(expandedScope.isExpanded, isTrue);

      final textFieldFinder = find.byType(AppTextField);
      expect(textFieldFinder, findsOneWidget);
      await tester.enterText(textFieldFinder, 'E2Eテスト実証用メモ内容テキスト');
      await tester.safePumpAndSettle();

      await tester.pumpWidget(
        buildTestApp(
          child: const QuickMemoScreen(tournamentId: testTournamentId),
        ),
      );
      await tester.safePumpAndSettle();

      expect(find.text('E2Eテスト実証用メモ内容テキスト'), findsOneWidget);

      await tester.tap(find.text('手書きメモ'));
      await tester.safePumpAndSettle();

      expect(find.byType(QuickMemoDrawingCanvas), findsOneWidget);
      final fullScreenCanvas = tester.widget<QuickMemoDrawingCanvas>(
        find.byType(QuickMemoDrawingCanvas),
      );
      expect(fullScreenCanvas.strokes.isNotEmpty, isTrue);
    });
  });
}
