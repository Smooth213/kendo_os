import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/utils/pdf_compressor.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('[Unit] PDF最適化ユーティリティの動作検証', () {
    test('閾値未満のPDFデータは最適化をスキップしてそのまま返却されること', () async {
      final dummyBytes = Uint8List.fromList([1, 2, 3, 4, 5]);

      final result = await PdfCompressor.compress(
        bytes: dummyBytes,
        thresholdBytes: 100, // 閾値: 100バイト
      );

      expect(result, equals(dummyBytes));
    });

    test('破損した不正なバイナリデータでも例外を投げずフォールバックしてそのまま返却されること', () async {
      final corruptBytes = Uint8List.fromList(
        List.generate(200, (i) => i % 256),
      );

      final result = await PdfCompressor.compress(
        bytes: corruptBytes,
        thresholdBytes: 50, // 閾値を下回るサイズで圧縮対象にする
      );

      expect(result, equals(corruptBytes));
    });

    test('テキストを含むPDFの最適化後も文字情報（テキスト検索性）が完全に保持されていること', () async {
      // 1. テスト用のテキスト入りPDFをメモリ上で作成
      final document = PdfDocument();
      final page = document.pages.add();
      final font = PdfStandardFont(PdfFontFamily.helvetica, 12);
      const testText = 'KendoOS Program Management Text Search Test';
      page.graphics.drawString(
        testText,
        font,
        bounds: const Rect.fromLTWH(0, 0, 500, 50),
      );
      final pdfBytes = Uint8List.fromList(document.saveSync());
      document.dispose();

      // 2. 閾値を0にして確実に最適化ロジックを通す
      final optimizedBytes = await PdfCompressor.compress(
        bytes: pdfBytes,
        thresholdBytes: 0,
      );

      expect(optimizedBytes.isNotEmpty, isTrue);

      // 3. 最適化後のPDFからテキストを抽出して検証
      final loadedDoc = PdfDocument(inputBytes: optimizedBytes);
      final extractor = PdfTextExtractor(loadedDoc);
      final extractedText = extractor.extractText();
      loadedDoc.dispose();

      expect(
        extractedText,
        contains('KendoOS Program Management Text Search Test'),
      );
    });
  });
}
