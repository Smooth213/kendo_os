import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../../models/match_model.dart';
import '../models/pdf_point_data.dart';
import '../models/pdf_view_model.dart';

class PdfKachinukiPainter {
  static pw.Widget build(String groupName, List<MatchModel> matches, pw.Font ttf, pw.Font ttfBold) {
    if (matches.isEmpty) return pw.SizedBox();

    final firstMatch = matches.first;
    final note = firstMatch.note;
    final String rTeam = firstMatch.redName.contains(':') ? firstMatch.redName.split(':').first.trim() : firstMatch.redName;
    final String wTeam = firstMatch.whiteName.contains(':') ? firstMatch.whiteName.split(':').first.trim() : firstMatch.whiteName;
    final String titleText = note.isNotEmpty ? '勝ち抜き戦：【$note】 $rTeam vs $wTeam' : '勝ち抜き戦：$rTeam vs $wTeam';

    const double dx = 45.0;       
    const double startX = 45.0;   
    const double height = 280.0;  
    
    const double y0 = 0.0;
    const double y1 = 80.0;       
    const double y2 = 200.0;      
    const double y3 = 280.0;      

    List<PdfPlayerSpan> redSpans = [];
    List<PdfPlayerSpan> whiteSpans = [];
    String currentRed = "", currentWhite = "";

    for (int i = 0; i < matches.length; i++) {
      final rName = matches[i].redName.contains(':') ? matches[i].redName.split(':').last.replaceAll(')', '').trim() : matches[i].redName;
      final wName = matches[i].whiteName.contains(':') ? matches[i].whiteName.split(':').last.replaceAll(')', '').trim() : matches[i].whiteName;

      if (rName != currentRed) { redSpans.add(PdfPlayerSpan(rName, i, i)); currentRed = rName; } else { redSpans.last.endIndex = i; }
      if (wName != currentWhite) { whiteSpans.add(PdfPlayerSpan(wName, i, i)); currentWhite = wName; } else { whiteSpans.last.endIndex = i; }
    }

    final latestMatch = matches.last;
    int currentRedIdx = matches.length;
    for (String name in latestMatch.redRemaining) {
      final cleanName = name.contains(':') ? name.split(':').last.replaceAll(')', '').trim() : name;
      redSpans.add(PdfPlayerSpan(cleanName, currentRedIdx, currentRedIdx));
      currentRedIdx++;
    }

    int currentWhiteIdx = matches.length;
    for (String name in latestMatch.whiteRemaining) {
      final cleanName = name.contains(':') ? name.split(':').last.replaceAll(')', '').trim() : name;
      whiteSpans.add(PdfPlayerSpan(cleanName, currentWhiteIdx, currentWhiteIdx));
      currentWhiteIdx++;
    }

    int totalCols = currentRedIdx > currentWhiteIdx ? currentRedIdx : currentWhiteIdx;
    final double totalWidth = startX + (totalCols * dx);

    void paintBracket(PdfGraphics canvas, PdfPoint size) {
      double invY(double y) => height - y; 

      void drawLine(double x1, double y1, double x2, double y2, {double w = 1.0}) {
        canvas.setStrokeColor(PdfColors.black);
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
        if (span.startIndex > 0) drawLine(left, y0, left, y1);
      }
      for (var span in whiteSpans) {
        double left = startX + (span.startIndex * dx);
        if (span.startIndex > 0) drawLine(left, y2, left, y3);
      }

      for (int i = 0; i < matches.length; i++) {
        var match = matches[i];
        bool isDone = match.status == 'finished' || match.status == 'approved';
        if (!isDone) continue;

        var rSpan = redSpans.firstWhere((s) => i >= s.startIndex && i <= s.endIndex);
        var wSpan = whiteSpans.firstWhere((s) => i >= s.startIndex && i <= s.endIndex);
        
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

    pw.Widget vertText(String text, double x, double y, double w, double h, pw.Font font, {bool isBold = false, double fSize = 9}) {
      final chars = text.split('');
      return pw.Positioned(
        left: x, top: y,
        child: pw.Container(width: w, height: h, child: pw.Center(child: pw.Column(mainAxisAlignment: pw.MainAxisAlignment.center, children: chars.map((c) {
          if (c == 'ー' || c == '-') return pw.Container(width: 1, height: fSize * 0.8, color: PdfColors.black, margin: const pw.EdgeInsets.symmetric(vertical: 1));
          if (c == '(' || c == ')' || c == '（' || c == '）') return pw.Text(c, style: pw.TextStyle(font: font, fontSize: fSize * 0.8, fontWeight: isBold ? pw.FontWeight.bold : null));
          return pw.Text(c, style: pw.TextStyle(font: font, fontSize: fSize, fontWeight: isBold ? pw.FontWeight.bold : null));
        }).toList())))
      );
    }

    textWidgets.add(vertText(rTeam, 0, y0, startX, y1 - y0, ttfBold, isBold: true, fSize: 11));
    textWidgets.add(vertText(wTeam, 0, y2, startX, y3 - y2, ttfBold, isBold: true, fSize: 11));

    for (var span in redSpans) { double left = startX + (span.startIndex * dx); double w = ((span.endIndex - span.startIndex) + 1) * dx; textWidgets.add(vertText(span.name, left, y0, w, y1 - y0, ttf)); }
    for (var span in whiteSpans) { double left = startX + (span.startIndex * dx); double w = ((span.endIndex - span.startIndex) + 1) * dx; textWidgets.add(vertText(span.name, left, y2, w, y3 - y2, ttf)); }

    for (int i = 0; i < matches.length; i++) {
      var match = matches[i];
      if (!(match.status == 'finished' || match.status == 'approved')) continue;
      var ptsMap = PdfViewModel.calculatePointsRaw(match);
      double leftX = startX + (i * dx);
      if (ptsMap['red']!.length > ptsMap['white']!.length) { textWidgets.add(pw.Positioned(left: leftX, top: y1 + 5, child: pw.Container(width: dx, child: pw.Center(child: _pdfScoreColumn(ptsMap['red']!, ttfBold))))); } 
      else if (ptsMap['white']!.length > ptsMap['red']!.length) { textWidgets.add(pw.Positioned(left: leftX, bottom: (height - y2) + 5, child: pw.Container(width: dx, child: pw.Center(child: _pdfScoreColumn(ptsMap['white']!, ttfBold, reverse: true))))); }
    }

    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text(titleText, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: ttfBold, fontSize: 12)),
      pw.SizedBox(height: 8),
      pw.FittedBox(fit: pw.BoxFit.scaleDown, alignment: pw.Alignment.centerLeft, child: pw.Container(width: totalWidth, height: height, child: pw.Stack(children: [pw.CustomPaint(size: PdfPoint(totalWidth, height), painter: paintBracket), ...textWidgets])))
    ]);
  }

  static pw.Widget _pdfScoreColumn(List<PdfPointData> pts, pw.Font ttfBold, {bool reverse = false}) {
    final widgets = pts.map((p) { final text = pw.Text(p.mark, style: pw.TextStyle(font: ttfBold, fontSize: 9)); if (p.isFirstOverall && p.mark != '◯') { return pw.Container(margin: const pw.EdgeInsets.symmetric(vertical: 1), padding: const pw.EdgeInsets.all(2), decoration: pw.BoxDecoration(shape: pw.BoxShape.circle, border: pw.Border.all(color: PdfColors.black, width: 1)), child: text); } return pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 2), child: text); }).toList();
    return pw.Column(mainAxisSize: pw.MainAxisSize.min, children: reverse ? widgets.reversed.toList() : widgets);
  }
}