import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:kendo_os/features/pdf/models/pdf_point_data.dart';
import 'package:kendo_os/shared/theme/app_tokens.dart';

/// 勝ち抜き戦PDF描画で使用する共通ウィジェット生成ヘルパー
class PdfKachinukiWidgets {
  static pw.Widget teamText(
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

  static Map<String, String> parsePlayerName(String raw) {
    if (raw.contains('欠員')) return {'last': '', 'first': ''};
    String clean = raw.contains(':')
        ? raw.split(':').last.replaceAll(RegExp(r'[()（）]'), '').trim()
        : raw.replaceAll(RegExp(r'[()（）]'), '').trim();
    var parts = clean.split(RegExp(r'\s+'));
    return {'last': parts[0], 'first': parts.length > 1 ? parts[1] : ''};
  }

  static pw.Widget playerCell(
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

  static pw.Widget pdfScoreColumn(
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
