import 'package:flutter/material.dart';
import 'package:kendo_os/shared/presentation/widgets/kendo_score_box.dart';

/// 試合一覧やタイムラインで技マーク（メ・コ・ド・ツ・◯・×・先取丸枠線）を単体描画する純粋UIコンポーネント
/// （新ガバナンス KendoTechMarkBadge への公式アダプター）
class MatchPointBadge extends StatelessWidget {
  final String mark;
  final bool isFirst;
  final Color color;

  const MatchPointBadge({
    super.key,
    required this.mark,
    this.isFirst = false,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return KendoTechMarkBadge(
      point: KendoPointMark(mark: mark, isFirst: isFirst),
      color: color,
      isDark: false,
    );
  }
}
