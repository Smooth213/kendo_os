import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/widgets/match_tables/point_mark_badge.dart';
import 'match_point_badge.dart';

/// 試合一覧やタイムラインで赤白の技マークと中央セパレーター（ー / ×）を描画する純粋UIコンポーネント
class MatchScoreLine extends StatelessWidget {
  final List<PointMark> redPoints;
  final List<PointMark> whitePoints;
  final bool isDraw;
  final Color redColor;
  final Color whiteTextColor;
  final Color dividerTextColor;

  const MatchScoreLine({
    super.key,
    required this.redPoints,
    required this.whitePoints,
    required this.isDraw,
    required this.redColor,
    required this.whiteTextColor,
    required this.dividerTextColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasValidPoints =
        redPoints.isNotEmpty || whitePoints.isNotEmpty || isDraw;

    if (!hasValidPoints) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: SizedBox(width: AppSpacing.md),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 赤側技マーク一覧
          Row(
            mainAxisSize: MainAxisSize.min,
            children: redPoints
                .map(
                  (p) => MatchPointBadge(
                    mark: p.mark,
                    isFirst: p.isFirst,
                    color: redColor,
                  ),
                )
                .toList(),
          ),
          // 中央セパレーター（引き分け時は「×」、得点時は「ー」）
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text(
              isDraw ? '×' : 'ー',
              style: TextStyle(
                fontSize: AppFontSize.bodySmall,
                color: dividerTextColor,
                fontWeight: AppFontWeight.bold,
              ),
            ),
          ),
          // 白側技マーク一覧
          Row(
            mainAxisSize: MainAxisSize.min,
            children: whitePoints
                .map(
                  (p) => MatchPointBadge(
                    mark: p.mark,
                    isFirst: p.isFirst,
                    color: whiteTextColor,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
