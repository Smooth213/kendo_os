import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';

/// 公式記録・観戦記録における打突部位表示用モデル
class OfficialPointDisplay {
  final String mark;
  final bool isFirstMatchPoint;

  const OfficialPointDisplay(this.mark, this.isFirstMatchPoint);
}

/// 打突部位マーク（メ、コ、ド、ツ、反、判、◯）描画バッジ（純粋UIコンポーネント）
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
    final displayMark = point.mark == '判定' ? '判' : point.mark;
    if (point.isFirstMatchPoint && displayMark != '反' && displayMark != '◯') {
      return Container(
        width: 14,
        height: 14,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 0.8),
        ),
        child: Text(
          displayMark,
          style: TextStyle(
            fontSize: AppFontSize.micro,
            color: color,
            fontWeight: AppFontWeight.bold,
            height: 1.1,
          ),
        ),
      );
    }
    return Text(
      displayMark,
      style: TextStyle(
        fontSize: AppFontSize.badge,
        color: color,
        fontWeight: AppFontWeight.bold,
        height: 1.1,
      ),
    );
  }
}

/// 観戦・公式記録画面における対戦スコアの打突部位ボックス（純粋UIコンポーネント）
/// 勝者円形ハイライト、1本目・2本目の上下配置に対応
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
    final color = isRed ? const Color(0xFFE53935) : const Color(0xFF2196F3);

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
          if (pts.isNotEmpty)
            Positioned(
              top: AppSpacing.xs,
              left: 6,
              child: OfficialTechMarkBadge(point: pts[0], color: color),
            ),
          if (pts.length > 1)
            Positioned(
              bottom: AppSpacing.xs,
              right: 6,
              child: OfficialTechMarkBadge(point: pts[1], color: color),
            ),
        ],
      ),
    );
  }
}
