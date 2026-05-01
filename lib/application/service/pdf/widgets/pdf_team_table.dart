import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../../models/match_model.dart';
import '../models/pdf_point_data.dart';
import '../models/pdf_view_model.dart';

class PdfTeamTable {
  static pw.Widget build(String groupName, List<MatchModel> matches, pw.Font ttf, pw.Font ttfBold) {
    if (matches.isEmpty) return pw.SizedBox();

    final note = matches.first.note;
    final cleanNote = note.replaceAll('[', '').replaceAll(']', '').trim();

    final redTeam = matches.first.redName.split(':').first;
    final whiteTeam = matches.first.whiteName.split(':').first;

    Map<String, String> parse(String raw) {
      if (raw.contains('欠員')) return {'last': '', 'first': ''};
      String clean = raw.contains(':') ? raw.split(':').last.replaceAll(RegExp(r'[()（）]'), '').trim() : raw.trim();
      var parts = clean.split(RegExp(r'\s+'));
      return {'last': parts[0], 'first': parts.length > 1 ? parts[1] : ''};
    }
    List<String> rLasts = matches.map((m) => parse(m.redName)['last']!).where((s) => s.isNotEmpty).toList();
    List<String> wLasts = matches.map((m) => parse(m.whiteName)['last']!).where((s) => s.isNotEmpty).toList();

    final allFinished = matches.every((m) => m.status == 'finished' || m.status == 'approved');
    String teamWinner = 'none';

    if (allFinished) {
      teamWinner = 'draw';
      int rWins = 0, wWins = 0, rPts = 0, wPts = 0;
      MatchModel? daihyo;
      for (var m in matches) {
        final rs = (m.redScore as num).toInt(); 
        final ws = (m.whiteScore as num).toInt();
        rPts += rs; 
        wPts += ws;
        if (rs > ws) { rWins++; } else if (ws > rs) { wWins++; }
        if (m.matchType == '代表戦') { daihyo = m; }
      }
      if (rWins > wWins) { teamWinner = 'red'; }
      else if (wWins > rWins) { teamWinner = 'white'; }
      else if (rPts > wPts) { teamWinner = 'red'; }
      else if (wPts > rPts) { teamWinner = 'white'; }
      else if (daihyo != null) {
        final rs = (daihyo.redScore as num).toInt(); 
        final ws = (daihyo.whiteScore as num).toInt();
        if (rs > ws) { teamWinner = 'red'; } else if (ws > rs) { teamWinner = 'white'; }
      }
    }

    final String titleText = cleanNote.isNotEmpty ? '【$cleanNote】 $redTeam vs $whiteTeam' : '$redTeam vs $whiteTeam';
    
    final Map<int, pw.TableColumnWidth> columnWidths = {
      0: const pw.FlexColumnWidth(1.4), 
      for (int i = 1; i <= matches.length; i++) i: const pw.FlexColumnWidth(1.0),
      matches.length + 1: const pw.FlexColumnWidth(1.0), 
    };

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(6), color: PdfColors.grey200, width: double.infinity,
          child: pw.Text(titleText, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: ttfBold, fontSize: 11)),
        ),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.black, width: 1),
          columnWidths: columnWidths,
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                pw.SizedBox(),
                ...matches.map((m) => pw.Center(child: pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(m.matchType, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, font: ttfBold))))),
                pw.Center(child: pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('勝/本', style: const pw.TextStyle(fontSize: 9)))),
              ],
            ),
            pw.TableRow(children: [
              _pdfTeamCell(redTeam, PdfColors.red900, ttfBold),
              ...matches.map((m) => _pdfNameCell(m.redName, rLasts, ttf)),
              _pdfSummaryCell(matches, true, ttfBold),
            ]),
            pw.TableRow(children: [
              pw.SizedBox(),
              ...matches.map((m) => _pdfScoreCell(m, ttfBold)),
              _pdfTeamResultCell(teamWinner, ttfBold),
            ]),
            pw.TableRow(children: [
              _pdfTeamCell(whiteTeam, PdfColors.black, ttfBold),
              ...matches.map((m) => _pdfNameCell(m.whiteName, wLasts, ttf)),
              _pdfSummaryCell(matches, false, ttfBold),
            ]),
          ],
        ),
      ],
    );
  }

  static pw.Widget _pdfTeamResultCell(String winner, pw.Font fontBold) {
    return pw.Container(height: 60, alignment: pw.Alignment.center, child: pw.Stack(alignment: pw.Alignment.center, children: [if (winner != 'draw' && winner != 'none') pw.Divider(color: PdfColors.black, thickness: 1, height: 0), if (winner == 'none') pw.SizedBox() else if (winner == 'draw') pw.Center(child: pw.Column(mainAxisAlignment: pw.MainAxisAlignment.center, children: '引き分け'.split('').map((c) => pw.Text(c, style: pw.TextStyle(font: fontBold, fontSize: 9))).toList())) else pw.Column(children: [pw.Expanded(child: pw.Center(child: pw.Text(winner == 'red' ? '勝' : '負', style: pw.TextStyle(font: fontBold, fontSize: 11, color: winner == 'red' ? PdfColors.red : PdfColors.black)))), pw.Expanded(child: pw.Center(child: pw.Text(winner == 'white' ? '勝' : '負', style: pw.TextStyle(font: fontBold, fontSize: 11, color: winner == 'white' ? PdfColors.red : PdfColors.black))))])]));
  }

  static pw.Widget _pdfTeamCell(String name, PdfColor color, pw.Font fontBold) => pw.Center(child: pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(name, style: pw.TextStyle(color: color, fontWeight: pw.FontWeight.bold, font: fontBold, fontSize: 10))));

  static pw.Widget _pdfNameCell(String rawName, List<String> teamLastNames, pw.Font ttf) {
    if (rawName.contains('欠員')) return pw.SizedBox(); 
    String clean = rawName.contains(':') ? rawName.split(':').last.replaceAll(RegExp(r'[()（）]'), '').trim() : rawName.trim();
    var parts = clean.split(RegExp(r'\s+'));
    final lastName = parts[0];
    final firstName = parts.length > 1 ? parts[1] : '';
    final showInitial = teamLastNames.where((n) => n == lastName).length > 1 && firstName.isNotEmpty;
    return pw.Center(child: pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2), child: pw.Row(mainAxisSize: pw.MainAxisSize.min, crossAxisAlignment: pw.CrossAxisAlignment.end, children: [pw.Text(lastName.split('').join('\n'), style: pw.TextStyle(font: ttf, fontSize: 9), textAlign: pw.TextAlign.center), if (showInitial) pw.Padding(padding: const pw.EdgeInsets.only(left: 1, bottom: 0), child: pw.Text(firstName.substring(0, 1), style: pw.TextStyle(font: ttf, fontSize: 6, color: PdfColors.grey700)))])));
  }

  static pw.Widget _pdfScoreCell(MatchModel m, pw.Font fontBold) {
    final isDone = m.status == 'finished' || m.status == 'approved';
    final rScore = (m.redScore as num).toInt(); final wScore = (m.whiteScore as num).toInt();
    final ptsMap = PdfViewModel.calculatePointsRaw(m);
    return pw.Container(height: 60, alignment: pw.Alignment.center, child: pw.Stack(alignment: pw.Alignment.center, children: [pw.Divider(color: PdfColors.black, thickness: 1, height: 0), if (isDone && rScore == wScore) pw.Center(child: pw.Text('×', style: pw.TextStyle(fontSize: 32, color: PdfColors.red300, font: fontBold))), pw.Column(children: [pw.Expanded(child: pdfPointBox(ptsMap['red']!, isDone && rScore > wScore, true, fontBold)), pw.Expanded(child: pdfPointBox(ptsMap['white']!, isDone && wScore > rScore, false, fontBold))])]));
  }

  static pw.Widget pdfPointBox(List<PdfPointData> pts, bool isWinner, bool isRed, pw.Font fontBold) {
    if (pts.isEmpty && !isWinner) return pw.SizedBox();
    final color = isRed ? PdfColors.red : PdfColors.black;
    if (pts.length == 2 && pts.every((p) => p.mark == '◯')) return pw.Container(width: 26, height: 26, child: pw.Stack(alignment: pw.Alignment.center, children: [if (isWinner) pw.Container(width: 26, height: 26, decoration: pw.BoxDecoration(shape: pw.BoxShape.circle, border: pw.Border.all(color: color, width: 0.8))), pw.Column(mainAxisAlignment: pw.MainAxisAlignment.center, children: [pw.Text('◯', style: pw.TextStyle(font: fontBold, fontSize: 10, color: color)), pw.Text('◯', style: pw.TextStyle(font: fontBold, fontSize: 10, color: color))])]));
    return pw.Container(width: 26, height: 26, child: pw.Stack(alignment: pw.Alignment.center, children: [if (isWinner) pw.Container(width: 26, height: 26, decoration: pw.BoxDecoration(shape: pw.BoxShape.circle, border: pw.Border.all(color: color, width: 0.8))), pw.Stack(children: [if (pts.isNotEmpty) pw.Positioned(top: 4, left: 5, child: _pdfSingleMark(pts[0], color, fontBold)), if (pts.length > 1) pw.Positioned(bottom: 4, right: 5, child: _pdfSingleMark(pts[1], color, fontBold))])]));
  }

  static pw.Widget _pdfSingleMark(PdfPointData p, PdfColor color, pw.Font fontBold) { return p.isFirstOverall && p.mark != '◯' ? pw.Container(width: 10, height: 10, alignment: pw.Alignment.center, decoration: pw.BoxDecoration(shape: pw.BoxShape.circle, border: pw.Border.all(color: color, width: 0.8)), child: pw.Text(p.mark, style: pw.TextStyle(font: fontBold, fontSize: 6, color: color))) : pw.Text(p.mark, style: pw.TextStyle(font: fontBold, fontSize: 8, color: color)); }
  static pw.Widget _pdfSummaryCell(List<MatchModel> ms, bool isRed, pw.Font fontBold) { int wins = 0, pts = 0; for (var m in ms) { final r = (m.redScore as num).toInt(); final w = (m.whiteScore as num).toInt(); pts += isRed ? r : w; if (isRed && r > w) wins++; if (!isRed && w > r) wins++; } return pw.Center(child: pw.Text('$wins\nー\n$pts', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: fontBold, fontSize: 10), textAlign: pw.TextAlign.center)); }
}