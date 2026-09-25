import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_canvas_painter.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_drawing_toolbar.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 🥋 クイックメモの手書き描画キャンバス＆ツールバー領域
class QuickMemoDrawingCanvas extends StatelessWidget {
  /// 📐 全端末共通の基準キャンバスサイズ（PC/iPad/iPhone共通ピクセル空間）
  static const Size baseCanvasSize = Size(800, 1000);

  final List<MemoStroke> strokes;
  final List<Offset> currentPoints;
  final Color selectedColor;
  final double selectedWidth;
  final bool isEraser;
  final bool isDark;
  final AppThemeColors themeColors;
  final GestureDragStartCallback onPanStart;
  final GestureDragUpdateCallback onPanUpdate;
  final GestureDragEndCallback onPanEnd;
  final ValueChanged<Color> onColorChanged;
  final VoidCallback onToggleWidth;
  final VoidCallback onToggleEraser;

  const QuickMemoDrawingCanvas({
    super.key,
    required this.strokes,
    required this.currentPoints,
    required this.selectedColor,
    required this.selectedWidth,
    required this.isEraser,
    required this.isDark,
    required this.themeColors,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.onColorChanged,
    required this.onToggleWidth,
    required this.onToggleEraser,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. 共通ピクセル比率を保つノート用紙キャンバス
        Positioned.fill(
          bottom: 74, // ツールバーの高さと余白
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.contain,
                child: Container(
                  width: baseCanvasSize.width,
                  height: baseCanvasSize.height,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF161F2E)
                        : AppKendoColors.white,
                    borderRadius: AppRadius.large,
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFCBD5E1),
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
                      // 統一座標系での手書きジェスチャー＆描画
                      Positioned.fill(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onPanStart: onPanStart,
                          onPanUpdate: onPanUpdate,
                          onPanEnd: onPanEnd,
                          child: CustomPaint(
                            painter: MemoCanvasPainter(
                              strokes: strokes,
                              currentPoints: currentPoints,
                              currentColor: selectedColor,
                              currentWidth: selectedWidth,
                            ),
                          ),
                        ),
                      ),
                      if (strokes.isEmpty && currentPoints.isEmpty)
                        QuickMemoEmptyGuidance(
                          textColor: themeColors.textColor,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // 2. ツールバー（画面下部に固定）
        Positioned(
          left: AppSpacing.md,
          right: AppSpacing.md,
          bottom: MediaQuery.of(context).padding.bottom + AppSpacing.xs,
          child: QuickMemoDrawingToolbar(
            themeColors: themeColors,
            isDark: isDark,
            selectedColor: selectedColor,
            selectedWidth: selectedWidth,
            isEraser: isEraser,
            onColorChanged: onColorChanged,
            onToggleWidth: onToggleWidth,
            onToggleEraser: onToggleEraser,
          ),
        ),
      ],
    );
  }
}
