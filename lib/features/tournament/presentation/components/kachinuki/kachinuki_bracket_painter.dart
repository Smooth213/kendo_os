import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/tournament/presentation/components/kachinuki/kachinuki_drawing_helper.dart';
import 'package:kendo_os/features/tournament/presentation/components/kachinuki/kachinuki_span_builder.dart';
import 'package:kendo_os/shared/application/projections/match_projection.dart';

export 'kachinuki_span_builder.dart';

class KachinukiBracketPainter extends CustomPainter {
  final List<MatchProjection> matches;
  final bool isDark;
  final WidgetRef? ref;

  KachinukiBracketPainter({
    required this.matches,
    this.isDark = false,
    this.ref,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (matches.isEmpty) return;

    final Color redWinColor = const Color(0xFFE53935);
    final Color whiteWinColor = const Color(0xFF3F51B5);
    final Color centerLineColor = const Color(0xFF3F51B5);
    final Color baseLineColor = isDark
        ? const Color(0xFFFFFFFF)
        : const Color(0x33000000);
    final Color drawLineColor = isDark
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF64748B);
    final Color drawCrossColor = const Color(0xFFD4AF37);

    final redBgPaint = Paint()
      ..color = isDark
          ? const Color(0xFFE53935).withValues(alpha: 0.08)
          : const Color(0xFFE53935).withValues(alpha: 0.03);
    final whiteBgPaint = Paint()
      ..color = isDark
          ? const Color(0xFF3F51B5).withValues(alpha: 0.12)
          : const Color(0xFF3F51B5).withValues(alpha: 0.03);

    final thickLinePaint = Paint()
      ..color = centerLineColor
      ..strokeWidth = 2.5;
    final thinLinePaint = Paint()
      ..color = baseLineColor
      ..strokeWidth = 1.0;

    const double dx = 60.0;
    const double startX = 60.0;
    const double y0 = 0.0;
    const double y1 = 150.0;
    const double y2 = 350.0;
    const double y3 = 500.0;

    canvas.drawRect(
      Rect.fromLTRB(0, y0, size.width, (y1 + y2) / 2),
      redBgPaint,
    );
    canvas.drawRect(
      Rect.fromLTRB(0, (y1 + y2) / 2, size.width, y3),
      whiteBgPaint,
    );

    final String rTeam = matches.first.redName.contains(':')
        ? matches.first.redName.split(':').first.trim()
        : '赤チーム';
    final String wTeam = matches.first.whiteName.contains(':')
        ? matches.first.whiteName.split(':').first.trim()
        : '白チーム';

    final spans = KachinukiSpanBuilder.buildSpans(matches);
    final redSpans = spans.redSpans;
    final whiteSpans = spans.whiteSpans;

    final totalWidth = startX + (spans.totalCols * dx);

    canvas.drawRect(
      Rect.fromLTRB(0, y0, totalWidth, y3),
      thickLinePaint..style = PaintingStyle.stroke,
    );
    canvas.drawLine(
      const Offset(0, y1),
      Offset(totalWidth, y1),
      thickLinePaint,
    );
    canvas.drawLine(
      const Offset(0, y2),
      Offset(totalWidth, y2),
      thickLinePaint,
    );
    canvas.drawLine(
      const Offset(startX, y0),
      const Offset(startX, y3),
      thickLinePaint,
    );

    KachinukiDrawingHelper.drawVerticalText(
      canvas,
      null,
      rTeam,
      const Offset(startX / 2, (y0 + y1) / 2),
      true,
      isDark,
      customColor: redWinColor,
    );
    KachinukiDrawingHelper.drawVerticalText(
      canvas,
      null,
      wTeam,
      const Offset(startX / 2, (y2 + y3) / 2),
      true,
      isDark,
    );

    for (var span in redSpans) {
      double left = startX + (span.startIndex * dx);
      double right = startX + ((span.endIndex + 1) * dx);
      canvas.drawRect(
        Rect.fromLTRB(left, y0, right, y1),
        thinLinePaint..style = PaintingStyle.stroke,
      );
      KachinukiDrawingHelper.drawVerticalText(
        canvas,
        span,
        '',
        Offset((left + right) / 2, (y0 + y1) / 2),
        false,
        isDark,
      );
    }

    for (var span in whiteSpans) {
      double left = startX + (span.startIndex * dx);
      double right = startX + ((span.endIndex + 1) * dx);
      canvas.drawRect(
        Rect.fromLTRB(left, y2, right, y3),
        thinLinePaint..style = PaintingStyle.stroke,
      );
      KachinukiDrawingHelper.drawVerticalText(
        canvas,
        span,
        '',
        Offset((left + right) / 2, (y2 + y3) / 2),
        false,
        isDark,
      );
    }

    for (int i = 0; i < matches.length; i++) {
      var match = matches[i];
      if (match.status != 'finished' && match.status != 'approved') continue;
      var rSpan = redSpans.firstWhere(
        (s) => i >= s.startIndex && i <= s.endIndex,
      );
      var wSpan = whiteSpans.firstWhere(
        (s) => i >= s.startIndex && i <= s.endIndex,
      );
      Offset redTopVertex = Offset(
        startX + (rSpan.startIndex + rSpan.endIndex + 1) * dx / 2,
        y1,
      );
      Offset whiteBottomVertex = Offset(
        startX + (wSpan.startIndex + wSpan.endIndex + 1) * dx / 2,
        y2,
      );

      Color currentWinColor = baseLineColor;
      double strokeW = 1.0;

      if (match.redScore > match.whiteScore) {
        currentWinColor = redWinColor;
        strokeW = 2.0;
      } else if (match.whiteScore > match.redScore) {
        currentWinColor = whiteWinColor;
        strokeW = 2.0;
      } else {
        currentWinColor = drawLineColor;
        strokeW = 1.5;
      }

      canvas.drawLine(
        redTopVertex,
        whiteBottomVertex,
        Paint()
          ..color = currentWinColor
          ..strokeWidth = strokeW,
      );

      final isEncho =
          match.note.contains('延長') ||
          match.matchType == '代表戦' ||
          match.matchType == '大将延長戦' ||
          match.matchType.contains('代表') ||
          match.matchType.contains('延長');

      if (match.redScore == match.whiteScore) {
        KachinukiDrawingHelper.drawSmallCross(
          canvas,
          Offset(
            (redTopVertex.dx + whiteBottomVertex.dx) / 2,
            (redTopVertex.dy + whiteBottomVertex.dy) / 2,
          ),
          Paint()
            ..color = drawCrossColor
            ..strokeWidth = 3.0,
        );
      } else {
        if (isEncho) {
          KachinukiDrawingHelper.drawEnchoTextCenter(
            canvas,
            Offset(
              (redTopVertex.dx + whiteBottomVertex.dx) / 2,
              (redTopVertex.dy + whiteBottomVertex.dy) / 2,
            ),
            isDark,
          );
        }
        if (match.redScore > match.whiteScore) {
          KachinukiDrawingHelper.drawScoreMarksVertical(
            canvas,
            match.redDisplays,
            Offset(startX + (i * dx) + dx / 2, y1 + 15),
            true,
          );
        } else {
          KachinukiDrawingHelper.drawScoreMarksVertical(
            canvas,
            match.whiteDisplays,
            Offset(startX + (i * dx) + dx / 2, y2 - 15),
            false,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant KachinukiBracketPainter oldDelegate) {
    if (oldDelegate.isDark != isDark) return true;
    if (oldDelegate.matches.length != matches.length) return true;
    for (int i = 0; i < matches.length; i++) {
      final o = oldDelegate.matches[i];
      final n = matches[i];
      if (o.status != n.status ||
          o.redScore != n.redScore ||
          o.whiteScore != n.whiteScore ||
          o.redName != n.redName ||
          o.whiteName != n.whiteName ||
          o.note != n.note) {
        return true;
      }
    }
    return false;
  }
}
