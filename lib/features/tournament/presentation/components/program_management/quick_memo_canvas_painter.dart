import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';

/// 🥋 クイック手書きメモの1筆（ストローク）
class MemoStroke {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  const MemoStroke({
    required this.points,
    required this.color,
    required this.strokeWidth,
  });

  Map<String, dynamic> toJson() {
    return {
      'points': points.map((p) => [p.dx, p.dy]).toList(),
      'color': color.toARGB32(),
      'strokeWidth': strokeWidth,
    };
  }

  factory MemoStroke.fromJson(Map<String, dynamic> json) {
    final rawPoints = json['points'] as List<dynamic>? ?? [];
    final points = rawPoints.map((pt) {
      final list = pt as List<dynamic>;
      return Offset((list[0] as num).toDouble(), (list[1] as num).toDouble());
    }).toList();
    final colorVal = json['color'] as int? ?? 0xFF000000;
    final width = (json['strokeWidth'] as num?)?.toDouble() ?? 3.0;
    return MemoStroke(
      points: points,
      color: Color(colorVal),
      strokeWidth: width,
    );
  }
}

/// 🥋 方眼グリッド背景ペインター
class MemoGridBackgroundPainter extends CustomPainter {
  final bool isDark;
  final Color gridColor;

  MemoGridBackgroundPainter({required this.isDark, required this.gridColor});

  @override
  void paint(Canvas canvas, Size size) {
    const double step = 28.0;
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.8;

    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant MemoGridBackgroundPainter oldDelegate) => false;
}

/// 🥋 手書きストロークペインター
class MemoCanvasPainter extends CustomPainter {
  final List<MemoStroke> strokes;
  final List<Offset> currentPoints;
  final Color currentColor;
  final double currentWidth;

  MemoCanvasPainter({
    required this.strokes,
    required this.currentPoints,
    required this.currentColor,
    required this.currentWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke.points, stroke.color, stroke.strokeWidth);
    }
    if (currentPoints.isNotEmpty) {
      _drawStroke(canvas, currentPoints, currentColor, currentWidth);
    }
  }

  void _drawStroke(
    Canvas canvas,
    List<Offset> points,
    Color color,
    double width,
  ) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (points.length == 1) {
      canvas.drawCircle(points.first, width / 2, paint);
      return;
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant MemoCanvasPainter oldDelegate) => true;
}

/// 🥋 手書き空状態ガイダンス表示
class QuickMemoEmptyGuidance extends StatelessWidget {
  final Color textColor;

  const QuickMemoEmptyGuidance({super.key, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: IgnorePointer(
        child: Opacity(
          opacity: 0.35,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edit_note_rounded, size: 64, color: textColor),
              const SizedBox(height: AppSpacing.md),
              Text(
                'ここに指やペンでメモを自由に書けます',
                style: TextStyle(
                  fontSize: AppFontSize.body,
                  color: textColor,
                  fontWeight: AppFontWeight.medium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
