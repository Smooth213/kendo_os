import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';

/// 試合一覧やタイムラインで技マーク（メ・コ・ド・ツ・◯・×・先取丸枠線）を単体描画する純粋UIコンポーネント
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
    final String displayMark = mark == '✕' ? '×' : mark;

    if (displayMark == '◯' || displayMark == '×') {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        child: Text(
          displayMark,
          style: TextStyle(
            fontSize: AppFontSize.body,
            fontWeight: AppFontWeight.bold,
            color: color,
          ),
        ),
      );
    }

    if (isFirst) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        padding: const EdgeInsets.all(AppSpacing.xxs),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 1.2),
        ),
        alignment: Alignment.center,
        child: Text(
          displayMark,
          style: TextStyle(
            fontSize: AppFontSize.badge,
            fontWeight: AppFontWeight.bold,
            color: color,
            height: 1.1,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Text(
        displayMark,
        style: TextStyle(
          fontSize: AppFontSize.body,
          fontWeight: AppFontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
