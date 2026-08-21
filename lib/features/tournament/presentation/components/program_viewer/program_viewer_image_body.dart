import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/painters/program_viewer_painters.dart';
import 'package:kendo_os/shared/domain/entities/program_model.dart'
    hide StrokeModel;
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';

/// プログラムビューアの画像＆OCRハイライトレンダリング本体コンポーネント
class ProgramViewerImageBody extends StatelessWidget {
  final ProgramModel program;
  final Future<Size> imageSizeFuture;
  final String safeUrl;
  final bool isSearchMode;
  final String currentSearchText;
  final Widget Function(double penWidth) buildOverlayLayers;

  const ProgramViewerImageBody({
    super.key,
    required this.program,
    required this.imageSizeFuture,
    required this.safeUrl,
    required this.isSearchMode,
    required this.currentSearchText,
    required this.buildOverlayLayers,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Size>(
      future: imageSizeFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final imgSize = snapshot.data!;

        const double maxDimension = 2048.0;
        final bool isTooLarge =
            imgSize.width > maxDimension || imgSize.height > maxDimension;
        final double scale = isTooLarge
            ? (maxDimension /
                  (imgSize.width > imgSize.height
                      ? imgSize.width
                      : imgSize.height))
            : 1.0;
        final Size displaySize = Size(
          imgSize.width * scale,
          imgSize.height * scale,
        );

        final double imagePenWidth = (displaySize.width * 0.005).clamp(
          8.0,
          50.0,
        );

        return FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: displaySize.width,
            height: displaySize.height,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.network(
                    safeUrl,
                    fit: BoxFit.fill,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFFEEEEEE),
                        child: const Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 64,
                            color: AppKendoColors.grey,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Builder(
                  builder: (context) {
                    final ocrWords = program.ocrWords;
                    if (isSearchMode &&
                        currentSearchText.isNotEmpty &&
                        ocrWords != null) {
                      return Positioned.fill(
                        child: CustomPaint(
                          painter: OcrHighlightPainter(
                            ocrWords: ocrWords,
                            searchText: currentSearchText,
                            originalImageSize: imgSize,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                buildOverlayLayers(imagePenWidth),
              ],
            ),
          ),
        );
      },
    );
  }
}
