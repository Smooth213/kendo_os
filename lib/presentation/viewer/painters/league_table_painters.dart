import 'package:flutter/material.dart';

// 自分自身との交差セルに斜め線を引く
class DiagonalLinePainter extends CustomPainter {
  final Color color;
  DiagonalLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 1;
    canvas.drawLine(const Offset(0, 0), Offset(size.width, size.height), paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ◯（勝ち）・△（負け）・✕（引き分け）を描画する究極のペインター
class ResultShapePainter extends CustomPainter {
  final String result; // 'win', 'loss', 'draw'
  final Color color;
  ResultShapePainter({required this.result, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = color.withValues(alpha: 0.1)..style = PaintingStyle.fill;
    final strokePaint = Paint()..color = color..strokeWidth = 1.5..style = PaintingStyle.stroke;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.42;

    if (result == 'win') { // ◯ 勝ち
      canvas.drawCircle(center, radius, bgPaint);
      canvas.drawCircle(center, radius, strokePaint);
    } else if (result == 'loss') { // △ 負け
      final path = Path();
      path.moveTo(center.dx, center.dy - radius);
      path.lineTo(center.dx + radius * 1.1, center.dy + radius * 0.8);
      path.lineTo(center.dx - radius * 1.1, center.dy + radius * 0.8);
      path.close();
      canvas.drawPath(path, bgPaint);
      canvas.drawPath(path, strokePaint);
    } else { // □ 引き分け（星取り表）
      final rect = Rect.fromCenter(center: center, width: radius * 1.8, height: radius * 1.8);
      canvas.drawRect(rect, bgPaint);
      canvas.drawRect(rect, strokePaint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 1本目だけ丸囲みする個人戦用ヘルパー
Widget buildIndivSingle(String tech, bool isFirst, Color color) {
  String displayTech = tech == '判定' ? '判' : tech;
  if (isFirst && displayTech != '◯' && displayTech != '反') {
    return Container(
      width: 14, height: 14, alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 0.8)),
      child: Text(displayTech, style: TextStyle(fontSize: 8, color: color, fontWeight: FontWeight.bold, height: 1.1)),
    );
  }
  return Text(displayTech, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold, height: 1.1));
}