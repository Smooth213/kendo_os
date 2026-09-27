import 'package:kendo_os/features/tournament/presentation/operate/providers/team_progress_helper.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:kendo_os/features/pdf/models/pdf_point_data.dart';
import 'package:kendo_os/features/pdf/models/pdf_view_model.dart';

class PdfKachinukiPainter {
  static pw.Widget build(
    String groupName,
    List<dynamic> matches,
    pw.Font ttf,
    pw.Font ttfBold,
  ) {
    if (matches.isEmpty) return pw.SizedBox();

    final firstMatch = matches.first;
    final note = firstMatch.note;
    final String rTeam = firstMatch.redName.contains(':')
        ? firstMatch.redName.split(':').first.trim()
        : firstMatch.redName;
    final String wTeam = firstMatch.whiteName.contains(':')
        ? firstMatch.whiteName.split(':').first.trim()
        : firstMatch.whiteName;

    final scenePrefix = TeamProgressHelper.getScenePrefixFromDynamic(
      firstMatch,
    );
    final String titleText = note.isNotEmpty
        ? '$scenePrefix勝ち抜き戦：【$note】 $rTeam vs $wTeam'
        : '$scenePrefix勝ち抜き戦：$rTeam vs $wTeam';

    const double dx = 45.0;
    const double startX = 60.0;
    const double height = 155.0;

    const double y0 = 0.0;
    const double y1 = 45.0;
    const double y2 = 110.0;
    const double y3 = 155.0;

    List<PdfPlayerSpan> redSpans = [];
    List<PdfPlayerSpan> whiteSpans = [];
    String currentRed = "", currentWhite = "";

    for (int i = 0; i < matches.length; i++) {
      final rName = matches[i].redName.contains(':')
          ? matches[i].redName.split(':').last.replaceAll(')', '').trim()
          : matches[i].redName;
      final wName = matches[i].whiteName.contains(':')
          ? matches[i].whiteName.split(':').last.replaceAll(')', '').trim()
          : matches[i].whiteName;

      if (rName != currentRed) {
        redSpans.add(PdfPlayerSpan(rName, i, i));
        currentRed = rName;
      } else {
        redSpans.last.endIndex = i;
      }
      if (wName != currentWhite) {
        whiteSpans.add(PdfPlayerSpan(wName, i, i));
        currentWhite = wName;
      } else {
        whiteSpans.last.endIndex = i;
      }
    }

    final latestMatch = matches.last;
    List<dynamic> rRemaining = [];
    List<dynamic> wRemaining = [];
    try {
      rRemaining = latestMatch.redRemaining;
      wRemaining = latestMatch.whiteRemaining;
    } catch (_) {}

    int currentRedIdx = matches.length;
    for (String name in rRemaining) {
      final cleanName = name.contains(':')
          ? name.split(':').last.replaceAll(')', '').trim()
          : name;
      redSpans.add(PdfPlayerSpan(cleanName, currentRedIdx, currentRedIdx));
      currentRedIdx++;
    }

    int currentWhiteIdx = matches.length;
    for (String name in wRemaining) {
      final cleanName = name.contains(':')
          ? name.split(':').last.replaceAll(')', '').trim()
          : name;
      whiteSpans.add(
        PdfPlayerSpan(cleanName, currentWhiteIdx, currentWhiteIdx),
      );
      currentWhiteIdx++;
    }

    int totalCols = currentRedIdx > currentWhiteIdx
        ? currentRedIdx
        : currentWhiteIdx;
    final double totalWidth = startX + (totalCols * dx);

    void paintBracket(PdfGraphics canvas, PdfPoint size) {
      double invY(double y) => height - y;

      void drawLine(
        double x1,
        double y1,
        double x2,
        double y2, {
        double w = 1.0,
        PdfColor color = PdfColors.black,
      }) {
        canvas.setStrokeColor(color);
        canvas.setLineWidth(w);
        canvas.drawLine(x1, invY(y1), x2, invY(y2));
        canvas.strokePath();
      }

      void drawRect(double x, double y, double w, double h, {double lw = 1.0}) {
        canvas.setStrokeColor(PdfColors.black);
        canvas.setLineWidth(lw);
        canvas.drawRect(x, invY(y + h), w, h);
        canvas.strokePath();
      }

      drawRect(0, 0, totalWidth, height, lw: 2.0);
      drawLine(0, y1, totalWidth, y1, w: 2.0);
      drawLine(0, y2, totalWidth, y2, w: 2.0);
      drawLine(startX, 0, startX, height, w: 2.0);

      for (var span in redSpans) {
        double left = startX + (span.startIndex * dx);
        if (span.startIndex > 0) {
          drawLine(left, y0, left, y1, color: PdfColors.red700);
        }
      }
      for (var span in whiteSpans) {
        double left = startX + (span.startIndex * dx);
        if (span.startIndex > 0) {
          drawLine(left, y2, left, y3, color: PdfColors.black);
        }
      }

      for (int i = 0; i < matches.length; i++) {
        var match = matches[i];
        bool isDone = match.status == 'finished' || match.status == 'approved';
        if (!isDone) continue;

        var rSpan = redSpans.firstWhere(
          (s) => i >= s.startIndex && i <= s.endIndex,
        );
        var wSpan = whiteSpans.firstWhere(
          (s) => i >= s.startIndex && i <= s.endIndex,
        );

        double rx = startX + (rSpan.startIndex + rSpan.endIndex + 1) * dx / 2;
        double wx = startX + (wSpan.startIndex + wSpan.endIndex + 1) * dx / 2;

        var ptsMap = PdfViewModel.calculatePointsRaw(match);
        int rPts = ptsMap['red']!.length;
        int wPts = ptsMap['white']!.length;

        drawLine(rx, y1, wx, y2, w: 1.0);

        if (rPts == wPts) {
          double cx = (rx + wx) / 2;
          double cy = (y1 + y2) / 2;
          double s = 4.0;
          drawLine(cx - s, cy - s, cx + s, cy + s, w: 1.5);
          drawLine(cx + s, cy - s, cx - s, cy + s, w: 1.5);
        }
      }
    }

    List<pw.Widget> textWidgets = [];

    pw.Widget teamText(
      String name,
      double x,
      double y,
      double w,
      double h,
      pw.Font fontBold, {
      required PdfColor color,
    }) {
      final double fontSize = name.length > 20
          ? 6.0
          : (name.length > 12
                ? 7.0
                : (name.length > 8 ? 8.0 : AppFontSize.badge));
      final String displayName = name.length > 25
          ? '${name.substring(0, 24)}…'
          : name;

      final double availableW = w - (AppSpacing.xxs * 2);

      return pw.Positioned(
        left: x,
        top: y,
        child: pw.Container(
          width: w,
          height: h,
          padding: const pw.EdgeInsets.symmetric(
            horizontal: AppSpacing.xxs,
            vertical: AppSpacing.xxs,
          ),
          child: pw.Center(
            child: pw.FittedBox(
              fit: pw.BoxFit.scaleDown,
              alignment: pw.Alignment.center,
              child: pw.SizedBox(
                width: availableW,
                child: pw.Text(
                  displayName,
                  style: pw.TextStyle(
                    color: color,
                    fontWeight: pw.FontWeight.bold,
                    font: fontBold,
                    fontSize: fontSize,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      );
    }

    Map<String, String> parsePlayerName(String raw) {
      if (raw.contains('欠員')) return {'last': '', 'first': ''};
      String clean = raw.contains(':')
          ? raw.split(':').last.replaceAll(RegExp(r'[()（）]'), '').trim()
          : raw.replaceAll(RegExp(r'[()（）]'), '').trim();
      var parts = clean.split(RegExp(r'\s+'));
      return {'last': parts[0], 'first': parts.length > 1 ? parts[1] : ''};
    }

    final List<String> redTeamLastNames = redSpans
        .map((s) => parsePlayerName(s.name)['last']!)
        .where((s) => s.isNotEmpty)
        .toList();
    final List<String> whiteTeamLastNames = whiteSpans
        .map((s) => parsePlayerName(s.name)['last']!)
        .where((s) => s.isNotEmpty)
        .toList();

    pw.Widget playerCell(
      String rawName,
      List<String> teamLastNames,
      double x,
      double y,
      double w,
      double h,
      pw.Font font,
    ) {
      if (rawName.contains('欠員')) return pw.SizedBox();
      final parsed = parsePlayerName(rawName);
      final rawLastName = parsed['last']!;
      final firstName = parsed['first']!;

      // 極長選手名でも縦書きが枠高さを突破しないよう最大8文字ガード
      final lastName = rawLastName.length > 8
          ? '${rawLastName.substring(0, 7)}…'
          : rawLastName;
      final double fontSize = lastName.length > 5 ? 7.0 : 9.0;

      final showInitial =
          teamLastNames.where((n) => n == rawLastName).length > 1 &&
          firstName.isNotEmpty;

      return pw.Positioned(
        left: x,
        top: y,
        child: pw.Container(
          width: w,
          height: h,
          padding: const pw.EdgeInsets.symmetric(
            vertical: AppSpacing.xs,
            horizontal: 2.0,
          ),
          child: pw.Center(
            child: pw.FittedBox(
              fit: pw.BoxFit.scaleDown,
              alignment: pw.Alignment.center,
              child: pw.Row(
                mainAxisSize: pw.MainAxisSize.min,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    lastName.split('').join('\n'),
                    style: pw.TextStyle(
                      font: font,
                      fontSize: fontSize,
                      color: PdfColors.black,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  if (showInitial)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(left: 1.0, bottom: 0.0),
                      child: pw.Text(
                        firstName.substring(0, 1),
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 6.0,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    textWidgets.add(
      teamText(rTeam, 0, y0, startX, y1 - y0, ttfBold, color: PdfColors.red700),
    );
    textWidgets.add(
      teamText(wTeam, 0, y2, startX, y3 - y2, ttfBold, color: PdfColors.black),
    );

    for (var span in redSpans) {
      double left = startX + (span.startIndex * dx);
      double w = ((span.endIndex - span.startIndex) + 1) * dx;
      textWidgets.add(
        playerCell(span.name, redTeamLastNames, left, y0, w, y1 - y0, ttf),
      );
    }
    for (var span in whiteSpans) {
      double left = startX + (span.startIndex * dx);
      double w = ((span.endIndex - span.startIndex) + 1) * dx;
      textWidgets.add(
        playerCell(span.name, whiteTeamLastNames, left, y2, w, y3 - y2, ttf),
      );
    }

    for (int i = 0; i < matches.length; i++) {
      var match = matches[i];
      if (!(match.status == 'finished' || match.status == 'approved')) continue;
      var ptsMap = PdfViewModel.calculatePointsRaw(match);
      double leftX = startX + (i * dx);
      if (ptsMap['red']!.length > ptsMap['white']!.length) {
        textWidgets.add(
          pw.Positioned(
            left: leftX,
            top: y1 + 5,
            child: pw.Container(
              width: dx,
              child: pw.Center(
                child: _pdfScoreColumn(
                  ptsMap['red']!,
                  ttfBold,
                  color: PdfColors.red700,
                ),
              ),
            ),
          ),
        );
      } else if (ptsMap['white']!.length > ptsMap['red']!.length) {
        textWidgets.add(
          pw.Positioned(
            left: leftX,
            bottom: (height - y2) + 5,
            child: pw.Container(
              width: dx,
              child: pw.Center(
                child: _pdfScoreColumn(
                  ptsMap['white']!,
                  ttfBold,
                  reverse: true,
                  color: PdfColors.black,
                ),
              ),
            ),
          ),
        );
      }
    }

    return pw.Inseparable(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            titleText,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              font: ttfBold,
              fontSize: AppFontSize.small,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.FittedBox(
            fit: pw.BoxFit.scaleDown,
            alignment: pw.Alignment.centerLeft,
            child: pw.Container(
              width: totalWidth,
              height: height,
              child: pw.Stack(
                children: [
                  pw.CustomPaint(
                    size: PdfPoint(totalWidth, height),
                    painter: paintBracket,
                  ),
                  ...textWidgets,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _pdfScoreColumn(
    List<PdfPointData> pts,
    pw.Font ttfBold, {
    bool reverse = false,
    PdfColor color = PdfColors.black,
  }) {
    final widgets = pts.map((p) {
      final text = pw.Text(
        p.mark,
        style: pw.TextStyle(font: ttfBold, fontSize: 9, color: color),
      );
      if (p.isFirstOverall && p.mark != '◯') {
        return pw.Container(
          margin: const pw.EdgeInsets.symmetric(vertical: 1),
          padding: const pw.EdgeInsets.all(AppSpacing.xxs),
          decoration: pw.BoxDecoration(
            shape: pw.BoxShape.circle,
            border: pw.Border.all(color: color, width: 1),
          ),
          child: text,
        );
      }
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: AppSpacing.xxs),
        child: text,
      );
    }).toList();
    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      children: reverse ? widgets.reversed.toList() : widgets,
    );
  }
}
