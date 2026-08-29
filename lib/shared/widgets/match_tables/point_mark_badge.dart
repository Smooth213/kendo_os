import 'package:flutter/material.dart';
import 'package:kendo_os/shared/presentation/widgets/kendo_score_box.dart';

// 旧コードとの完全な互換性のための Type Alias
typedef PointMark = KendoPointMark;

/// 技マーク（メ、コ、ド、ツ、反、判定、◯など）を描画するバッジWidget
/// （新ガバナンス KendoTechMarkBadge への公式アダプター）
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
    return KendoTechMarkBadge(point: point, color: color, isDark: isDark);
  }
}

/// 選手の取得した2本分（またはそれ以上）の技マークを並べて表示するボックス
/// （新ガバナンス KendoScoreBox への公式アダプター）
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
    return KendoScoreBox(
      points: points,
      isWinner: isWinner,
      isRed: isRed,
      isDark: isDark,
      variant: ScoreDisplayVariant.table,
    );
  }
}
