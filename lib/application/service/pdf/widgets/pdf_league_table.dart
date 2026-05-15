import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../../domain/services/kendo_rule_engine.dart';
import '../../../../domain/rules/match_rule.dart';
import '../models/pdf_view_model.dart';
import '../../../../domain/entities/match_model.dart';

class PdfLeagueTable {
  static pw.Widget build(String groupName, List<dynamic> matches, pw.Font ttf, pw.Font ttfBold) {
    if (matches.isEmpty) return pw.SizedBox();
    
    final normalMatches = matches.where((m) => !m.note.contains('[順位決定戦]')).toList();
    if (normalMatches.isEmpty) return pw.SizedBox();

    final first = normalMatches.first;
    final rule = (first is MatchModel) ? (first.rule ?? const MatchRule()) : const MatchRule();
    final stats = (first is MatchModel) ? KendoRuleEngine.calculateLeagueStandings(normalMatches.cast<MatchModel>(), rule) : [];
    
    final isIndiv = normalMatches.any((m) => 
      m.matchType == 'individual' || m.matchType == '選手' || m.matchType.contains('個人戦') ||
      (!m.redName.contains(':') && !m.whiteName.contains(':'))
    );
    final allFinished = matches.every((m) => m.status.toString().contains('approved') || m.status.toString().contains('finished'));
    final hasMatchPoints = rule.isLeague;

    final teams = <String>{};
    for (var m in normalMatches) {
      teams.add(m.redName.split(':').first.trim());
      teams.add(m.whiteName.split(':').first.trim());
    }
    final teamList = teams.toList()..sort();

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(80), 
        for (int i = 1; i <= teamList.length; i++) i: const pw.FixedColumnWidth(45), 
        teamList.length + 1: const pw.FixedColumnWidth(30), 
        teamList.length + 2: const pw.FixedColumnWidth(30), 
        teamList.length + 3: const pw.FixedColumnWidth(30), 
        if (hasMatchPoints) teamList.length + 4: const pw.FixedColumnWidth(30), 
        teamList.length + (hasMatchPoints ? 5 : 4): const pw.FixedColumnWidth(30), 
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            pw.Container(height: 30),
            ...teamList.map((t) => pw.Center(child: pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text(t, style: pw.TextStyle(font: ttfBold, fontSize: 7), textAlign: pw.TextAlign.center)))),
            _pdfHeaderCell('勝数', ttfBold), _pdfHeaderCell('勝者', ttfBold), _pdfHeaderCell('本数', ttfBold),
            if (hasMatchPoints) _pdfHeaderCell('勝点', ttfBold),
            _pdfHeaderCell('順位', ttfBold),
          ]
        ),
        ...teamList.map((rowTeam) {
          final stat = stats.isNotEmpty ? stats.firstWhere((s) => s.name == rowTeam, orElse: () => stats.first) : null;
          final rankStr = allFinished ? '${stats.indexWhere((s) => s.name == rowTeam) + 1}' : '-';

          final List<pw.Widget> cells = [];
          cells.add(pw.Container(
            height: 40, alignment: pw.Alignment.center, decoration: const pw.BoxDecoration(color: PdfColors.grey100),
            child: pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text(rowTeam, style: pw.TextStyle(font: ttfBold, fontSize: 7), textAlign: pw.TextAlign.center)),
          ));

          for (var colTeam in teamList) {
            if (rowTeam == colTeam) {
              cells.add(pw.Container(height: 40, color: PdfColors.grey300, child: pw.CustomPaint(painter: (PdfGraphics canvas, PdfPoint size) { canvas.setStrokeColor(PdfColors.grey500); canvas.setLineWidth(0.5); canvas.drawLine(0, size.y, size.x, 0); canvas.strokePath(); })));
            } else {
              final bouts = normalMatches.where((m) {
                final r = m.redName.split(':').first.trim();
                final w = m.whiteName.split(':').first.trim();
                return (r == rowTeam && w == colTeam) || (r == colTeam && w == rowTeam);
              }).toList();
              if (bouts.isEmpty) {
                cells.add(pw.Container(height: 40));
              } else {
                cells.add(_buildPdfLeagueCell(rowTeam, colTeam, bouts, isIndiv, ttf, ttfBold));
              }
            }
          }
          
          cells.add(_pdfStatCell('${stat?.matchWins ?? 0}', ttfBold));
          cells.add(_pdfStatCell('${stat?.individualWinners ?? 0}', ttfBold));
          cells.add(_pdfStatCell('${stat?.totalPointsScored ?? 0}', ttfBold));
          if (hasMatchPoints) {
            cells.add(_pdfStatCell(stat != null ? stat.customPoints.toStringAsFixed(stat.customPoints.truncateToDouble() == stat.customPoints ? 0 : 1) : '0', ttfBold));
          }
          cells.add(_pdfStatCell(rankStr, ttfBold, isRank: true));

          return pw.TableRow(children: cells);
        }),
      ]
    );
  }

  static pw.Widget _pdfHeaderCell(String text, pw.Font font) { return pw.Center(child: pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 8), child: pw.Text(text, style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey700)))); }

  static pw.Widget _pdfStatCell(String text, pw.Font font, {bool isRank = false}) { return pw.Container(height: 40, alignment: pw.Alignment.center, color: isRank ? PdfColors.orange50 : null, child: pw.Text(text, style: pw.TextStyle(font: font, fontSize: isRank ? 11 : 8, color: isRank ? PdfColors.orange800 : PdfColors.black))); }

  static pw.Widget _buildPdfLeagueCell(String teamA, String teamB, List<dynamic> pairMatches, bool isIndividual, pw.Font ttf, pw.Font ttfBold) {
    final hasStarted = pairMatches.any((m) => !m.status.toString().contains('waiting') || (m.runtimeType.toString() == 'MatchModel' && m.events.isNotEmpty));
    if (!hasStarted) return pw.Container(height: 40);
    String result = 'draw'; int aWins = 0, bWins = 0, aPts = 0, bPts = 0; List<String> techs = [];
    for (var m in pairMatches) {
      final isRedA = m.redName.split(':').first.trim() == teamA;
      final rs = (m.redScore as num).toInt(); final ws = (m.whiteScore as num).toInt();
      if (rs > ws) { isRedA ? aWins++ : bWins++; } else if (ws > rs) { isRedA ? bWins++ : aWins++; }
      aPts += isRedA ? rs : ws; bPts += isRedA ? ws : rs;
      if (isIndividual) {
        if (m is MatchModel) {
          techs.addAll(PdfViewModel.extractTechsForPdf(m.events, isRedA, isRedA ? rs : ws));
        } else {
          final marks = isRedA ? m.redPointMarks : m.whitePointMarks;
          for (var mark in marks) {
            techs.add(mark);
          }
        }
      }
    }
    PdfColor symbolColor = PdfColors.amber800; PdfColor bgColor = const PdfColor(1.0, 0.98, 0.95); 
    if (aWins > bWins) { result = 'win'; symbolColor = PdfColors.red800; bgColor = const PdfColor(1.0, 0.95, 0.95); } else if (bWins > aWins) { result = 'loss'; symbolColor = PdfColors.indigo800; bgColor = const PdfColor(0.95, 0.95, 1.0); } else if (aPts != bPts) { if (aPts > bPts) { result = 'win'; symbolColor = PdfColors.red800; bgColor = const PdfColor(1.0, 0.95, 0.95); } else { result = 'loss'; symbolColor = PdfColors.indigo800; bgColor = const PdfColor(0.95, 0.95, 1.0); } }
    final bool isAllFinished = pairMatches.every((m) => m.status.toString().contains('approved') || m.status.toString().contains('finished'));
    if (!isAllFinished) return pw.Container(height: 40);
    void paintPdfShape(PdfGraphics canvas, PdfPoint size) {
      final center = PdfPoint(size.x / 2, size.y / 2);
      final radius = size.x * 0.42;
      canvas.setFillColor(bgColor);
      if (result == 'win') {
        canvas.drawEllipse(center.x, center.y, radius, radius);
      } else if (result == 'loss') {
        canvas.moveTo(center.x, center.y + radius);
        canvas.lineTo(center.x + radius * 1.1, center.y - radius * 0.8);
        canvas.lineTo(center.x - radius * 1.1, center.y - radius * 0.8);
        canvas.closePath();
      } else {
        // 引き分けの背景は描画しない（四角で囲まれるのを防ぐ）
      }
      canvas.fillPath();
      
      canvas.setStrokeColor(symbolColor);
      canvas.setLineWidth(0.7);
      if (result == 'win') {
        canvas.drawEllipse(center.x, center.y, radius, radius);
      } else if (result == 'loss') {
        canvas.moveTo(center.x, center.y + radius);
        canvas.lineTo(center.x + radius * 1.1, center.y - radius * 0.8);
        canvas.lineTo(center.x - radius * 1.1, center.y - radius * 0.8);
        canvas.closePath();
      } else {
        // 引き分け(✕)
        canvas.moveTo(center.x - radius * 0.8, center.y - radius * 0.8);
        canvas.lineTo(center.x + radius * 0.8, center.y + radius * 0.8);
        canvas.moveTo(center.x + radius * 0.8, center.y - radius * 0.8);
        canvas.lineTo(center.x - radius * 0.8, center.y + radius * 0.8);
      }
      canvas.strokePath();
    }
    return pw.Container(height: 40, alignment: pw.Alignment.center, child: pw.Stack(alignment: pw.Alignment.center, children: [pw.CustomPaint(size: const PdfPoint(32, 32), painter: paintPdfShape), pw.Column(mainAxisAlignment: pw.MainAxisAlignment.center, children: [isIndividual ? (techs.isNotEmpty ? _pdfIndivSingle(techs[0], true, PdfColors.black, ttfBold) : pw.SizedBox(height: 10)) : pw.Text('$aPts', style: pw.TextStyle(font: ttfBold, fontSize: 9)), pw.Container(height: 0.5, width: 14, color: PdfColors.black, margin: const pw.EdgeInsets.symmetric(vertical: 1.5)), isIndividual ? (techs.length > 1 ? _pdfIndivSingle(techs[1], false, PdfColors.black, ttfBold) : pw.SizedBox(height: 10)) : pw.Text('$aWins', style: pw.TextStyle(font: ttfBold, fontSize: 9))])]));
  }
  static pw.Widget _pdfIndivSingle(String tech, bool isFirst, PdfColor color, pw.Font fontBold) { return isFirst && tech != '◯' ? pw.Container(width: 10, height: 10, alignment: pw.Alignment.center, decoration: pw.BoxDecoration(shape: pw.BoxShape.circle, border: pw.Border.all(color: color, width: 0.5)), child: pw.Text(tech, style: pw.TextStyle(font: fontBold, fontSize: 6, color: color))) : pw.Text(tech, style: pw.TextStyle(font: fontBold, fontSize: 8, color: color)); }
}