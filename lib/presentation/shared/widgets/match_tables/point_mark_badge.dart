import 'package:flutter/material.dart';

/// 技マークを表示するための共通データ構造
class PointMark {
  final String mark;
  final bool isFirst;

  const PointMark({
    required this.mark,
    this.isFirst = false,
  });
}

/// 技マーク（メ、コ、ド、ツ、反、判定、◯など）を描画するバッジWidget
class PointMarkBadge extends StatelessWidget {
  final PointMark point;
  final Color color;
  final bool isDark;

  const PointMarkBadge({
    super.key,
    required this.point,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    String displayMark = point.mark == '判定' ? '判' : point.mark;
    
    // 1本目（先取）かつ、フセン勝ち（◯）や反則（反）でない場合は丸で囲む
    if (point.isFirst && displayMark != '◯' && displayMark != '反') {
      return Container(
        width: 14,
        height: 14,
        alignment: Alignment.center,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.6 : 1.0),
            width: 1.0,
          ),
        ),
        child: Text(
          displayMark,
          style: TextStyle(
            fontSize: 8,
            color: color,
            fontWeight: FontWeight.bold,
            height: 1.1,
          ),
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        displayMark,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
          height: 1.1,
        ),
      ),
    );
  }
}

/// 選手の取得した2本分（またはそれ以上）の技マークを並べて表示するボックス
class PointBox extends StatelessWidget {
  final List<PointMark> points;
  final bool isWinner;
  final bool isRed;
  final bool isDark;

  const PointBox({
    super.key,
    required this.points,
    required this.isWinner,
    required this.isRed,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final color = isRed 
        ? (isDark ? Colors.red.shade400 : Colors.red.shade700) 
        : (isDark ? Colors.blue.shade400 : Colors.blue.shade700);

    return SizedBox(
      width: 36,
      height: 36,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isWinner)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
            ),
          if (points.isNotEmpty)
            Positioned(
              top: 4,
              left: 6,
              child: PointMarkBadge(point: points[0], color: color, isDark: isDark),
            ),
          if (points.length > 1)
            Positioned(
              bottom: 4,
              right: 6,
              child: PointMarkBadge(point: points[1], color: color, isDark: isDark),
            ),
        ],
      ),
    );
  }
}