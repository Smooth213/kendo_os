import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/safe_pump_helper.dart';
import 'package:kendo_os/features/match/domain/score/stroke_model.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_viewer/program_viewer_controls.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_viewer/program_viewer_drawing_toolbar.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_viewer/program_viewer_material_placeholder.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_viewer/program_viewer_media_cache.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_viewer/program_viewer_stroke_eraser.dart';
import 'package:kendo_os/features/tournament/presentation/painters/program_viewer_painters.dart';
import 'package:kendo_os/shared/domain/entities/program_model.dart'
    show ProgramModel;
import 'package:kendo_os/shared/infrastructure/persistence/models/local_stroke_model.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Widget] プログラムビュアー・描画コンポーネント統合テスト', () {
    // ----------------------------------------------------------
    // ツールボタン・ペンオプション
    // ----------------------------------------------------------
    group('ProgramViewerControls描画テスト', () {
      testWidgets('ツールボタンが表示されタップ時にコールバックが正常に実行されること', (
        WidgetTester tester,
      ) async {
        bool tapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProgramViewerToolButton(
                tool: 'pen',
                icon: Icons.edit,
                tooltip: 'ペンツール',
                isSelected: true,
                isDark: false,
                activeColor: Colors.blue,
                onTap: () => tapped = true,
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.edit), findsOneWidget);

        await tester.tap(find.byIcon(Icons.edit));
        expect(tapped, isTrue);
      });

      testWidgets('ペンオプションボタンが表示されタップ時にコールバックが正常に実行されること', (
        WidgetTester tester,
      ) async {
        bool optionTapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Row(
                children: [
                  ProgramViewerPenOption(
                    color: Colors.red,
                    label: 'レッド',
                    isSelected: true,
                    onTap: () => optionTapped = true,
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.text('レッド'), findsOneWidget);

        await tester.tap(find.text('レッド'));
        expect(optionTapped, isTrue);
      });
    });

    // ----------------------------------------------------------
    // 描画ツールバー
    // ----------------------------------------------------------
    group('ProgramViewerDrawingToolbarツールバーテスト', () {
      testWidgets('各種ツールが描画されコールバックが処理されること', (WidgetTester tester) async {
        String selectedTool = 'pen';
        Color penColor = AppKendoColors.pink;
        bool undoCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProgramViewerDrawingToolbar(
                selectedTool: selectedTool,
                activePenColor: penColor,
                activeIsShared: true,
                canUseSharedPen: true,
                isDark: false,
                onSelectTool: (tool) => selectedTool = tool,
                onSelectPenColor: (color) => penColor = color,
                onUndo: () => undoCalled = true,
                onClearAll: () {},
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.edit), findsWidgets);
        expect(find.byIcon(Icons.border_color), findsOneWidget);
        expect(find.byIcon(Icons.cleaning_services), findsOneWidget);
        expect(find.byIcon(Icons.undo), findsOneWidget);

        await tester.tap(find.byIcon(Icons.undo));
        expect(undoCalled, isTrue);
      });

      testWidgets('観客モード時に共有ペン設定が秘匿されること', (WidgetTester tester) async {
        Color selectedColor = AppKendoColors.blue;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProgramViewerDrawingToolbar(
                selectedTool: 'pen',
                activePenColor: AppKendoColors.blue,
                activeIsShared: false,
                canUseSharedPen: false,
                isDark: false,
                onSelectTool: (_) {},
                onSelectPenColor: (color) => selectedColor = color,
                onUndo: () {},
                onClearAll: () {},
              ),
            ),
          ),
        );

        await tester.tap(find.byIcon(Icons.arrow_drop_down));
        await tester.safePumpAndSettle();

        expect(find.textContaining('共有ペン'), findsNothing);
        expect(
          find.widgetWithText(ProgramViewerPenOption, 'ピンク (共有)'),
          findsNothing,
        );
        expect(
          find.widgetWithText(ProgramViewerPenOption, 'イエロー (共有)'),
          findsNothing,
        );

        expect(find.textContaining('個人ペン'), findsOneWidget);
        expect(
          find.widgetWithText(ProgramViewerPenOption, 'ブルー (個人)'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(ProgramViewerPenOption, 'ブラック (個人)'),
          findsOneWidget,
        );

        await tester.tap(
          find.widgetWithText(ProgramViewerPenOption, 'ブラック (個人)'),
        );
        await tester.safePumpAndSettle();
        expect(selectedColor, equals(AppKendoColors.pureBlack));
      });

      testWidgets('記録係モード時に共有ペン設定が表示されること', (WidgetTester tester) async {
        Color selectedColor = AppKendoColors.pink;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProgramViewerDrawingToolbar(
                selectedTool: 'pen',
                activePenColor: AppKendoColors.pink,
                activeIsShared: true,
                canUseSharedPen: true,
                isDark: false,
                onSelectTool: (_) {},
                onSelectPenColor: (color) => selectedColor = color,
                onUndo: () {},
                onClearAll: () {},
              ),
            ),
          ),
        );

        await tester.tap(find.byIcon(Icons.arrow_drop_down));
        await tester.safePumpAndSettle();

        expect(find.textContaining('共有ペン'), findsOneWidget);
        expect(
          find.widgetWithText(ProgramViewerPenOption, 'ピンク (共有)'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(ProgramViewerPenOption, 'イエロー (共有)'),
          findsOneWidget,
        );
        expect(find.textContaining('個人ペン'), findsOneWidget);
        expect(
          find.widgetWithText(ProgramViewerPenOption, 'ブルー (個人)'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(ProgramViewerPenOption, 'ブラック (個人)'),
          findsOneWidget,
        );

        await tester.tap(
          find.widgetWithText(ProgramViewerPenOption, 'イエロー (共有)'),
        );
        await tester.safePumpAndSettle();
        expect(selectedColor, equals(const Color(0xFFCA8A04)));
      });
    });

    // ----------------------------------------------------------
    // ストローク消しゴム判定
    // ----------------------------------------------------------
    group('ProgramViewerStrokeEraserストローク判定テスト', () {
      test('ProgramViewerStrokeEraser detects near strokes correctlyこと', () {
        final points = [const Offset(10.0, 10.0), const Offset(20.0, 20.0)];

        expect(
          ProgramViewerStrokeEraser.isNearStroke(
            const Offset(12.0, 12.0),
            points,
            5.0,
          ),
          isTrue,
        );
        expect(
          ProgramViewerStrokeEraser.isNearStroke(
            const Offset(50.0, 50.0),
            points,
            5.0,
          ),
          isFalse,
        );
      });

      test('ProgramViewerStrokeEraser detects local strokes correctlyこと', () {
        final xs = [10.0, 20.0];
        final ys = [10.0, 20.0];

        expect(
          ProgramViewerStrokeEraser.isNearLocalStroke(
            const Offset(12.0, 12.0),
            xs,
            ys,
            5.0,
          ),
          isTrue,
        );
        expect(
          ProgramViewerStrokeEraser.isNearLocalStroke(
            const Offset(50.0, 50.0),
            xs,
            ys,
            5.0,
          ),
          isFalse,
        );
      });
    });

    // ----------------------------------------------------------
    // プレースホルダー
    // ----------------------------------------------------------
    group('ProgramViewerMaterialPlaceholder描画テスト', () {
      testWidgets('タイトルおよびMaterial情報テキストが描画されること', (WidgetTester tester) async {
        final program = ProgramModel(
          id: 'prog1',
          tournamentId: 't1',
          title: '大会パンフレット 表紙',
          fileUrl: '',
          fileType: 'pdf',
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProgramViewerMaterialPlaceholder(
                program: program,
                isDark: false,
              ),
            ),
          ),
        );

        expect(find.text('大会パンフレット 表紙'), findsOneWidget);
        expect(find.textContaining('材料データ同期済み'), findsOneWidget);
      });
    });

    // ----------------------------------------------------------
    // メディアキャッシュ
    // ----------------------------------------------------------
    group('ProgramViewerMediaCacheメディアキャッシュテスト', () {
      test('プレースホルダー画像サイズを正しく処理すること', () async {
        final cache = ProgramViewerMediaCache();
        final size = await cache.getCachedImageSize(
          'https://placehold.co/400x600',
        );
        expect(size, const Size(400, 600));
      });

      test('空URLを正しく処理すること', () async {
        final cache = ProgramViewerMediaCache();
        final size = await cache.getCachedImageSize('');
        expect(size, const Size(400, 600));
      });
    });

    // ----------------------------------------------------------
    // ペインター
    // ----------------------------------------------------------
    group('ProgramViewerPaintersペインターテスト', () {
      testWidgets('StrokePainter paints shared and private strokesこと', (
        tester,
      ) async {
        final sharedStroke = StrokeModel(
          id: 's1',
          programId: 'p1',
          points: const [Offset(10, 10), Offset(50, 50)],
          color: Colors.red,
          strokeWidth: 4.0,
        );

        final privateStroke = LocalStrokeModel()
          ..colorValue = Colors.blue.toARGB32()
          ..strokeWidth = 4.0
          ..pointsX = [20.0, 60.0]
          ..pointsY = [20.0, 60.0];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                painter: StrokePainter(
                  sharedStrokes: [sharedStroke],
                  privateStrokes: [privateStroke],
                  currentPoints: const [Offset(30, 30), Offset(70, 70)],
                  currentLineColor: Colors.green,
                  activePenWidth: 6.0,
                ),
                size: const Size(200, 200),
              ),
            ),
          ),
        );

        expect(find.byType(CustomPaint), findsWidgets);
      });

      testWidgets('OcrHighlightPainter paints matched bounding boxこと', (
        tester,
      ) async {
        final ocrWords = [
          {
            'text': '先鋒',
            'vertices': [
              {'x': 10, 'y': 10},
              {'x': 50, 'y': 10},
              {'x': 50, 'y': 30},
              {'x': 10, 'y': 30},
            ],
          },
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                painter: OcrHighlightPainter(
                  ocrWords: ocrWords,
                  searchText: '先鋒',
                  originalImageSize: const Size(100, 100),
                ),
                size: const Size(200, 200),
              ),
            ),
          ),
        );

        expect(find.byType(CustomPaint), findsWidgets);
      });
    });
  });
}
