import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:kendo_os/features/match/domain/services/kendo_rule_engine.dart';
import 'package:kendo_os/features/match/domain/rules/match_rule.dart';
import 'package:kendo_os/features/pdf/models/pdf_view_model.dart';
import 'package:kendo_os/features/pdf/models/pdf_point_data.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';

class PdfLeagueTable {
  static String _getEntityName(String fullName, bool isIndiv) {
    if (isIndiv) {
      return fullName.contains(':')
          ? fullName.split(':').last.replaceAll(RegExp(r'[()（）]'), '').trim()
          : fullName.trim();
    }
    return fullName.contains(':')
        ? fullName.split(':').first.trim()
        : fullName.trim();
  }

  static pw.Widget build(
    String groupName,
    List<dynamic> matches,
    pw.Font ttf,
    pw.Font ttfBold,
  ) {
    if (matches.isEmpty) return pw.SizedBox();

    final normalMatches = matches
        .where((m) => !m.note.contains('[順位決定戦]'))
        .toList();
    if (normalMatches.isEmpty) return pw.SizedBox();

    final first = normalMatches.first;
    final rule = (first is MatchModel)
        ? (first.rule ?? const MatchRule())
        : const MatchRule();
    final stats = (first is MatchModel)
        ? KendoRuleEngine.calculateLeagueStandings(
            normalMatches.cast<MatchModel>(),
            rule,
          )
        : [];

    final isIndiv = normalMatches.any(
      (m) =>
          m.matchType == 'individual' ||
          m.matchType == '選手' ||
          m.matchType.contains('個人戦') || // 個人戦系のキーワード
          (!m.matchType.contains('団体') &&
              !m.redName.contains(':') &&
              !m.whiteName.contains(':')), // 「団体」を含まず、名前がコロン区切りでない場合
    );
    final allFinished = matches.every(
      (m) =>
          m.status.toString().contains('approved') ||
          m.status.toString().contains('finished'),
    );
    final hasMatchPoints = rule.isLeague;

    final teams = <String>{};
    for (var m in normalMatches) {
      teams.add(_getEntityName(m.redName, isIndiv));
      teams.add(_getEntityName(m.whiteName, isIndiv));
    }
    final teamList = teams.toList()..sort();

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(80),
        for (int i = 1; i <= teamList.length; i++)
          i: const pw.FixedColumnWidth(45),
        teamList.length + 1: const pw.FixedColumnWidth(30),
        teamList.length + 2: const pw.FixedColumnWidth(30),
        teamList.length + 3: const pw.FixedColumnWidth(30),
        if (hasMatchPoints) teamList.length + 4: const pw.FixedColumnWidth(30),
        teamList.length + (hasMatchPoints ? 5 : 4): const pw.FixedColumnWidth(
          30,
        ),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            pw.Container(height: 30),
            ...teamList.map(
              (t) => pw.Center(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.all(2),
                  child: pw.Text(
                    t,
                    style: pw.TextStyle(font: ttfBold, fontSize: 7),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ),
            ),
            _pdfHeaderCell('勝数', ttfBold),
            _pdfHeaderCell('勝者', ttfBold),
            _pdfHeaderCell('本数', ttfBold),
            if (hasMatchPoints) _pdfHeaderCell('勝点', ttfBold),
            _pdfHeaderCell('順位', ttfBold),
          ],
        ),
        ...teamList.map((rowTeam) {
          dynamic stat;
          if (stats.isNotEmpty) {
            final found = stats.where((s) => s.name == rowTeam).toList();
            stat = found.isNotEmpty ? found.first : stats.first;
          }
          final rankStr = allFinished
              ? '${stats.indexWhere((s) => s.name == rowTeam) + 1}'
              : '-';

          final List<pw.Widget> cells = [];
          cells.add(
            pw.Container(
              height: 40,
              alignment: pw.Alignment.center,
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              child: pw.Padding(
                padding: const pw.EdgeInsets.all(2),
                child: pw.Text(
                  rowTeam,
                  style: pw.TextStyle(font: ttfBold, fontSize: 7),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ),
          );

          for (var colTeam in teamList) {
            if (rowTeam == colTeam) {
              cells.add(
                pw.Container(
                  height: 40,
                  color: PdfColors.grey300,
                  child: pw.CustomPaint(
                    painter: (PdfGraphics canvas, PdfPoint size) {
                      canvas.setStrokeColor(PdfColors.grey500);
                      canvas.setLineWidth(0.5);
                      canvas.drawLine(0, size.y, size.x, 0);
                      canvas.strokePath();
                    },
                  ),
                ),
              );
            } else {
              final bouts = normalMatches.where((m) {
                final r = _getEntityName(m.redName, isIndiv);
                final w = _getEntityName(m.whiteName, isIndiv);
                return (r == rowTeam && w == colTeam) ||
                    (r == colTeam && w == rowTeam);
              }).toList();
              if (bouts.isEmpty) {
                cells.add(pw.Container(height: 40));
              } else {
                cells.add(
                  _buildPdfLeagueCell(
                    rowTeam,
                    colTeam,
                    bouts,
                    isIndiv,
                    ttf,
                    ttfBold,
                  ),
                );
              }
            }
          }

          cells.add(_pdfStatCell('${stat?.matchWins ?? 0}', ttfBold));
          cells.add(_pdfStatCell('${stat?.individualWinners ?? 0}', ttfBold));
          cells.add(_pdfStatCell('${stat?.totalPointsScored ?? 0}', ttfBold));
          if (hasMatchPoints) {
            cells.add(
              _pdfStatCell(
                stat != null
                    ? stat.customPoints.toStringAsFixed(
                        stat.customPoints.truncateToDouble() ==
                                stat.customPoints
                            ? 0
                            : 1,
                      )
                    : '0',
                ttfBold,
              ),
            );
          }
          cells.add(_pdfStatCell(rankStr, ttfBold, isRank: true));

          return pw.TableRow(children: cells);
        }),
      ],
    );
  }

  static pw.Widget _pdfHeaderCell(String text, pw.Font font) {
    return pw.Center(
      child: pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 8),
        child: pw.Text(
          text,
          style: pw.TextStyle(
            font: font,
            fontSize: 8,
            color: PdfColors.grey700,
          ),
        ),
      ),
    );
  }

  static pw.Widget _pdfStatCell(
    String text,
    pw.Font font, {
    bool isRank = false,
  }) {
    return pw.Container(
      height: 40,
      alignment: pw.Alignment.center,
      color: isRank ? PdfColors.orange50 : null,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: isRank ? 11 : 8,
          color: isRank ? PdfColors.orange800 : PdfColors.black,
        ),
      ),
    );
  }

  static pw.Widget _buildPdfLeagueCell(
    String teamA,
    String teamB,
    List<dynamic> pairMatches,
    bool isIndividual,
    pw.Font ttf,
    pw.Font ttfBold,
  ) {
    final hasStarted = pairMatches.any(
      (m) =>
          !m.status.toString().contains('waiting') ||
          (m.runtimeType.toString() == 'MatchModel' && m.events.isNotEmpty),
    );
    if (!hasStarted) return pw.Container(height: 40);
    String result = 'draw';
    int aWins = 0, bWins = 0, aPts = 0, bPts = 0;
    List<PdfPointData> techs = [];
    for (var m in pairMatches) {
      final isRedA = _getEntityName(m.redName, isIndividual) == teamA;
      final rs = (m.redScore as num).toInt();
      final ws = (m.whiteScore as num).toInt();
      if (rs > ws) {
        isRedA ? aWins++ : bWins++;
      } else if (ws > rs) {
        isRedA ? bWins++ : aWins++;
      }
      aPts += isRedA ? rs : ws;
      bPts += isRedA ? ws : rs;
      if (isIndividual) {
        final ptsMap = PdfViewModel.calculatePointsRaw(m);
        final pts = isRedA ? ptsMap['red'] : ptsMap['white'];
        if (pts != null) techs.addAll(pts);
      }
    }
    PdfColor symbolColor = PdfColors.amber800;
    PdfColor bgColor = const PdfColor(1.0, 0.98, 0.95);
    if (aWins > bWins) {
      result = 'win';
      symbolColor = PdfColors.red800;
      bgColor = const PdfColor(1.0, 0.95, 0.95);
    } else if (bWins > aWins) {
      result = 'loss';
      symbolColor = PdfColors.indigo800;
      bgColor = const PdfColor(0.95, 0.95, 1.0);
    } else if (aPts != bPts) {
      if (aPts > bPts) {
        result = 'win';
        symbolColor = PdfColors.red800;
        bgColor = const PdfColor(1.0, 0.95, 0.95);
      } else {
        result = 'loss';
        symbolColor = PdfColors.indigo800;
        bgColor = const PdfColor(0.95, 0.95, 1.0);
      }
    }
    final bool isAllFinished = pairMatches.every(
      (m) =>
          m.status.toString().contains('approved') ||
          m.status.toString().contains('finished'),
    );
    if (!isAllFinished) return pw.Container(height: 40);
    void paintPdfShape(PdfGraphics canvas, PdfPoint size) {
      final center = PdfPoint(size.x / 2, size.y / 2);
      final radius = size.x * 0.42;
      canvas.setFillColor(bgColor);
      if (result == 'win') {
        canvas.drawEllipse(center.x, center.y, radius, radius);
        canvas.fillPath();
      } else if (result == 'loss') {
        canvas.moveTo(center.x, center.y + radius);
        canvas.lineTo(center.x + radius * 1.1, center.y - radius * 0.8);
        canvas.lineTo(center.x - radius * 1.1, center.y - radius * 0.8);
        canvas.closePath();
        canvas.fillPath();
      } else {
        // 引き分けの場合は四角形(□)の背景を描画する (円と同じくらいの視覚サイズにする)
        final rectSize = radius * 1.9;
        canvas.drawRect(
          center.x - rectSize / 2,
          center.y - rectSize / 2,
          rectSize,
          rectSize,
        );
        canvas.fillPath();
      }

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
        // 引き分けの場合は四角形(□)の枠線を描画する (円と同じくらいの視覚サイズにする)
        final rectSize = radius * 1.9;
        canvas.drawRect(
          center.x - rectSize / 2,
          center.y - rectSize / 2,
          rectSize,
          rectSize,
        );
      }
      canvas.strokePath();
    }

    pw.Widget buildTechMark(PdfPointData p) {
      String displayTech = p.mark == '判定' ? '判' : p.mark;
      if (p.isFirstOverall &&
          displayTech != '◯' &&
          displayTech != '反' &&
          displayTech != '✕' &&
          displayTech != '×') {
        return pw.Container(
          width: 10,
          height: 10,
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(
            shape: pw.BoxShape.circle,
            border: pw.Border.all(color: PdfColors.black, width: 0.5),
          ),
          child: pw.Text(
            displayTech,
            style: pw.TextStyle(
              font: ttfBold,
              fontSize: 6,
              color: PdfColors.black,
            ),
          ),
        );
      }
      return pw.Text(
        displayTech,
        style: pw.TextStyle(font: ttfBold, fontSize: 8, color: PdfColors.black),
      );
    }

    return pw.Container(
      height: 40,
      alignment: pw.Alignment.center,
      child: pw.Stack(
        alignment: pw.Alignment.center,
        children: [
          pw.CustomPaint(
            size: const PdfPoint(32, 32),
            painter: paintPdfShape,
          ), // win/lossの背景色と枠線

          if (isIndividual)
            pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                if (techs.isNotEmpty) ...[
                  buildTechMark(techs[0]),
                  pw.Container(
                    height: 0.5,
                    width: 8,
                    color: PdfColors.black,
                    margin: const pw.EdgeInsets.symmetric(vertical: 1),
                  ),
                  if (techs.length > 1)
                    buildTechMark(techs[1])
                  else
                    pw.SizedBox(height: 10, width: 10),
                ],
              ],
            )
          else
            pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  '$aPts',
                  style: pw.TextStyle(font: ttfBold, fontSize: 9),
                ),
                pw.Container(
                  height: 0.5,
                  width: 14,
                  color: PdfColors.black,
                  margin: const pw.EdgeInsets.symmetric(vertical: 1.5),
                ),
                pw.Text(
                  '$aWins',
                  style: pw.TextStyle(font: ttfBold, fontSize: 9),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
