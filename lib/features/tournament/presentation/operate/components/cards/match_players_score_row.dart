import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/widgets/match_tables/point_mark_badge.dart';
import 'match_score_line.dart';

/// 試合カード内の赤選手名・中央スコアライン・白選手名を1行で描画する純粋UIコンポーネント
class MatchPlayersScoreRow extends StatelessWidget {
  final String redName;
  final String whiteName;
  final bool isRedOwn;
  final bool isWhiteOwn;
  final List<PointMark> redPoints;
  final List<PointMark> whitePoints;
  final bool isDraw;
  final Color textColor;
  final Color subTextColor;

  const MatchPlayersScoreRow({
    super.key,
    required this.redName,
    required this.whiteName,
    required this.isRedOwn,
    required this.isWhiteOwn,
    required this.redPoints,
    required this.whitePoints,
    required this.isDraw,
    required this.textColor,
    required this.subTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 赤側選手名（100%の横幅を活用して文字切れを完全に防御）
        Expanded(
          child: Text(
            redName,
            style: TextStyle(
              fontSize: AppFontSize.body,
              fontWeight: isRedOwn ? AppFontWeight.black : AppFontWeight.bold,
              color: isRedOwn ? const Color(0xFFD97706) : textColor,
            ),
            textAlign: TextAlign.start,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // 中央スコアマーク（スコアなし時は完全空欄）
        MatchScoreLine(
          redPoints: redPoints,
          whitePoints: whitePoints,
          isDraw: isDraw,
          redColor: const Color(0xFFE53935),
          whiteTextColor: textColor,
          dividerTextColor: subTextColor,
        ),
        // 白側選手名
        Expanded(
          child: Text(
            whiteName,
            style: TextStyle(
              fontSize: AppFontSize.body,
              fontWeight: isWhiteOwn ? AppFontWeight.black : AppFontWeight.bold,
              color: isWhiteOwn ? const Color(0xFFD97706) : textColor,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
