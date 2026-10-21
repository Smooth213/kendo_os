import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_viewer/program_viewer_material_placeholder.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_viewer/program_viewer_media_cache.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_viewer/program_viewer_page_item.dart';
import 'package:kendo_os/shared/domain/entities/program_model.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Widget] プログラムビューア ページアイテム表示およびズーム操作テスト', () {
    testWidgets('URLが空またはプレースホルダーの場合にマテリアルプレースホルダーが描画されること', (
      WidgetTester tester,
    ) async {
      final program = ProgramModel(
        id: 'prog-placeholder',
        tournamentId: 'tourney-1',
        title: '印刷用要項',
        fileUrl: '',
        fileType: 'pdf',
        createdAt: DateTime.now(),
      );

      final transformationController = TransformationController();
      final pdfViewerController = PdfViewerController();

      addTearDown(() {
        transformationController.dispose();
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ProgramViewerPageItem(
                program: program,
                index: 0,
                isDark: false,
                isDrawingMode: false,
                selectedTool: 'pen',
                activePenColor: Colors.blue,
                activeIsShared: false,
                canUseSharedPen: false,
                transformationController: transformationController,
                pdfViewerController: pdfViewerController,
                getCachedPdfBytesViaSdk: (_) async => Uint8List(0),
                mediaCache: ProgramViewerMediaCache.shared,
                initialPage: 0,
                pageCount: 1,
                onPageCountLoaded: (_) {},
                onPageChanged: (_) {},
                isZoomed: false,
                isPinching: false,
                onResetZoom: () {},
                isSearchMode: false,
                currentSearchText: '',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ProgramViewerPageItem), findsOneWidget);
      expect(find.byType(ProgramViewerMaterialPlaceholder), findsOneWidget);
      expect(find.text('印刷用要項'), findsWidgets);
    });

    testWidgets('画像プログラム表示時にInteractiveViewerが配備されダブルタップでズームリセットされること', (
      WidgetTester tester,
    ) async {
      final program = ProgramModel(
        id: 'prog-img-test',
        tournamentId: 'tourney-1',
        title: '画像要項',
        fileUrl: 'https://example.com/test_pending.png',
        fileType: 'image',
        createdAt: DateTime.now(),
      );

      final mediaCache = ProgramViewerMediaCache();
      // 未完了のFutureを設定してローディング状態（ネットワーク非接続）を保つ
      final completer = Completer<Size>();
      mediaCache.imageSizeCache['https://example.com/test_pending.png'] =
          completer.future;

      final transformationController = TransformationController();
      final pdfViewerController = PdfViewerController();
      bool resetZoomCalled = false;

      addTearDown(() {
        transformationController.dispose();
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ProgramViewerPageItem(
                program: program,
                index: 0,
                isDark: false,
                isDrawingMode: false,
                selectedTool: 'pen',
                activePenColor: Colors.blue,
                activeIsShared: false,
                canUseSharedPen: false,
                transformationController: transformationController,
                pdfViewerController: pdfViewerController,
                getCachedPdfBytesViaSdk: (_) async => Uint8List(0),
                mediaCache: mediaCache,
                initialPage: 0,
                pageCount: 1,
                onPageCountLoaded: (_) {},
                onPageChanged: (_) {},
                isZoomed: false,
                isPinching: false,
                onResetZoom: () {
                  resetZoomCalled = true;
                },
                isSearchMode: false,
                currentSearchText: '',
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      final interactiveViewerFinder = find.byType(InteractiveViewer);
      expect(interactiveViewerFinder, findsOneWidget);

      final gestureDetectorFinder = find.descendant(
        of: find.byType(ProgramViewerPageItem),
        matching: find.byType(GestureDetector),
      );
      expect(gestureDetectorFinder, findsWidgets);

      final GestureDetector gd = tester.widget(gestureDetectorFinder.first);
      gd.onDoubleTap?.call();

      expect(resetZoomCalled, isTrue);

      final InteractiveViewer iv = tester.widget(interactiveViewerFinder);
      iv.onInteractionEnd?.call(ScaleEndDetails());
    });
  });
}
