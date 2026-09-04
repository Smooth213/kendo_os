import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;

/// PDF生成用のフォントペア
class PdfFontPair {
  final pw.Font regular;
  final pw.Font bold;

  const PdfFontPair({required this.regular, required this.bold});
}

/// 📦 【Phase 6】PDFフォントロード最適化サービス（メモ化キャッシュ付き）
class PdfFontLoader {
  static PdfFontPair? _cachedPair;

  /// メモ化キャッシュ付きフォントロード
  /// 2回目以降のPDF出力時はディスクI/OとTTFパースをスキップし、0msで即時返却
  static Future<PdfFontPair> loadFonts() async {
    if (_cachedPair != null) {
      return _cachedPair!;
    }

    final fontData = await rootBundle.load(
      'assets/fonts/NotoSansJP-Regular.ttf',
    );
    final regular = pw.Font.ttf(fontData);

    final fontDataBold = await rootBundle.load(
      'assets/fonts/NotoSansJP-Bold.ttf',
    );
    final bold = pw.Font.ttf(fontDataBold);

    _cachedPair = PdfFontPair(regular: regular, bold: bold);
    return _cachedPair!;
  }

  /// メモリ警告時やテスト用のキャッシュクリア
  static void clearCache() {
    _cachedPair = null;
  }
}
