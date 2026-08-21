import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/shared/application/projections/match_projection.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';

class PlayerSpan {
  final String rawName;
  final String lastName;
  final String initial;
  final int startIndex;
  int endIndex;
  PlayerSpan(
    this.rawName,
    this.lastName,
    this.initial,
    this.startIndex,
    this.endIndex,
  );
}

class KachinukiBracketPainter extends CustomPainter {
  final List<MatchProjection> matches;
  final bool isDark;
  final WidgetRef? ref;

  KachinukiBracketPainter({
    required this.matches,
    this.isDark = false,
    this.ref,
  });

  Map<String, String> _parse(String raw) {
    if (raw.contains('欠員')) {
      return {'last': '', 'first': ''};
    }
    String clean = raw.contains(':')
        ? raw.split(':').last.replaceAll(RegExp(r'[()（）]'), '').trim()
        : raw.trim();
    var parts = clean.split(RegExp(r'\s+'));
    return {'last': parts[0], 'first': parts.length > 1 ? parts[1] : ''};
  }

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

    final double dx = 60.0;
    final double startX = 60.0;
    final double y0 = 0.0;
    final double y1 = 150.0;
    final double y2 = 350.0;
    final double y3 = 500.0;

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

    List<String> rAllRaw = matches.map((m) => m.redName).toList()
      ..addAll(matches.last.redRemaining);
    List<String> wAllRaw = matches.map((m) => m.whiteName).toList()
      ..addAll(matches.last.whiteRemaining);
    List<String> rLasts = rAllRaw
        .map((n) => _parse(n)['last']!)
        .where((s) => s.isNotEmpty)
        .toList();
    List<String> wLasts = wAllRaw
        .map((n) => _parse(n)['last']!)
        .where((s) => s.isNotEmpty)
        .toList();

    List<PlayerSpan> redSpans = [];
    List<PlayerSpan> whiteSpans = [];
    String currentRed = "", currentWhite = "";

    for (int i = 0; i < matches.length; i++) {
      final rRaw = matches[i].redName;
      final wRaw = matches[i].whiteName;
      final rP = _parse(rRaw);
      final rShow =
          rLasts.where((n) => n == rP['last']).length > 1 &&
          rP['first']!.isNotEmpty;
      if (rRaw != currentRed) {
        redSpans.add(
          PlayerSpan(
            rRaw,
            rP['last']!,
            rShow ? rP['first']!.substring(0, 1) : '',
            i,
            i,
          ),
        );
        currentRed = rRaw;
      } else {
        redSpans.last.endIndex = i;
      }

      final wP = _parse(wRaw);
      final wShow =
          wLasts.where((n) => n == wP['last']).length > 1 &&
          wP['first']!.isNotEmpty;
      if (wRaw != currentWhite) {
        whiteSpans.add(
          PlayerSpan(
            wRaw,
            wP['last']!,
            wShow ? wP['first']!.substring(0, 1) : '',
            i,
            i,
          ),
        );
        currentWhite = wRaw;
      } else {
        whiteSpans.last.endIndex = i;
      }
    }

    int currentRedIdx = matches.length;
    for (String name in matches.last.redRemaining) {
      final p = _parse(name);
      final show =
          rLasts.where((n) => n == p['last']).length > 1 &&
          p['first']!.isNotEmpty;
      redSpans.add(
        PlayerSpan(
          name,
          p['last']!,
          show ? p['first']!.substring(0, 1) : '',
          currentRedIdx,
          currentRedIdx,
        ),
      );
      currentRedIdx++;
    }

    int currentWhiteIdx = matches.length;
    for (String name in matches.last.whiteRemaining) {
      final p = _parse(name);
      final show =
          wLasts.where((n) => n == p['last']).length > 1 &&
          p['first']!.isNotEmpty;
      whiteSpans.add(
        PlayerSpan(
          name,
          p['last']!,
          show ? p['first']!.substring(0, 1) : '',
          currentWhiteIdx,
          currentWhiteIdx,
        ),
      );
      currentWhiteIdx++;
    }

    int totalCols = currentRedIdx > currentWhiteIdx
        ? currentRedIdx
        : currentWhiteIdx;
    final totalWidth = startX + (totalCols * dx);

    canvas.drawRect(
      Rect.fromLTRB(0, y0, totalWidth, y3),
      thickLinePaint..style = PaintingStyle.stroke,
    );
    canvas.drawLine(Offset(0, y1), Offset(totalWidth, y1), thickLinePaint);
    canvas.drawLine(Offset(0, y2), Offset(totalWidth, y2), thickLinePaint);
    canvas.drawLine(Offset(startX, y0), Offset(startX, y3), thickLinePaint);

    _drawVerticalText(
      canvas,
      null,
      rTeam,
      Offset(startX / 2, (y0 + y1) / 2),
      true,
      customColor: redWinColor,
    );
    _drawVerticalText(
      canvas,
      null,
      wTeam,
      Offset(startX / 2, (y2 + y3) / 2),
      true,
    );

    for (var span in redSpans) {
      double left = startX + (span.startIndex * dx);
      double right = startX + ((span.endIndex + 1) * dx);
      canvas.drawRect(
        Rect.fromLTRB(left, y0, right, y1),
        thinLinePaint..style = PaintingStyle.stroke,
      );
      _drawVerticalText(
        canvas,
        span,
        '',
        Offset((left + right) / 2, (y0 + y1) / 2),
        false,
      );
    }

    for (var span in whiteSpans) {
      double left = startX + (span.startIndex * dx);
      double right = startX + ((span.endIndex + 1) * dx);
      canvas.drawRect(
        Rect.fromLTRB(left, y2, right, y3),
        thinLinePaint..style = PaintingStyle.stroke,
      );
      _drawVerticalText(
        canvas,
        span,
        '',
        Offset((left + right) / 2, (y2 + y3) / 2),
        false,
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
        _drawSmallCross(
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
          _drawEnchoTextCenter(
            canvas,
            Offset(
              (redTopVertex.dx + whiteBottomVertex.dx) / 2,
              (redTopVertex.dy + whiteBottomVertex.dy) / 2,
            ),
            isDark,
          );
        }
        if (match.redScore > match.whiteScore) {
          _drawScoreMarksVertical(
            canvas,
            match.redDisplays,
            Offset(startX + (i * dx) + dx / 2, y1 + 15),
            true,
          );
        } else {
          _drawScoreMarksVertical(
            canvas,
            match.whiteDisplays,
            Offset(startX + (i * dx) + dx / 2, y2 - 15),
            false,
          );
        }
      }
    }
  }

  void _drawEnchoTextCenter(Canvas canvas, Offset center, bool isDark) {
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

  void _drawVerticalText(
    Canvas canvas,
    PlayerSpan? span,
    String teamName,
    Offset center,
    bool isTeamName, {
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

  void _drawSmallCross(Canvas canvas, Offset center, Paint paint) {
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

  void _drawScoreMarksVertical(
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
