import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_canvas_painter.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 📄 手書きクイックメモの用紙（グリッド・ストローク・枠線・影）レンダリングビュー
class QuickMemoPaperView extends StatelessWidget {
  final Offset paperTopLeft;
  final double totalScale;
  final Size baseCanvasSize;
  final bool isDark;
  final AppThemeColors themeColors;
  final List<MemoStroke> strokes;
  final List<Offset> currentPoints;
  final Color selectedColor;
  final double selectedWidth;
  final bool isZoomed;

  const QuickMemoPaperView({
    super.key,
    required this.paperTopLeft,
    required this.totalScale,
    required this.baseCanvasSize,
    required this.isDark,
    required this.themeColors,
    required this.strokes,
    required this.currentPoints,
    required this.selectedColor,
    required this.selectedWidth,
    required this.isZoomed,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: paperTopLeft.dx,
      top: paperTopLeft.dy,
      width: baseCanvasSize.width * totalScale,
      height: baseCanvasSize.height * totalScale,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161F2E) : AppKendoColors.white,
          borderRadius: AppRadius.large,
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppKendoColors.black.withValues(
                alpha: isDark ? 0.35 : 0.08,
              ),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: baseCanvasSize.width,
            height: baseCanvasSize.height,
            child: Stack(
              children: [
                // 用紙内方眼グリッド
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: MemoGridBackgroundPainter(
                        isDark: isDark,
                        gridColor: isDark
                            ? const Color(0xFF243247)
                            : const Color(0xFFF1F5F9),
                      ),
                    ),
                  ),
                ),
                // 統一座標系での手書き描画
                Positioned.fill(
                  child: CustomPaint(
                    painter: MemoCanvasPainter(
                      strokes: strokes,
                      currentPoints: currentPoints,
                      currentColor: selectedColor,
                      currentWidth: selectedWidth,
                    ),
                  ),
                ),
                if (strokes.isEmpty && currentPoints.isEmpty && !isZoomed)
                  QuickMemoEmptyGuidance(textColor: themeColors.textColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
