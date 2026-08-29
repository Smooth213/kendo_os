import 'package:flutter/material.dart';
import 'package:kendo_os/shared/presentation/widgets/kendo_score_box.dart';

/// 公式記録・観戦記録における打突部位表示用モデル（旧コード互換）
class OfficialPointDisplay {
  final String mark;
  final bool isFirstMatchPoint;

  const OfficialPointDisplay(this.mark, this.isFirstMatchPoint);

  KendoPointMark toKendoPointMark() =>
      KendoPointMark(mark: mark, isFirst: isFirstMatchPoint);
}

/// 打突部位マーク（メ、コ、ド、ツ、反、判、◯）描画バッジ
/// （新ガバナンス KendoTechMarkBadge への公式アダプター）
class OfficialTechMarkBadge extends StatelessWidget {
  final OfficialPointDisplay point;
  final Color color;

  const OfficialTechMarkBadge({
    super.key,
    required this.point,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return KendoTechMarkBadge(
      point: point.toKendoPointMark(),
      color: color,
      isDark: false,
    );
  }
}

/// 観戦・公式記録画面における対戦スコアの打突部位ボックス
/// （新ガバナンス KendoScoreBox への公式アダプター）
class ViewerPointBoxCell extends StatelessWidget {
  final List<OfficialPointDisplay> pts;
  final bool isWinner;
  final bool isRed;
  final bool isDark;

  const ViewerPointBoxCell({
    super.key,
    required this.pts,
    required this.isWinner,
    required this.isRed,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return KendoScoreBox(
      points: pts.map((p) => p.toKendoPointMark()).toList(),
      isWinner: isWinner,
      isRed: isRed,
      isDark: isDark,
      variant: ScoreDisplayVariant.table,
    );
  }
}
