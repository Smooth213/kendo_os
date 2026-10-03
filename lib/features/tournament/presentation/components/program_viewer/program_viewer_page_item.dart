import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_viewer/program_viewer_canvas_overlay.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_viewer/program_viewer_image_body.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_viewer/program_viewer_material_placeholder.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_viewer/program_viewer_media_cache.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_viewer/program_viewer_pdf_body.dart';
import 'package:kendo_os/shared/domain/entities/program_model.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

/// 🥋 プログラムビューア 単一ページ表示コンポーネント
class ProgramViewerPageItem extends StatelessWidget {
  final ProgramModel program;
  final int index;
  final bool isDark;
  final bool isDrawingMode;
  final String selectedTool;
  final Color activePenColor;
  final bool activeIsShared;
  final bool canUseSharedPen;
  final TransformationController transformationController;
  final PdfViewerController pdfViewerController;
  final Future<Uint8List> Function(String url) getCachedPdfBytesViaSdk;
  final ProgramViewerMediaCache mediaCache;
  final int initialPage;
  final int pageCount;
  final ValueChanged<int> onPageCountLoaded;
  final ValueChanged<int> onPageChanged;
  final bool isZoomed;
  final bool isPinching;
  final VoidCallback onResetZoom;
  final bool isSearchMode;
  final String currentSearchText;

  const ProgramViewerPageItem({
    super.key,
    required this.program,
    required this.index,
    required this.isDark,
    required this.isDrawingMode,
    required this.selectedTool,
    required this.activePenColor,
    required this.activeIsShared,
    required this.canUseSharedPen,
    required this.transformationController,
    required this.pdfViewerController,
    required this.getCachedPdfBytesViaSdk,
    required this.mediaCache,
    required this.initialPage,
    required this.pageCount,
    required this.onPageCountLoaded,
    required this.onPageChanged,
    required this.isZoomed,
    required this.isPinching,
    required this.onResetZoom,
    required this.isSearchMode,
    required this.currentSearchText,
  });

  @override
  Widget build(BuildContext context) {
    final isMaterialOnly =
        program.fileUrl.isEmpty || !program.fileUrl.startsWith('http');
    if (isMaterialOnly) {
      return ProgramViewerMaterialPlaceholder(program: program, isDark: isDark);
    }

    final isFilePdf =
        program.fileType == 'pdf' ||
        program.fileUrl.toLowerCase().contains('.pdf');
    final programId = program.id.isNotEmpty ? program.id : program.fileUrl;

    Widget buildCanvas({required double penWidth, int? pageIndex}) {
      return ProgramViewerCanvasOverlay(
        programId: programId,
        pageIndex: isFilePdf ? (pageIndex ?? 0) : index,
        penWidth: penWidth,
        isDrawingMode: isDrawingMode,
        selectedTool: selectedTool,
        activePenColor: activePenColor,
        activeIsShared: activeIsShared,
        canUseSharedPen: canUseSharedPen,
      );
    }

    final Widget childWidget = isFilePdf
        ? ProgramViewerPdfBody(
            key: ValueKey('pdf_body_${program.fileUrl}_$index'),
            program: program,
            pageCount: pageCount,
            pdfViewerController: pdfViewerController,
            sdkPdfBytesFuture: getCachedPdfBytesViaSdk(program.fileUrl),
            onPageCountLoaded: onPageCountLoaded,
            buildPageOverlay: (pIndex) =>
                buildCanvas(penWidth: 10.0, pageIndex: pIndex),
            isDrawingMode: isDrawingMode,
            isZoomed: isZoomed,
            isPinching: isPinching,
            initialPage: initialPage,
            onPageChanged: onPageChanged,
          )
        : ProgramViewerImageBody(
            key: ValueKey('img_body_${program.fileUrl}_$index'),
            program: program,
            imageSizeFuture: mediaCache.getCachedImageSize(program.fileUrl),
            safeUrl: mediaCache.getSafeUrl(program.fileUrl),
            isSearchMode: isSearchMode,
            currentSearchText: currentSearchText,
            buildOverlayLayers: (w) => buildCanvas(penWidth: w),
          );

    return GestureDetector(
      onDoubleTap: onResetZoom,
      child: InteractiveViewer(
        key: ValueKey('viewer_iv_${program.id}_$index'),
        transformationController: transformationController,
        panEnabled: !isDrawingMode,
        scaleEnabled: true,
        minScale: 1.0,
        maxScale: 6.0,
        boundaryMargin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.giant * 4,
          vertical: AppSpacing.giant * 6,
        ),
        clipBehavior: Clip.hardEdge,
        alignment: Alignment.center,
        onInteractionEnd: (_) {
          final double currentScale = transformationController.value
              .getMaxScaleOnAxis();
          if (currentScale <= 1.05) {
            onResetZoom();
          }
        },
        child: Center(
          key: ValueKey('viewer_container_${program.id}_$index'),
          child: childWidget,
        ),
      ),
    );
  }
}
