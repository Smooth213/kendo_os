import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kendo_os/shared/domain/entities/program_model.dart'
    hide StrokeModel;
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

/// プログラムビューアのPDFレンダリング本体コンポーネント
/// 縦スクロール PageView（Axis.vertical）により、直感的な縦スワイプで各ページをスイスイ切り替え可能。
/// 各ページは A4比率（1000x1414）の固定キャンバス内に PDF と手書きペンが完全に一体化し、
/// ページ切り替え時も用紙とペンが一緒にスクロールするため、ペンだけが取り残されることは物理的に100%あり得ません。
/// さらに、ピンチ拡大中やペン書き込み中は縦スワイプが自動でOFFになり、自由なパン移動や描画が可能です。
class ProgramViewerPdfBody extends StatefulWidget {
  final ProgramModel program;
  final int pageCount;
  final PdfViewerController pdfViewerController;
  final Future<Uint8List>? sdkPdfBytesFuture;
  final void Function(int count)? onPageCountLoaded;
  final Widget Function(int pageIndex) buildPageOverlay;
  final bool isDrawingMode;
  final bool isZoomed;
  final ValueChanged<int>? onPageChanged;
  final int initialPage;

  const ProgramViewerPdfBody({
    super.key,
    required this.program,
    required this.pageCount,
    required this.pdfViewerController,
    this.sdkPdfBytesFuture,
    this.onPageCountLoaded,
    required this.buildPageOverlay,
    this.isDrawingMode = false,
    this.isZoomed = false,
    this.onPageChanged,
    this.initialPage = 0,
  });

  @override
  State<ProgramViewerPdfBody> createState() => _ProgramViewerPdfBodyState();
}

class _ProgramViewerPdfBodyState extends State<ProgramViewerPdfBody> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double canvasWidth = 1000.0;
    const double canvasHeight = 1414.0;
    final int safePageCount = widget.pageCount > 0 ? widget.pageCount : 1;

    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      physics: widget.isDrawingMode || widget.isZoomed
          ? const NeverScrollableScrollPhysics()
          : const PageScrollPhysics(),
      itemCount: safePageCount,
      onPageChanged: (pageIndex) {
        widget.onPageChanged?.call(pageIndex);
      },
      itemBuilder: (context, pageIndex) {
        return Center(
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: canvasWidth,
              height: canvasHeight,
              child: Stack(
                children: [
                  // 1. PDFドキュメント表示層（IgnorePointerで包み、内部スクロールによるペン置き去りを防止）
                  Positioned.fill(
                    child: IgnorePointer(
                      child: widget.sdkPdfBytesFuture != null && kIsWeb
                          ? FutureBuilder<Uint8List>(
                              future: widget.sdkPdfBytesFuture,
                              builder: (context, bytesSnapshot) {
                                if (bytesSnapshot.hasError) {
                                  return Center(
                                    child: Text(
                                      'PDFロード失敗: ${bytesSnapshot.error}',
                                      style: const TextStyle(
                                        color: AppKendoColors.redAccent,
                                      ),
                                    ),
                                  );
                                }
                                if (!bytesSnapshot.hasData) {
                                  return const Center(
                                    child: CircularProgressIndicator(
                                      color: AppKendoColors.ipponGold,
                                    ),
                                  );
                                }
                                return SfPdfViewer.memory(
                                  bytesSnapshot.data!,
                                  key: ValueKey(
                                    '${widget.program.fileUrl}_p$pageIndex',
                                  ),
                                  initialPageNumber: pageIndex + 1,
                                  pageLayoutMode: PdfPageLayoutMode.single,
                                  canShowScrollHead: false,
                                  canShowScrollStatus: false,
                                  canShowPaginationDialog: false,
                                  enableDoubleTapZooming: false,
                                  enableTextSelection: false,
                                  onDocumentLoaded: (details) {
                                    widget.onPageCountLoaded?.call(
                                      details.document.pages.count,
                                    );
                                  },
                                  onDocumentLoadFailed: (details) {
                                    debugPrint(
                                      '🚨 PDF Load Failed (Memory): ${details.error} - ${details.description}',
                                    );
                                  },
                                );
                              },
                            )
                          : SfPdfViewer.network(
                              widget.program.fileUrl,
                              key: ValueKey(
                                '${widget.program.fileUrl}_p$pageIndex',
                              ),
                              initialPageNumber: pageIndex + 1,
                              pageLayoutMode: PdfPageLayoutMode.single,
                              canShowScrollHead: false,
                              canShowScrollStatus: false,
                              canShowPaginationDialog: false,
                              enableDoubleTapZooming: false,
                              enableTextSelection: false,
                              onDocumentLoaded: (details) {
                                widget.onPageCountLoaded?.call(
                                  details.document.pages.count,
                                );
                              },
                              onDocumentLoadFailed: (details) {
                                debugPrint(
                                  '🚨 PDF Load Failed: ${details.error} - ${details.description}',
                                );
                              },
                            ),
                    ),
                  ),

                  // 2. そのページ専用の手書き描画レイヤー（用紙と完全に同一キャンバスで一体化）
                  Positioned.fill(child: widget.buildPageOverlay(pageIndex)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
