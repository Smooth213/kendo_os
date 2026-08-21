import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;

/// PDF生成用のフォントペア
class PdfFontPair {
  final pw.Font regular;
  final pw.Font bold;

  const PdfFontPair({required this.regular, required this.bold});
}

/// PDFフォントロードサービス
class PdfFontLoader {
  static Future<PdfFontPair> loadFonts() async {
    final fontData = await rootBundle.load(
      'assets/fonts/NotoSansJP-Regular.ttf',
    );
    final regular = pw.Font.ttf(fontData);

    final fontDataBold = await rootBundle.load(
      'assets/fonts/NotoSansJP-Bold.ttf',
    );
    final bold = pw.Font.ttf(fontDataBold);

    return PdfFontPair(regular: regular, bold: bold);
  }
}
