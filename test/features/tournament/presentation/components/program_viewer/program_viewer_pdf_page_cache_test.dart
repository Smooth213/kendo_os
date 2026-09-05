import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/tournament/presentation/components/program_viewer/program_viewer_pdf_page_cache.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

void main() {
  group('🥋 ProgramViewerPdfPageCache 縦横混在PDF動的抽出＆キャンバス比率 単体テスト', () {
    late Uint8List mixedPdfBytes;

    setUp(() {
      ProgramViewerPdfPageCache.shared.clear();

      // 縦横混在の3ページPDFを生成
      // Page 0: 縦向き (A4: 595 x 842)
      // Page 1: 横向き (A4横: 842 x 595)
      // Page 2: 90度回転による横向き
      final PdfDocument doc = PdfDocument();

      // Section 0: 縦 (A4縦)
      final sec0 = doc.sections!.add();
      sec0.pageSettings.size = const Size(595, 842);
      sec0.pageSettings.margins.all = 0;
      final p0 = sec0.pages.add();
      p0.graphics.drawString(
        'Page 1 Portrait',
        PdfStandardFont(PdfFontFamily.helvetica, 20),
        bounds: const Rect.fromLTWH(20, 20, 200, 50),
      );

      // Section 1: 横向き (A4横)
      final sec1 = doc.sections!.add();
      sec1.pageSettings.orientation = PdfPageOrientation.landscape;
      sec1.pageSettings.margins.all = 0;
      final p1 = sec1.pages.add();
      p1.graphics.drawString(
        'Page 2 Landscape',
        PdfStandardFont(PdfFontFamily.helvetica, 20),
        bounds: const Rect.fromLTWH(20, 20, 200, 50),
      );

      // Section 2: 回転による横向き (rotation = 90)
      final sec2 = doc.sections!.add();
      sec2.pageSettings.rotate = PdfPageRotateAngle.rotateAngle90;
      sec2.pageSettings.margins.all = 0;
      final p2 = sec2.pages.add();
      p2.graphics.drawString(
        'Page 3 Rotated 90',
        PdfStandardFont(PdfFontFamily.helvetica, 20),
        bounds: const Rect.fromLTWH(20, 20, 200, 50),
      );

      mixedPdfBytes = Uint8List.fromList(doc.saveSync());
      doc.dispose();
    });

    test('1. parseDocumentInfo で縦横混在の各ページが最適なキャンバスサイズに分類されること', () {
      const url = 'https://example.com/mixed.pdf';
      final totalCount = ProgramViewerPdfPageCache.shared.parseDocumentInfo(
        url,
        mixedPdfBytes,
      );

      expect(totalCount, equals(3));
      expect(
        ProgramViewerPdfPageCache.shared.getCachedPageCount(url),
        equals(3),
      );

      // Page 0: 縦向き -> Size(1000, 1414)
      final size0 = ProgramViewerPdfPageCache.shared.getPageCanvasSize(url, 0);
      expect(size0, equals(const Size(1000.0, 1414.0)));

      // Page 1: 横向き -> Size(1414, 1000)
      final size1 = ProgramViewerPdfPageCache.shared.getPageCanvasSize(url, 1);
      expect(size1, equals(const Size(1414.0, 1000.0)));

      // Page 2: 90度回転横向き -> Size(1414, 1000)
      final size2 = ProgramViewerPdfPageCache.shared.getPageCanvasSize(url, 2);
      expect(size2, equals(const Size(1414.0, 1000.0)));
    });

    test('2. extractSinglePage で抽出されたPDFが常に総ページ数「1」であること', () {
      // Page 0 抽出
      final singleP0Bytes = ProgramViewerPdfPageCache.shared.extractSinglePage(
        mixedPdfBytes,
        0,
      );
      final docP0 = PdfDocument(inputBytes: singleP0Bytes);
      expect(docP0.pages.count, equals(1), reason: '抽出されたPDFは単一ページでなければなりません');
      docP0.dispose();

      // Page 1 抽出
      final singleP1Bytes = ProgramViewerPdfPageCache.shared.extractSinglePage(
        mixedPdfBytes,
        1,
      );
      final docP1 = PdfDocument(inputBytes: singleP1Bytes);
      expect(docP1.pages.count, equals(1), reason: '横向きページも単一ページでなければなりません');
      final p1Page = docP1.pages[0];
      final bool p1Rotated =
          p1Page.rotation.name.contains('90') ||
          p1Page.rotation.name.contains('270');
      final double p1EffWidth = p1Rotated
          ? p1Page.size.height
          : p1Page.size.width;
      final double p1EffHeight = p1Rotated
          ? p1Page.size.width
          : p1Page.size.height;
      expect(p1EffWidth > p1EffHeight, isTrue, reason: '横向きのページ幅が保持されていること');
      docP1.dispose();

      // Page 2 抽出（回転90度）
      final singleP2Bytes = ProgramViewerPdfPageCache.shared.extractSinglePage(
        mixedPdfBytes,
        2,
      );
      final docP2 = PdfDocument(inputBytes: singleP2Bytes);
      expect(docP2.pages.count, equals(1));
      expect(
        docP2.pages[0].rotation,
        equals(PdfPageRotateAngle.rotateAngle90),
        reason: '回転角90度が保持されていること',
      );
      docP2.dispose();
    });

    test('3. getOrExtractSinglePage でキャッシュが正しく効くこと', () {
      const url = 'https://example.com/cached.pdf';

      final firstCall = ProgramViewerPdfPageCache.shared.getOrExtractSinglePage(
        url,
        mixedPdfBytes,
        1,
      );
      final secondCall = ProgramViewerPdfPageCache.shared
          .getOrExtractSinglePage(url, mixedPdfBytes, 1);

      expect(
        identical(firstCall, secondCall),
        isTrue,
        reason: '同一インスタンスが返却され再抽出が発生しないこと',
      );
    });

    test('4. 異常系・単一ページPDFの場合は安全にバイナリをそのままパススルーすること', () {
      final singleDoc = PdfDocument();
      singleDoc.pages.add();
      final singleBytes = Uint8List.fromList(singleDoc.saveSync());
      singleDoc.dispose();

      final result = ProgramViewerPdfPageCache.shared.extractSinglePage(
        singleBytes,
        0,
      );
      expect(
        identical(result, singleBytes),
        isTrue,
        reason: '1ページのPDFは再抽出せずそのまま返却',
      );

      // 不正なダミーバイナリでも例外にならずフォールバックすること
      final dummyBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final fallbackResult = ProgramViewerPdfPageCache.shared.extractSinglePage(
        dummyBytes,
        0,
      );
      expect(fallbackResult, equals(dummyBytes));
    });
  });
}
