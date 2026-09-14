import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;

/// PDF生成用のフォントペア
class PdfFontPair {
  final pw.Font regular;
  final pw.Font bold;

  const PdfFontPair({required this.regular, required this.bold});
}

class PdfFontRawBytes {
  final Uint8List regular;
  final Uint8List bold;

  const PdfFontRawBytes({required this.regular, required this.bold});
}

/// 📦 【Phase 6】PDFフォントロード最適化サービス（メモ化キャッシュ付き）
class PdfFontLoader {
  static PdfFontPair? _cachedPair;
  static PdfFontRawBytes? _cachedRawBytes;

  /// 生フォントバイトの取得（Isolate・computeへの転送用）
  static Future<PdfFontRawBytes> loadFontBytes() async {
    if (_cachedRawBytes != null) {
      return _cachedRawBytes!;
    }

    final fontData = await rootBundle.load(
      'assets/fonts/NotoSansJP-Regular.ttf',
    );
    final fontDataBold = await rootBundle.load(
      'assets/fonts/NotoSansJP-Bold.ttf',
    );

    _cachedRawBytes = PdfFontRawBytes(
      regular: fontData.buffer.asUint8List(
        fontData.offsetInBytes,
        fontData.lengthInBytes,
      ),
      bold: fontDataBold.buffer.asUint8List(
        fontDataBold.offsetInBytes,
        fontDataBold.lengthInBytes,
      ),
    );
    return _cachedRawBytes!;
  }

  /// メモ化キャッシュ付きフォントロード
  /// 2回目以降のPDF出力時はディスクI/OとTTFパースをスキップし、0msで即時返却
  static Future<PdfFontPair> loadFonts() async {
    if (_cachedPair != null) {
      return _cachedPair!;
    }

    final rawBytes = await loadFontBytes();
    final regular = pw.Font.ttf(ByteData.sublistView(rawBytes.regular));
    final bold = pw.Font.ttf(ByteData.sublistView(rawBytes.bold));

    _cachedPair = PdfFontPair(regular: regular, bold: bold);
    return _cachedPair!;
  }

  /// メモリ警告時やテスト用のキャッシュクリア
  static void clearCache() {
    _cachedPair = null;
    _cachedRawBytes = null;
  }
}
