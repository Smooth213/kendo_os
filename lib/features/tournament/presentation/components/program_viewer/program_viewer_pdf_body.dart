import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kendo_os/shared/domain/entities/program_model.dart'
    hide StrokeModel;
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

/// プログラムビューアのPDFレンダリング本体コンポーネント
class ProgramViewerPdfBody extends StatelessWidget {
  final ProgramModel program;
  final int pageCount;
  final PdfViewerController pdfViewerController;
  final Future<Uint8List>? sdkPdfBytesFuture;
  final void Function(int count)? onPageCountLoaded;
  final Widget overlayLayers;

  const ProgramViewerPdfBody({
    super.key,
    required this.program,
    required this.pageCount,
    required this.pdfViewerController,
    this.sdkPdfBytesFuture,
    this.onPageCountLoaded,
    required this.overlayLayers,
  });

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: 1000,
        height: 1415 * (pageCount > 0 ? pageCount : 1).toDouble(),
        child: Stack(
          children: [
            Positioned.fill(
              child: kIsWeb && sdkPdfBytesFuture != null
                  ? FutureBuilder<Uint8List>(
                      future: sdkPdfBytesFuture,
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
                          key: ValueKey(program.fileUrl),
                          controller: pdfViewerController,
                          canShowScrollHead: false,
                          enableDoubleTapZooming: false,
                          enableTextSelection: false,
                          onDocumentLoaded: (details) {
                            onPageCountLoaded?.call(
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
                      program.fileUrl,
                      key: ValueKey(program.fileUrl),
                      controller: pdfViewerController,
                      canShowScrollHead: false,
                      enableDoubleTapZooming: false,
                      enableTextSelection: false,
                      onDocumentLoaded: (details) {
                        onPageCountLoaded?.call(details.document.pages.count);
                      },
                      onDocumentLoadFailed: (details) {
                        debugPrint(
                          '🚨 PDF Load Failed: ${details.error} - ${details.description}',
                        );
                      },
                    ),
            ),
            overlayLayers,
          ],
        ),
      ),
    );
  }
}
