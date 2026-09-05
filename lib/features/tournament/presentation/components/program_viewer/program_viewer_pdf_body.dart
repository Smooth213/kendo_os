import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_viewer/program_viewer_media_cache.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_viewer/program_viewer_pdf_page_cache.dart';
import 'package:kendo_os/shared/domain/entities/program_model.dart'
    hide StrokeModel;
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

/// プログラムビューアのPDFレンダリング本体コンポーネント
/// 縦スクロール PageView（Axis.vertical）により、直感的な縦スワイプで各ページを切り替え可能。
///
/// ★ 縦横混在PDFの上下左右完全中央配置＆手書きペン100%同期アーキテクチャ:
/// Syncfusionの縦横混在マルチページバグを構造的に根絶するため、各ページを「単一ページPDF」として動的に分離・キャッシュ。
/// ページの向きに応じたキャンバスサイズ（縦: 1000x1414, 横: 1414x1000）を適用し、
/// Positioned.fill で用紙とペン層を完全に一致させ、FittedBox(contain) により上下左右完全中央に均等余白で自動配置します。
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

/// 過去の互換性のためのエイリアス
class ProgramPdfPageLayoutCache {
  static Size getPageCanvasSize(String url, int pageIndex) {
    return ProgramViewerPdfPageCache.shared.getPageCanvasSize(url, pageIndex);
  }

  static Rect getPageBounds(String url, int pageIndex) {
    final size = getPageCanvasSize(url, pageIndex);
    return Rect.fromLTWH(0, 0, size.width, size.height);
  }

  static double getVerticalOffset(String url, int pageIndex) => 0.0;
}

class _ProgramViewerPdfBodyState extends State<ProgramViewerPdfBody> {
  late PageController _pageController;
  late Future<Uint8List> _sourceBytesFuture;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialPage);
    _initSourceBytes();
  }

  void _initSourceBytes() {
    _sourceBytesFuture =
        widget.sdkPdfBytesFuture ??
        ProgramViewerMediaCache.shared.getCachedPdfBytes(
          widget.program.fileUrl,
        );

    _sourceBytesFuture
        .then((bytes) {
          if (!mounted) return;
          final totalCount = ProgramViewerPdfPageCache.shared.parseDocumentInfo(
            widget.program.fileUrl,
            bytes,
          );
          widget.onPageCountLoaded?.call(totalCount);
          setState(() {});
        })
        .catchError((dynamic error) {
          debugPrint(
            '🚨 [ProgramViewerPdfBody] Failed to load source bytes: $error',
          );
        });
  }

  @override
  void didUpdateWidget(covariant ProgramViewerPdfBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.program.fileUrl != oldWidget.program.fileUrl ||
        widget.sdkPdfBytesFuture != oldWidget.sdkPdfBytesFuture) {
      _initSourceBytes();
    }
    if (widget.initialPage != oldWidget.initialPage &&
        _pageController.hasClients) {
      if (_pageController.page?.round() != widget.initialPage) {
        _pageController.jumpToPage(widget.initialPage);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int cachedCount =
        ProgramViewerPdfPageCache.shared.getCachedPageCount(
          widget.program.fileUrl,
        ) ??
        widget.pageCount;
    final int safePageCount = cachedCount > 0 ? cachedCount : 1;

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
        // ページの向きに応じたキャンバスサイズ（縦: 1000x1414, 横: 1414x1000）
        final Size canvasSize = ProgramViewerPdfPageCache.shared
            .getPageCanvasSize(widget.program.fileUrl, pageIndex);

        return Center(
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: canvasSize.width,
              height: canvasSize.height,
              child: Stack(
                children: [
                  // 1. PDF単一ページ描画層
                  // 単一ページPDFなので先行ページの向き・サイズ記憶によるオフセットズレは物理的に100%発生しない
                  Positioned.fill(
                    child: IgnorePointer(
                      child: FutureBuilder<Uint8List>(
                        future: _sourceBytesFuture,
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                'PDFロード失敗: ${snapshot.error}',
                                style: const TextStyle(
                                  color: AppKendoColors.redAccent,
                                ),
                              ),
                            );
                          }
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: AppKendoColors.ipponGold,
                              ),
                            );
                          }

                          // 当該ページのみを抽出した単一ページPDFバイナリ
                          final Uint8List singlePageBytes =
                              ProgramViewerPdfPageCache.shared
                                  .getOrExtractSinglePage(
                                    widget.program.fileUrl,
                                    snapshot.data!,
                                    pageIndex,
                                  );

                          return SfPdfViewerTheme(
                            data: const SfPdfViewerThemeData(
                              backgroundColor: AppKendoColors.transparent,
                            ),
                            child: SfPdfViewer.memory(
                              singlePageBytes,
                              key: ValueKey(
                                '${widget.program.fileUrl}_single_p$pageIndex',
                              ),
                              initialPageNumber: 1,
                              pageLayoutMode: PdfPageLayoutMode.single,
                              scrollDirection: PdfScrollDirection.vertical,
                              pageSpacing: 0,
                              canShowScrollHead: false,
                              canShowScrollStatus: false,
                              canShowPaginationDialog: false,
                              enableDoubleTapZooming: false,
                              enableTextSelection: false,
                              onDocumentLoadFailed: (details) {
                                debugPrint(
                                  '🚨 PDF Single Page Load Failed: ${details.error} - ${details.description}',
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // 2. そのページ専用の手書き描画レイヤー（用紙と完全に同一比率・同一キャンバスで一体化）
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
