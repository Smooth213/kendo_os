import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:kendo_os/features/pdf/models/pdf_point_data.dart';
import 'package:kendo_os/features/pdf/models/pdf_view_model.dart';

class PdfTeamTable {
  static pw.Widget build(
    String groupName,
    List<dynamic> matches,
    pw.Font ttf,
    pw.Font ttfBold,
  ) {
    if (matches.isEmpty) return pw.SizedBox();

    final note = matches.first.note;
    final isLeague = note.contains('リーグ戦');

    // ★ 修正: 団体戦でもデフォルトのリーグ戦文言を綺麗に消去する
    String cleanNote = note
        .replaceAll('[リーグ戦]', '')
        .replaceAll('[', '')
        .replaceAll(']', '')
        .trim();
    if (cleanNote == 'リーグ戦') {
      cleanNote = '';
    }

    final redTeam = matches.first.redName.split(':').first;
    final whiteTeam = matches.first.whiteName.split(':').first;

    // ★ 修正: 【リーグ団体戦】への切り替えと、パターンA（コメントがない時は括弧ごと消去）の適用
    final prefix = isLeague ? '【リーグ団体戦】' : '【団体戦】';
    final String titleText = cleanNote.isNotEmpty
        ? '$prefix対戦スコア詳細（$cleanNote）'
        : '$prefix対戦スコア詳細';
    Map<String, String> parse(String raw) {
      if (raw.contains('欠員')) return {'last': '', 'first': ''};
      String clean = raw.contains(':')
          ? raw.split(':').last.replaceAll(RegExp(r'[()（）]'), '').trim()
          : raw.trim();
      var parts = clean.split(RegExp(r'\s+'));
      return {'last': parts[0], 'first': parts.length > 1 ? parts[1] : ''};
    }

    List<String> rLasts = matches
        .map((m) => parse(m.redName)['last']!)
        .where((s) => s.isNotEmpty)
        .toList();
    List<String> wLasts = matches
        .map((m) => parse(m.whiteName)['last']!)
        .where((s) => s.isNotEmpty)
        .toList();

    final allFinished = matches.every(
      (m) =>
          m.status.toString().contains('finished') ||
          m.status.toString().contains('approved'),
    );
    String teamWinner = 'none';

    if (allFinished) {
      teamWinner = 'draw';
      int rWins = 0, wWins = 0, rPts = 0, wPts = 0;
      dynamic daihyo;
      for (var m in matches) {
        if (m.matchType == '代表戦') {
          daihyo = m;
          continue; // ★ 修正: 代表戦のスコアはチームの合計(勝数/本数)には含めない
        }
        final rs = (m.redScore as num).toInt();
        final ws = (m.whiteScore as num).toInt();
        rPts += rs;
        wPts += ws;
        if (rs > ws) {
          rWins++;
        } else if (ws > rs) {
          wWins++;
        }
      }
      if (rWins > wWins) {
        teamWinner = 'red';
      } else if (wWins > rWins) {
        teamWinner = 'white';
      } else if (rPts > wPts) {
        teamWinner = 'red';
      } else if (wPts > rPts) {
        teamWinner = 'white';
      } else if (daihyo != null) {
        final rs = (daihyo.redScore as num).toInt();
        final ws = (daihyo.whiteScore as num).toInt();
        if (rs > ws) {
          teamWinner = 'red';
        } else if (ws > rs) {
          teamWinner = 'white';
        }
      }
    }

    // ★ Phase 6-1: A4横幅最適化ガード
    // 7人制や9人制など、試合数（列数）が極端に多くなった場合でも、文字が重なってA4の印刷可能幅から
    // はみ出るのを物理的に防ぐため、列数に応じてフォントサイズとタイトルサイズを決定論的に自動縮小（スケール）させます。
    final double dynamicFontSize = matches.length > 5 ? 7.5 : 9.0;
    final double dynamicTitleSize = matches.length > 5 ? 9.5 : 11.0;

    final Map<int, pw.TableColumnWidth> columnWidths = {
      0: const pw.FlexColumnWidth(1.4),
      for (int i = 1; i <= matches.length; i++)
        i: const pw.FlexColumnWidth(1.0),
      matches.length + 1: const pw.FlexColumnWidth(1.0),
    };

    // ★ Phase 6-1: 改ページ崩れの完全封鎖（pw.Container）
    // 1つの対戦表がページの最下部で不自然に真っ二つに分断されるのを100%防止するため、
    // 表のひとかたまりを pw.Container で包み、ページ内に収まらない場合は自動で次のページへ安全に送出します。
    return pw.Container(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.all(6),
            color: PdfColors.grey200,
            width: double.infinity,
            child: pw.Text(
              titleText,
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                font: ttfBold,
                fontSize: dynamicTitleSize,
              ),
            ),
          ),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.black, width: 1),
            columnWidths: columnWidths,
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  pw.SizedBox(),
                  ...matches.map(
                    (m) => pw.Center(
                      child: pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          m.matchType,
                          style: pw.TextStyle(
                            fontSize: dynamicFontSize,
                            fontWeight: pw.FontWeight.bold,
                            font: ttfBold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  pw.Center(
                    child: pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        '本/勝',
                        style: pw.TextStyle(
                          fontSize: dynamicFontSize,
                          font: ttfBold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  _pdfTeamCell(redTeam, PdfColors.red900, ttfBold),
                  ...matches.map((m) => _pdfNameCell(m.redName, rLasts, ttf)),
                  _pdfSummaryCell(matches, true, ttfBold),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.SizedBox(),
                  ...matches.map((m) => _pdfScoreCell(m, ttfBold)),
                  _pdfTeamResultCell(teamWinner, ttfBold),
                ],
              ),
              pw.TableRow(
                children: [
                  _pdfTeamCell(whiteTeam, PdfColors.black, ttfBold),
                  ...matches.map((m) => _pdfNameCell(m.whiteName, wLasts, ttf)),
                  _pdfSummaryCell(matches, false, ttfBold),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _pdfTeamResultCell(String winner, pw.Font fontBold) {
    return pw.Container(
      height: 60,
      alignment: pw.Alignment.center,
      child: pw.Stack(
        alignment: pw.Alignment.center,
        children: [
          if (winner != 'draw' && winner != 'none')
            pw.Divider(color: PdfColors.black, thickness: 1, height: 0),
          if (winner == 'none')
            pw.SizedBox()
          else if (winner == 'draw')
            pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: '引き分け'
                    .split('')
                    .map(
                      (c) => pw.Text(
                        c,
                        style: pw.TextStyle(font: fontBold, fontSize: 9),
                      ),
                    )
                    .toList(),
              ),
            )
          else
            pw.Column(
              children: [
                pw.Expanded(
                  child: pw.Center(
                    child: pw.Text(
                      winner == 'red' ? '勝' : '負',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 11,
                        color: winner == 'red'
                            ? PdfColors.red
                            : PdfColors.black,
                      ),
                    ),
                  ),
                ),
                pw.Expanded(
                  child: pw.Center(
                    child: pw.Text(
                      winner == 'white' ? '勝' : '負',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 11,
                        color: winner == 'white'
                            ? PdfColors.red
                            : PdfColors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  static pw.Widget _pdfTeamCell(
    String name,
    PdfColor color,
    pw.Font fontBold,
  ) => pw.Center(
    child: pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        name,
        style: pw.TextStyle(
          color: color,
          fontWeight: pw.FontWeight.bold,
          font: fontBold,
          fontSize: 10,
        ),
      ),
    ),
  );

  static pw.Widget _pdfNameCell(
    String rawName,
    List<String> teamLastNames,
    pw.Font ttf,
  ) {
    if (rawName.contains('欠員')) return pw.SizedBox();
    String clean = rawName.contains(':')
        ? rawName.split(':').last.replaceAll(RegExp(r'[()（）]'), '').trim()
        : rawName.trim();
    var parts = clean.split(RegExp(r'\s+'));
    final lastName = parts[0];
    final firstName = parts.length > 1 ? parts[1] : '';
    final showInitial =
        teamLastNames.where((n) => n == lastName).length > 1 &&
        firstName.isNotEmpty;
    return pw.Center(
      child: pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: pw.Row(
          mainAxisSize: pw.MainAxisSize.min,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              lastName.split('').join('\n'),
              style: pw.TextStyle(font: ttf, fontSize: 9),
              textAlign: pw.TextAlign.center,
            ),
            if (showInitial)
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 1, bottom: 0),
                child: pw.Text(
                  firstName.substring(0, 1),
                  style: pw.TextStyle(
                    font: ttf,
                    fontSize: 6,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _pdfScoreCell(dynamic m, pw.Font fontBold) {
    final isDone =
        m.status.toString().contains('finished') ||
        m.status.toString().contains('approved');
    final rScore = (m.redScore as num).toInt();
    final wScore = (m.whiteScore as num).toInt();
    final ptsMap = PdfViewModel.calculatePointsRaw(m);
    return pw.Container(
      height: 60,
      alignment: pw.Alignment.center,
      child: pw.Stack(
        alignment: pw.Alignment.center,
        children: [
          pw.Divider(color: PdfColors.black, thickness: 1, height: 0),
          if (isDone && rScore == wScore)
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 2),
              child: pw.Text(
                '×',
                style: pw.TextStyle(
                  fontSize: 16,
                  color: PdfColors.grey600,
                  font: fontBold,
                ),
              ),
            ),
          pw.Column(
            children: [
              pw.Expanded(
                child: pdfPointBox(
                  ptsMap['red']!,
                  isDone && rScore > wScore,
                  true,
                  fontBold,
                ),
              ),
              pw.Expanded(
                child: pdfPointBox(
                  ptsMap['white']!,
                  isDone && wScore > rScore,
                  false,
                  fontBold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget pdfPointBox(
    List<PdfPointData> pts,
    bool isWinner,
    bool isRed,
    pw.Font fontBold,
  ) {
    if (pts.isEmpty) return pw.SizedBox(width: 26, height: 26);
    final color = isRed ? PdfColors.red700 : PdfColors.black;
    // ★ 修正: データソースが古い '✕' でも新しい '×' でも安全にマッチさせ、出力は標準の '×' に統一して豆腐文字を防ぐ
    if (pts.length == 1 && (pts[0].mark == '✕' || pts[0].mark == '×')) {
      return pw.Container(
        width: 26,
        height: 26,
        child: pw.Stack(
          alignment: pw.Alignment.center,
          children: [
            if (isWinner)
              pw.Container(
                width: 26,
                height: 26,
                decoration: pw.BoxDecoration(
                  shape: pw.BoxShape.circle,
                  border: pw.Border.all(color: color, width: 0.8),
                ),
              ),
            pw.Text(
              '×',
              style: pw.TextStyle(font: fontBold, fontSize: 10, color: color),
            ),
          ],
        ),
      );
    }
    return pw.Container(
      width: 26,
      height: 26,
      child: pw.Stack(
        alignment: pw.Alignment.center,
        children: [
          if (isWinner)
            pw.Container(
              width: 26,
              height: 26,
              decoration: pw.BoxDecoration(
                shape: pw.BoxShape.circle,
                border: pw.Border.all(color: color, width: 0.8),
              ),
            ),
          pw.Stack(
            children: [
              if (pts.isNotEmpty)
                pw.Positioned(
                  top: 4,
                  left: 5,
                  child: _pdfSingleMark(pts[0], color, fontBold),
                ),
              if (pts.length > 1)
                pw.Positioned(
                  bottom: 4,
                  right: 5,
                  child: _pdfSingleMark(pts[1], color, fontBold),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _pdfSingleMark(
    PdfPointData p,
    PdfColor color,
    pw.Font fontBold,
  ) {
    return p.isFirstOverall && p.mark != '◯'
        ? pw.Container(
            width: 10,
            height: 10,
            alignment: pw.Alignment.center,
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              border: pw.Border.all(color: color, width: 0.8),
            ),
            child: pw.Text(
              p.mark,
              style: pw.TextStyle(font: fontBold, fontSize: 6, color: color),
            ),
          )
        : pw.Text(
            p.mark,
            style: pw.TextStyle(font: fontBold, fontSize: 8, color: color),
          );
  }

  static pw.Widget _pdfSummaryCell(
    List<dynamic> ms,
    bool isRed,
    pw.Font fontBold,
  ) {
    int wins = 0, pts = 0;
    for (var m in ms) {
      if (m.matchType == '代表戦') continue; // ★ 修正: 代表戦は合算しない
      final r = (m.redScore as num).toInt();
      final w = (m.whiteScore as num).toInt();
      pts += isRed ? r : w;
      if (isRed && r > w) wins++;
      if (!isRed && w > r) wins++;
    }
    return pw.Center(
      child: pw.Text(
        '$pts\nー\n$wins',
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          font: fontBold,
          fontSize: 10,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }
}
