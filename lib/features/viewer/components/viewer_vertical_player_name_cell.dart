import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';

/// 観戦・公式記録画面における縦書きテキスト・選手名表示セル（純粋UIコンポーネント）
/// 長音符「ー」や括弧類の 90 度回転、イニシャル（頭文字添え字）の配置に対応
class ViewerVerticalPlayerNameCell extends StatelessWidget {
  final String text;
  final String initial;
  final bool isDark;
  final TextStyle? style;

  const ViewerVerticalPlayerNameCell({
    super.key,
    required this.text,
    this.initial = '',
    required this.isDark,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final defaultStyle = TextStyle(
      fontSize: AppFontSize.caption,
      fontWeight: AppFontWeight.bold,
      color: isDark ? const Color(0xFFFFFFFF) : const Color(0x8A000000),
    );
    final effectiveStyle = style ?? defaultStyle;

    final Widget nameCol = Column(
      mainAxisSize: MainAxisSize.min,
      children: text.split('').map((char) {
        if (char == 'ー' || char == '-') {
          return RotatedBox(
            quarterTurns: 1,
            child: Text(char, style: effectiveStyle),
          );
        }
        if (char == '(' || char == ')' || char == '（' || char == '）') {
          return RotatedBox(
            quarterTurns: 1,
            child: Text(char, style: effectiveStyle),
          );
        }
        return Text(char, style: effectiveStyle.copyWith(height: 1.1));
      }).toList(),
    );

    if (initial.isEmpty) return nameCol;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        nameCol,
        Padding(
          padding: const EdgeInsets.only(left: 1, bottom: 0),
          child: Text(
            initial,
            style: effectiveStyle.copyWith(
              fontSize: AppFontSize.micro,
              color: isDark ? const Color(0xFFFFFFFF) : const Color(0x8A000000),
            ),
          ),
        ),
      ],
    );
  }
}
