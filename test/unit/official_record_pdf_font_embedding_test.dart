import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:kendo_os/features/pdf/services/pdf_font_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('📄 公式記録PDF 日本語フォント埋め込み＆バイナリ生成検証テスト', () {
    setUp(() {
      PdfFontLoader.clearCache();
    });

    test('1. 日本語フォント (NotoSansJP Regular/Bold) の読み込みとキャッシュの検証', () async {
      final fontPair = await PdfFontLoader.loadFonts();
      expect(fontPair.regular, isNotNull);
      expect(fontPair.bold, isNotNull);

      // キャッシュ機能の検証: 2回目の呼び出しが同一インスタンスを返すこと
      final fontPairCached = await PdfFontLoader.loadFonts();
      expect(identical(fontPair, fontPairCached), isTrue);

      // RawBytes の検証
      final rawBytes = await PdfFontLoader.loadFontBytes();
      expect(rawBytes.regular.isNotEmpty, isTrue);
      expect(rawBytes.bold.isNotEmpty, isTrue);
    });

    test('2. 日本語・外字・外国人名を含む公式PDF生成とフォント埋め込みバイナリ検証', () async {
      final fontPair = await PdfFontLoader.loadFonts();
      final pdf = pw.Document(
        theme: pw.ThemeData.withFont(
          base: fontPair.regular,
          bold: fontPair.bold,
        ),
      );

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '第68回 全日本剣道選手権大会 公式記録表',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text('選手名: 髙橋 龍之介（旧字体） / Smith Müller（外国人名）'),
                pw.Text('試合結果: 勝者 ◯◯ 胴・面 二本勝ち'),
              ],
            );
          },
        ),
      );

      final Uint8List pdfBytes = await pdf.save();

      // 1. PDFマジックナンバー (%PDF-) を検証
      expect(pdfBytes.length, greaterThan(100));
      final header = String.fromCharCodes(pdfBytes.sublist(0, 5));
      expect(header, '%PDF-');

      // 2. フォントリソース定義 (/Font /Type) がバイナリ内に含まれていること
      final content = String.fromCharCodes(
        pdfBytes.where((b) => b >= 32 && b <= 126),
      );
      expect(content.contains('/Font'), isTrue);
      expect(content.contains('/Type'), isTrue);
    });
  });
}
