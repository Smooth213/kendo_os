import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../../models/match_model.dart';
import '../models/pdf_view_model.dart';
import 'pdf_team_table.dart';

class PdfIndividualList {
  static pw.Widget build(String groupName, List<MatchModel> matches, pw.Font ttf, pw.Font ttfBold) {
    if (matches.isEmpty) return pw.SizedBox();

    final uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
    String displayGroupName = groupName;
    if (uuidRegex.hasMatch(groupName) || groupName.length > 20 || groupName == 'matchup') {
      displayGroupName = '';
    }

    final note = matches.first.note;
    final cleanNote = note.replaceAll('[', '').replaceAll(']', '').trim();
    
    String headerTitle = '【個人戦】';
    if (displayGroupName.isNotEmpty) {
      headerTitle += ' $displayGroupName';
    } else {
      final rTeam = matches.first.redName.contains(':') ? matches.first.redName.split(':').first.trim() : '';
      final wTeam = matches.first.whiteName.contains(':') ? matches.first.whiteName.split(':').first.trim() : '';
      if (rTeam.isNotEmpty && wTeam.isNotEmpty && rTeam != wTeam) {
        headerTitle += ' $rTeam vs $wTeam';
      }
    }
    if (cleanNote.isNotEmpty && !cleanNote.contains('個人戦')) headerTitle += ' ($cleanNote)';

    final rows = <pw.Widget>[];
    for (int i = 0; i < matches.length; i++) {
      final m = matches[i];
      final rName = m.redName.contains(':') ? m.redName.split(':').last.replaceAll(')', '').trim() : m.redName;
      final wName = m.whiteName.contains(':') ? m.whiteName.split(':').last.replaceAll(')', '').trim() : m.whiteName;
      final rTeam = m.redName.contains(':') ? m.redName.split(':').first.trim() : '';
      final wTeam = m.whiteName.contains(':') ? m.whiteName.split(':').first.trim() : '';

      final isDone = m.status == 'finished' || m.status == 'approved';
      final rScore = (m.redScore as num).toInt();
      final wScore = (m.whiteScore as num).toInt();
      final isDraw = isDone && rScore == wScore;
      final rWin = isDone && rScore > wScore;
      final wWin = isDone && wScore > rScore;

      final ptsMap = PdfViewModel.calculatePointsRaw(m);

      rows.add(
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
          child: pw.Row(
            children: [
              pw.Container(width: 45, child: pw.Text(m.note.isNotEmpty ? m.note : '第${i+1}試合', style: pw.TextStyle(font: ttfBold, fontSize: 8, color: PdfColors.grey600), textAlign: pw.TextAlign.center)),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    if (rTeam.isNotEmpty) pw.Text(rTeam, style: pw.TextStyle(font: ttf, fontSize: 7, color: PdfColors.grey600)),
                    pw.Text(rName, style: pw.TextStyle(font: ttfBold, fontSize: 10, color: rWin ? PdfColors.red700 : PdfColors.black)),
                  ],
                ),
              ),
              pw.SizedBox(width: 8),
              PdfTeamTable.pdfPointBox(ptsMap['red']!, rWin, true, ttfBold),
              pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 6), child: pw.Text(isDraw ? '✕' : '-', style: pw.TextStyle(font: ttf, fontSize: 12, color: PdfColors.grey500))),
              PdfTeamTable.pdfPointBox(ptsMap['white']!, wWin, false, ttfBold),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (wTeam.isNotEmpty) pw.Text(wTeam, style: pw.TextStyle(font: ttf, fontSize: 7, color: PdfColors.grey600)),
                    pw.Text(wName, style: pw.TextStyle(font: ttfBold, fontSize: 10, color: wWin ? PdfColors.red700 : PdfColors.black)),
                  ],
                ),
              ),
            ],
          ),
        )
      );
    }
    return pw.Container(margin: const pw.EdgeInsets.symmetric(vertical: 4), decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey500, width: 0.5)), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [pw.Container(padding: const pw.EdgeInsets.all(6), color: PdfColors.grey200, width: double.infinity, child: pw.Text(headerTitle, style: pw.TextStyle(font: ttfBold, fontSize: 10))), ...rows]));
  }
}