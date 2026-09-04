import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/program_bottom_sheet.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/program_stroke_layer.dart';
import 'package:kendo_os/features/tournament/presentation/operate/providers/program_list_provider.dart';
import 'package:kendo_os/shared/domain/entities/program_model.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final dummyPrograms = [
    ProgramModel(
      id: 'prog_1',
      tournamentId: 'tour_123',
      title: '進行表_1日目',
      fileUrl: 'https://example.com/prog1.png',
      fileType: 'image',
      pageCount: 1,
      createdAt: DateTime(2026, 9, 1),
    ),
    ProgramModel(
      id: 'prog_2',
      tournamentId: 'tour_123',
      title: 'トーナメント表_女子',
      fileUrl: 'https://example.com/prog2.jpg',
      fileType: 'image',
      pageCount: 1,
      createdAt: DateTime(2026, 9, 2),
    ),
  ];

  Widget createTestWidget({
    required List<ProgramModel> programs,
    bool isViewerMode = false,
    bool isDark = false,
  }) {
    final themeColors = AppThemeColors.ofMode(isDark: isDark, mode: 'normal');
    return ProviderScope(
      overrides: [
        programListProvider(
          'tour_123',
        ).overrideWith((ref) => Stream.value(programs)),
      ],
      child: MaterialApp(
        theme: (isDark ? ThemeData.dark() : ThemeData.light()).copyWith(
          extensions: [themeColors],
        ),
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    ProgramBottomSheet.show(
                      context,
                      tournamentId: 'tour_123',
                      isViewerMode: isViewerMode,
                    );
                  },
                  child: const Text('Open Sheet'),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  group('🥋 ProgramBottomSheet ウィジェットテスト', () {
    testWidgets('プログラム未登録時に空メッセージが表示されること', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(programs: []));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('プログラム（進行表・トーナメント表）を登録してください'), findsOneWidget);
    });

    testWidgets('複数プログラム登録時にチップで切り替えができること', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(programs: dummyPrograms));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('進行表_1日目'), findsWidgets);
      expect(find.text('トーナメント表_女子'), findsOneWidget);

      // 2つ目のチップをタップして切り替え
      await tester.tap(find.text('トーナメント表_女子'));
      await tester.pumpAndSettle();

      expect(find.byType(InteractiveViewer), findsOneWidget);
    });

    testWidgets('閉じるボタンをタップするとシートが閉じること', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(programs: dummyPrograms));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.byType(ProgramBottomSheet), findsOneWidget);

      // 閉じるボタンをタップ
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(ProgramBottomSheet), findsNothing);
    });

    testWidgets('右下の「プログラム管理」ボタンが削除され、ヘッダーにペン編集ボタンが存在すること', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestWidget(programs: dummyPrograms, isViewerMode: false),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // 右下の「プログラム管理」ボタンは削除されていること
      expect(find.text('プログラム管理'), findsNothing);

      // ヘッダーにペン編集ボタン（brush）が存在すること
      expect(find.byIcon(Icons.brush_rounded), findsOneWidget);
    });

    testWidgets('観客モード（isViewerMode=true）でもペン編集ボタンが表示されること', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestWidget(programs: dummyPrograms, isViewerMode: true),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // 観客モードでも個人メモ用にペン編集ボタンが存在すること
      expect(find.byIcon(Icons.brush_rounded), findsOneWidget);
    });

    testWidgets('画像プログラム表示時に手書きペン層（ProgramStrokeLayer）が配置されていること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(programs: dummyPrograms));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // ProgramStrokeLayer が描画ツリーに配置されていること
      expect(find.byType(ProgramStrokeLayer), findsOneWidget);
    });

    testWidgets('ヘッダーに全画面拡大ボタン（open_in_full）が存在すること', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(programs: dummyPrograms));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // 全画面ボタンが存在すること
      expect(find.byIcon(Icons.open_in_full_rounded), findsOneWidget);
    });

    testWidgets('PDFプログラム（fileType: pdf）表示時にも ProgramStrokeLayer が配置されること', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final pdfPrograms = [
        ProgramModel(
          id: 'prog_pdf_1',
          tournamentId: 'tour_123',
          title: 'トーナメント表_PDF',
          fileUrl: 'https://example.com/tournament.pdf',
          fileType: 'pdf',
          pageCount: 1,
          createdAt: DateTime(2026, 9, 3),
        ),
      ];

      await tester.pumpWidget(createTestWidget(programs: pdfPrograms));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // PDF の場合も ProgramStrokeLayer が重畳配置されていること
      expect(find.byType(ProgramStrokeLayer), findsOneWidget);
    });

    testWidgets('InteractiveViewer により拡大縮小（ズーム）が有効であること', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(programs: dummyPrograms));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      final interactiveFinder = find.byType(InteractiveViewer);
      expect(interactiveFinder, findsOneWidget);

      final interactive = tester.widget<InteractiveViewer>(interactiveFinder);
      expect(interactive.maxScale, 4.0);
      expect(interactive.minScale, 0.8);
    });
  });
}
