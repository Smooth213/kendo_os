import 'package:flutter/material.dart';
import 'package:kendo_os/features/match/domain/score/stroke_model.dart';
import 'package:kendo_os/shared/infrastructure/persistence/models/local_stroke_model.dart';
import 'package:kendo_os/shared/theme/app_kendo_colors.dart';

/// 🥋 プログラム（PDF）ビューアー 手書きストローク描画ペインター
/// 共有ストローク（赤等）およびローカル個人ストローク（青等）のベジェ曲線描画に対応
class StrokePainter extends CustomPainter {
  final List<StrokeModel> sharedStrokes;
  final List<LocalStrokeModel> privateStrokes;
  final List<Offset>? currentPoints;
  final Color currentLineColor;
  final double activePenWidth;

  StrokePainter({
    required this.sharedStrokes,
    required this.privateStrokes,
    this.currentPoints,
    required this.currentLineColor,
    required this.activePenWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. 共有の線(赤)を描画
    for (final stroke in sharedStrokes) {
      // ★ 過去に描いた細すぎる線も、今の太さに補正して見やすくする救済措置
      final width = stroke.strokeWidth < 6.0
          ? activePenWidth
          : stroke.strokeWidth;
      final paint = getPaint(stroke.color, width);
      _drawPoints(canvas, stroke.points, paint);
    }

    // 2. 個人の線(青)を描画 (X/YのリストからOffsetを復元)
    for (final stroke in privateStrokes) {
      final width = stroke.strokeWidth < 6.0
          ? activePenWidth
          : stroke.strokeWidth;
      final paint = getPaint(Color(stroke.colorValue), width);
      if (stroke.pointsX.length < 2) continue;

      final path = Path();
      path.moveTo(stroke.pointsX.first, stroke.pointsY.first);
      for (int i = 1; i < stroke.pointsX.length; i++) {
        path.lineTo(stroke.pointsX[i], stroke.pointsY[i]);
      }
      canvas.drawPath(path, paint);
    }

    // 3. 今まさに引いている線を描画
    final current = currentPoints;
    if (current != null && current.isNotEmpty) {
      final paint = getPaint(currentLineColor, activePenWidth);
      _drawPoints(canvas, current, paint);
    }
  }

  Paint getPaint(Color color, double width) {
    // 🛡️ 救済パッチ：過去にColors.yellowで書かれたアノテーションデータを読み込んだ場合、
    // 自動的に視認性の高いゴールドイエローに色補正してレンダリングする
    Color finalColor = color;
    if (color.r == AppKendoColors.yellow.r &&
        color.g == AppKendoColors.yellow.g &&
        color.b == AppKendoColors.yellow.b) {
      finalColor = const Color(
        0xFFCA8A04,
      ).withAlpha((color.a * 255.0).round().clamp(0, 255));
    }

    final paint = Paint()
      ..color = finalColor
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // 不透明度が0.8未満（半透明）の場合はラインマーカーと見なし、乗算（blendMode）を適用する
    if (finalColor.a < 0.8) {
      paint.blendMode = BlendMode.multiply;
    }
    return paint;
  }

  void _drawPoints(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.isEmpty) return;

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    // ★ 画面にポンッと触れた瞬間（点が1つ）の時に、「極小の線（点）」を描画する
    if (points.length == 1) {
      path.lineTo(points.first.dx + 0.1, points.first.dy + 0.1);
      canvas.drawPath(path, paint);
      return;
    }

    if (points.length < 3) {
      path.lineTo(points.last.dx, points.last.dy);
    } else {
      for (int i = 1; i < points.length - 1; i++) {
        final xc = (points[i].dx + points[i + 1].dx) / 2;
        final yc = (points[i].dy + points[i + 1].dy) / 2;
        path.quadraticBezierTo(points[i].dx, points[i].dy, xc, yc);
      }
      path.lineTo(points.last.dx, points.last.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant StrokePainter oldDelegate) {
    // ★ 最適化: リスト長のショートサーキット判定で変化を最速検知
    if (oldDelegate.sharedStrokes.length != sharedStrokes.length) return true;
    if (oldDelegate.privateStrokes.length != privateStrokes.length) return true;
    if (oldDelegate.currentLineColor != currentLineColor) return true;
    if (oldDelegate.activePenWidth != activePenWidth) return true;
    if (oldDelegate.currentPoints != currentPoints) return true;
    return oldDelegate.sharedStrokes != sharedStrokes ||
        oldDelegate.privateStrokes != privateStrokes;
  }
}

/// 🥋 プログラム（PDF）ビューアー 画像OCR用ハイライト描画ペインター（絶対座標版）
class OcrHighlightPainter extends CustomPainter {
  final List<dynamic> ocrWords;
  final String searchText;
  final Size originalImageSize;

  OcrHighlightPainter({
    required this.ocrWords,
    required this.searchText,
    required this.originalImageSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (searchText.isEmpty) return;

    if (originalImageSize.width == 0) return;
    final double scale = size.width / originalImageSize.width;

    final paint = Paint()
      ..color = AppKendoColors.pinkAccent.withAlpha(128)
      ..style = PaintingStyle.fill;

    for (var wordData in ocrWords) {
      if (wordData is Map<String, dynamic>) {
        final text = wordData['text'] as String?;
        // 検索ワードが含まれているか判定
        if (text != null &&
            text.toLowerCase().contains(searchText.toLowerCase())) {
          final vertices = wordData['vertices'] as List<dynamic>?;
          if (vertices != null && vertices.length == 4) {
            double minX = double.infinity, minY = double.infinity;
            double maxX = 0, maxY = 0;

            for (var vertex in vertices) {
              final x = ((vertex['x'] as num?)?.toDouble() ?? 0.0) * scale;
              final y = ((vertex['y'] as num?)?.toDouble() ?? 0.0) * scale;
              if (x < minX) minX = x;
              if (y < minY) minY = y;
              if (x > maxX) maxX = x;
              if (y > maxY) maxY = y;
            }

            final padding = size.width * 0.005;
            final rect = Rect.fromLTRB(
              minX - padding,
              minY - padding,
              maxX + padding,
              maxY + padding,
            );
            canvas.drawRRect(
              RRect.fromRectAndRadius(rect, Radius.circular(padding)),
              paint,
            );
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant OcrHighlightPainter oldDelegate) {
    return oldDelegate.searchText != searchText ||
        oldDelegate.ocrWords != ocrWords ||
        oldDelegate.originalImageSize != originalImageSize;
  }
}
