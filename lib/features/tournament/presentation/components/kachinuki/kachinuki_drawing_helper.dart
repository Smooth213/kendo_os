import 'package:flutter/material.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/tournament/presentation/components/kachinuki/kachinuki_span_builder.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';

/// 勝ち抜き戦の文字・延長表記・スコアマーク描画ヘルパー
class KachinukiDrawingHelper {
  static void drawEnchoTextCenter(Canvas canvas, Offset center, bool isDark) {
    const double width = 16.0;
    const double height = 26.0;
    final bgPaint = Paint()
      ..color = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF);
    final borderPaint = Paint()
      ..color = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF64748B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final rect = Rect.fromCenter(center: center, width: width, height: height);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(AppRadius.tinyValue)),
      bgPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(AppRadius.tinyValue)),
      borderPaint,
    );

    final textStyle = TextStyle(
      color: isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000),
      fontSize: AppFontSize.nano,
      fontWeight: AppFontWeight.bold,
      fontFamily: 'Noto Sans JP',
    );

    final tpEn = TextPainter(
      text: TextSpan(text: '延', style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    tpEn.paint(canvas, Offset(center.dx - (tpEn.width / 2), center.dy - 11));

    final tpCho = TextPainter(
      text: TextSpan(text: '長', style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    tpCho.paint(canvas, Offset(center.dx - (tpCho.width / 2), center.dy + 1));
  }

  static void drawVerticalText(
    Canvas canvas,
    PlayerSpan? span,
    String teamName,
    Offset center,
    bool isTeamName,
    bool isDark, {
    Color? customColor,
  }) {
    double availableHeight = 130.0;
    double charHeight = 22.0;
    double fontSize = isTeamName ? 18.0 : 16.0;

    final Color textColor =
        customColor ??
        (isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000));

    if (!isTeamName && span != null && span.rawName.contains('欠員')) {
      final tp = TextPainter(
        text: const TextSpan(
          text: '(欠員)',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: AppFontSize.bodySmall,
            fontWeight: AppFontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(center.dx - (tp.width / 2), center.dy - (tp.height / 2)),
      );
      return;
    }

    String text = isTeamName ? teamName : span!.lastName;
    final chars = text.split('');
    if (chars.length * charHeight > availableHeight) {
      charHeight = availableHeight / chars.length;
      fontSize = charHeight * 0.8;
    }

    final textStyle = TextStyle(
      color: textColor,
      fontSize: fontSize,
      fontWeight: isTeamName ? AppFontWeight.black : AppFontWeight.bold,
      fontFamily: 'Noto Sans JP',
    );

    double y = center.dy - ((chars.length * charHeight) / 2) + (charHeight / 2);
    for (var char in chars) {
      final tp = TextPainter(
        text: TextSpan(text: char, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(center.dx - (tp.width / 2), y - (tp.height / 2)));
      y += charHeight;
    }

    if (!isTeamName && span != null && span.initial.isNotEmpty) {
      final tp = TextPainter(
        text: TextSpan(
          text: span.initial,
          style: textStyle.copyWith(
            fontSize: fontSize * 0.65,
            color: isDark ? const Color(0xFFFFFFFF) : const Color(0xFF64748B),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(center.dx + (fontSize * 0.2), y - (charHeight * 0.8)),
      );
    }
  }

  static void drawSmallCross(Canvas canvas, Offset center, Paint paint) {
    const double size = 8.0;
    canvas.drawLine(
      Offset(center.dx - size, center.dy - size),
      Offset(center.dx + size, center.dy + size),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx + size, center.dy - size),
      Offset(center.dx - size, center.dy + size),
      paint,
    );
  }

  static void drawScoreMarksVertical(
    Canvas canvas,
    List<PointDisplay> pts,
    Offset baseAnchor,
    bool isRed,
  ) {
    double y = isRed ? baseAnchor.dy : baseAnchor.dy - (pts.length * 24.0);
    final Color color = isRed
        ? const Color(0xFFE53935)
        : const Color(0xFF3F51B5);

    final textStyle = TextStyle(
      color: color,
      fontSize: AppFontSize.bodyMedium,
      fontWeight: AppFontWeight.black,
    );
    final circlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (var p in pts) {
      final tp = TextPainter(
        text: TextSpan(text: p.mark, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(baseAnchor.dx - (tp.width / 2), y));
      if (p.isFirstMatchPoint && p.mark != '◯') {
        canvas.drawCircle(
          Offset(baseAnchor.dx, y + (tp.height / 2)),
          11.5,
          circlePaint,
        );
      }
      y += 24.0;
    }
  }
}
