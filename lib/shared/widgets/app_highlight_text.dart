import 'package:flutter/material.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:kendo_os/shared/theme/theme_color_extensions.dart';

/// 🔍 検索クエリと一致するテキスト部分をハイライト表示する共通コンポーネント
class AppHighlightText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle? style;
  final TextStyle? highlightStyle;
  final Color? highlightColor;
  final Color? highlightTextColor;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const AppHighlightText({
    super.key,
    required this.text,
    required this.query,
    this.style,
    this.highlightStyle,
    this.highlightColor,
    this.highlightTextColor,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  /// 🔍 TextSpan のリストとしてハイライト要素を生成するユーティリティ
  static List<TextSpan> buildSpans({
    required String text,
    required String query,
    TextStyle? style,
    TextStyle? highlightStyle,
    Color? highlightColor,
    Color? highlightTextColor,
    bool isDark = false,
  }) {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty || text.isEmpty) {
      return [TextSpan(text: text, style: style)];
    }

    final effectiveHighlightColor =
        highlightColor ??
        (isDark
            ? const Color(0xFFFFB300).withValues(alpha: 0.38)
            : const Color(0xFFFFF59D));

    final effectiveTextColor =
        highlightTextColor ??
        (isDark ? const Color(0xFFFFFFFF) : const Color(0xFF1E293B));

    final effectiveHighlightStyle =
        highlightStyle ??
        (style ?? const TextStyle()).copyWith(
          backgroundColor: effectiveHighlightColor,
          color: effectiveTextColor,
          fontWeight: AppFontWeight.bold,
        );

    final lowerText = text.toLowerCase();
    final lowerQuery = cleanQuery.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) {
        if (start < text.length) {
          spans.add(TextSpan(text: text.substring(start), style: style));
        }
        break;
      }
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index), style: style));
      }
      spans.add(
        TextSpan(
          text: text.substring(index, index + cleanQuery.length),
          style: effectiveHighlightStyle,
        ),
      );
      start = index + cleanQuery.length;
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty || text.isEmpty) {
      return Text(
        text,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeColors =
        Theme.of(context).extension<AppThemeColors>() ??
        AppThemeColors.ofMode(isDark: isDark, mode: 'normal');

    final spans = buildSpans(
      text: text,
      query: cleanQuery,
      style: style,
      highlightStyle: highlightStyle,
      highlightColor:
          highlightColor ?? themeColors.warningColor.withValues(alpha: 0.35),
      highlightTextColor: highlightTextColor ?? themeColors.textColor,
      isDark: isDark,
    );

    return Text.rich(
      TextSpan(style: style, children: spans),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
