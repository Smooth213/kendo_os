import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/program_stroke_layer.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_viewer/program_viewer_media_cache.dart';
import 'package:kendo_os/shared/domain/entities/program_model.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// プログラムボトムシート用の画像ビューアコンポーネント
class ProgramSheetImageViewer extends StatelessWidget {
  const ProgramSheetImageViewer({
    super.key,
    required this.program,
    required this.programId,
    required this.pageIndex,
    required this.themeColors,
    required this.mediaCache,
  });

  final ProgramModel program;
  final String programId;
  final int pageIndex;
  final AppThemeColors themeColors;
  final ProgramViewerMediaCache mediaCache;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: InteractiveViewer(
        minScale: 0.8,
        maxScale: 4.0,
        child: Center(
          child: FutureBuilder<Size>(
            future: mediaCache.getCachedImageSize(program.fileUrl),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppKendoColors.ipponGold,
                  ),
                );
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
                        child: program.fileUrl.contains('example.com')
                            ? Container(
                                color: themeColors.cardBackground,
                                child: Center(
                                  child: Icon(
                                    Icons.image,
                                    size: 64,
                                    color: themeColors.primaryAccent,
                                  ),
                                ),
                              )
                            : Image.network(
                                mediaCache.getSafeUrl(program.fileUrl),
                                fit: BoxFit.fill,
                                errorBuilder: (context, _, _) => Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.broken_image,
                                        size: 48,
                                        color: AppKendoColors.grey,
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      Text(
                                        '画像を読み込めませんでした',
                                        style: TextStyle(
                                          color: themeColors.subTextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                      Positioned.fill(
                        child: ProgramStrokeLayer(
                          programId: programId,
                          pageIndex: pageIndex,
                          penWidth: imagePenWidth,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
