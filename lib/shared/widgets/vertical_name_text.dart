import 'package:flutter/material.dart';

class VerticalNameText extends StatelessWidget {
  final String text;
  final String initial;
  final bool isDark;

  const VerticalNameText({
    super.key,
    required this.text,
    this.initial = '',
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.bold,
      color: isDark ? Colors.grey.shade400 : Colors.grey.shade800,
    );

    Widget nameCol = Column(
      mainAxisSize: MainAxisSize.min,
      children: text.split('').map((char) {
        if (char == 'ー' || char == '-') {
          return RotatedBox(quarterTurns: 1, child: Text(char, style: style));
        }
        if (char == '(' || char == ')' || char == '（' || char == '）') {
          return RotatedBox(quarterTurns: 1, child: Text(char, style: style));
        }
        return Text(char, style: style.copyWith(height: 1.1));
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
            style: style.copyWith(
              fontSize: 8,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade500,
            ),
          ),
        ),
      ],
    );
  }
}
