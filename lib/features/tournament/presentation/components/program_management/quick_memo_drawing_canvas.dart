import 'package:flutter/material.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_canvas_painter.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_management/quick_memo_drawing_toolbar.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 🥋 クイックメモの手書き描画キャンバス＆ツールバー領域
class QuickMemoDrawingCanvas extends StatelessWidget {
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
          QuickMemoEmptyGuidance(textColor: themeColors.textColor),
        Positioned(
          left: AppSpacing.md,
          right: AppSpacing.md,
          bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
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
