import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:kendo_os/features/pdf/models/pdf_point_data.dart';
import 'package:kendo_os/features/pdf/models/pdf_view_model.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';

/// PDF団体戦対戦表の各種セル描画レンダラー
class PdfTeamTableCellRenderer {
  /// チーム勝敗結果セル
  static pw.Widget buildTeamResultCell(String winner, pw.Font fontBold) {
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
                        fontSize: AppFontSize.caption,
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
                        fontSize: AppFontSize.caption,
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

  /// チーム名セル
  static pw.Widget buildTeamCell(
    String name,
    PdfColor color,
    pw.Font fontBold,
  ) => pw.Center(
    child: pw.Padding(
      padding: const pw.EdgeInsets.all(AppSpacing.subValue),
      child: pw.Text(
        name,
        style: pw.TextStyle(
          color: color,
          fontWeight: pw.FontWeight.bold,
          font: fontBold,
          fontSize: AppFontSize.badge,
        ),
      ),
    ),
  );

  /// 選手名セル（名字の縦書き ＋ 同姓時の頭文字表示）
  static pw.Widget buildNameCell(
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
        padding: const pw.EdgeInsets.symmetric(
          vertical: AppSpacing.xs,
          horizontal: 2,
        ),
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

  /// 試合スコアセル（一本・二本・引き分け・延長対応）
  static pw.Widget buildScoreCell(dynamic m, pw.Font fontBold) {
    final isDone =
        m.status.toString().contains('finished') ||
        m.status.toString().contains('approved');
    final rScore = (m.redScore as num).toInt();
    final wScore = (m.whiteScore as num).toInt();
    final ptsMap = PdfViewModel.calculatePointsRaw(m);

    final note = (m.note ?? '').toString();
    final matchType = (m.matchType ?? '').toString();
    final isEncho =
        isDone &&
        (note.contains('延長') ||
            matchType == '代表戦' ||
            matchType == '大将延長戦' ||
            matchType.contains('代表') ||
            matchType.contains('延長'));

    return pw.Container(
      height: 60,
      alignment: pw.Alignment.center,
      child: pw.Stack(
        alignment: pw.Alignment.center,
        children: [
          pw.Divider(color: PdfColors.black, thickness: 1, height: 0),
          if (isDone && rScore == wScore)
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: AppSpacing.xxs,
              ),
              color: PdfColors.white,
              child: pw.Text(
                '×',
                style: pw.TextStyle(
                  fontSize: AppFontSize.subhead,
                  color: PdfColors.grey600,
                  font: fontBold,
                ),
              ),
            )
          else if (isEncho)
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: AppSpacing.xxs,
                vertical: 1,
              ),
              color: PdfColors.white,
              child: pw.Column(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text(
                    '延',
                    style: pw.TextStyle(
                      fontSize: AppFontSize.micro,
                      font: fontBold,
                      color: PdfColors.black,
                    ),
                  ),
                  pw.Text(
                    '長',
                    style: pw.TextStyle(
                      fontSize: AppFontSize.micro,
                      font: fontBold,
                      color: PdfColors.black,
                    ),
                  ),
                ],
              ),
            ),
          pw.Column(
            children: [
              pw.Expanded(
                child: buildPointBox(
                  ptsMap['red']!,
                  isDone && rScore > wScore,
                  true,
                  fontBold,
                ),
              ),
              pw.Expanded(
                child: buildPointBox(
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

  /// 打突部位ポイントボックス
  static pw.Widget buildPointBox(
    List<PdfPointData> pts,
    bool isWinner,
    bool isRed,
    pw.Font fontBold,
  ) {
    if (pts.isEmpty) return pw.SizedBox(width: 26, height: 26);
    final color = isRed ? PdfColors.red700 : PdfColors.black;
    if (pts.length == 1 && (pts[0].mark == '✕' || pts[0].mark == '×')) {
      return pw.Container(
        width: 26,
        height: 26,
        alignment: pw.Alignment.center,
        child: pw.Stack(
          alignment: pw.Alignment.center,
          children: [
            if (isWinner)
              pw.Container(
                width: 25,
                height: 25,
                decoration: pw.BoxDecoration(
                  shape: pw.BoxShape.circle,
                  border: pw.Border.all(color: color, width: 0.7),
                ),
              ),
            pw.Text(
              '×',
              style: pw.TextStyle(
                font: fontBold,
                fontSize: AppFontSize.badge,
                color: color,
              ),
            ),
          ],
        ),
      );
    }
    return pw.Container(
      width: 26,
      height: 26,
      alignment: pw.Alignment.center,
      child: pw.Stack(
        alignment: pw.Alignment.center,
        children: [
          if (isWinner)
            pw.Container(
              width: 25,
              height: 25,
              decoration: pw.BoxDecoration(
                shape: pw.BoxShape.circle,
                border: pw.Border.all(color: color, width: 0.7),
              ),
            ),
          pw.Stack(
            children: [
              if (pts.isNotEmpty)
                pw.Positioned(
                  top: 3.5,
                  left: 4.5,
                  child: _pdfSingleMark(pts[0], color, fontBold),
                ),
              if (pts.length > 1)
                pw.Positioned(
                  bottom: 3.5,
                  right: 4.5,
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
    final bool isSpecialFusenOrDraw =
        p.mark == '◯' || p.mark == '✕' || p.mark == '×' || p.mark == '反';
    return p.isFirstOverall && !isSpecialFusenOrDraw
        ? pw.Container(
            width: 10,
            height: 10,
            alignment: pw.Alignment.center,
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              border: pw.Border.all(color: color, width: 0.6),
            ),
            child: pw.Text(
              p.mark,
              style: pw.TextStyle(font: fontBold, fontSize: 5.5, color: color),
              textAlign: pw.TextAlign.center,
            ),
          )
        : pw.Text(
            p.mark,
            style: pw.TextStyle(
              font: fontBold,
              fontSize: AppFontSize.micro,
              color: color,
            ),
            textAlign: pw.TextAlign.center,
          );
  }

  /// 本数/勝者数 集計サマリーセル
  static pw.Widget buildSummaryCell(
    List<dynamic> ms,
    bool isRed,
    pw.Font fontBold,
  ) {
    int wins = 0, pts = 0;
    for (var m in ms) {
      if (m.matchType == '代表戦') continue;
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
          fontSize: AppFontSize.badge,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }
}
