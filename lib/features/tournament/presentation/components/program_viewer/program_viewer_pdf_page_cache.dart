import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// PDFのマルチページ縦横混在バグを完全に回避するため、
/// 各ページを「単一ページPDF」として動的に抽出・キャッシュし、
/// ページの向きに応じたキャンバスサイズ（1000x1414 または 1414x1000）を提供するキャッシュ機構
class ProgramViewerPdfPageCache {
  static final ProgramViewerPdfPageCache shared = ProgramViewerPdfPageCache();

  /// URL -> (pageIndex -> 単一ページPDFのバイナリ)
  final Map<String, Map<int, Uint8List>> _singlePageBytesCache = {};

  /// URL -> (pageIndex -> キャンバスサイズ)
  final Map<String, Map<int, Size>> _pageCanvasSizeCache = {};

  /// URL -> 総ページ数
  final Map<String, int> _pageCountCache = {};

  /// 指定したページのキャンバスサイズを取得
  Size getPageCanvasSize(String url, int pageIndex) {
    return _pageCanvasSizeCache[url]?[pageIndex] ?? const Size(1000.0, 1414.0);
  }

  /// 指定したURLのキャッシュされた総ページ数を取得（未解析時はnull）
  int? getCachedPageCount(String url) {
    return _pageCountCache[url];
  }

  /// PDF全体のバイト列から全ページの基本情報（総ページ数、各ページの縦横比）を解析・キャッシュ
  int parseDocumentInfo(String url, Uint8List sourceBytes) {
    if (_pageCountCache.containsKey(url)) {
      return _pageCountCache[url]!;
    }

    try {
      final PdfDocument document = PdfDocument(inputBytes: sourceBytes);
      final int count = document.pages.count;
      _pageCountCache[url] = count;
      final sizeMap = _pageCanvasSizeCache.putIfAbsent(url, () => {});

      for (int i = 0; i < count; i++) {
        final page = document.pages[i];
        final size = page.size;
        final rotation = page.rotation;
        final rotationStr = rotation.name;
        final bool isRotated =
            rotationStr.contains('90') || rotationStr.contains('270');
        final double effectiveWidth = isRotated ? size.height : size.width;
        final double effectiveHeight = isRotated ? size.width : size.height;

        if (effectiveWidth > effectiveHeight) {
          // 横向きページ: 横1414 x 縦1000
          sizeMap[i] = const Size(1414.0, 1000.0);
        } else {
          // 縦向きページ: 横1000 x 縦1414
          sizeMap[i] = const Size(1000.0, 1414.0);
        }
      }
      document.dispose();
      return count;
    } catch (e) {
      debugPrint('🚨 [ProgramViewerPdfPageCache] parseDocumentInfo error: $e');
      _pageCountCache[url] = 1;
      return 1;
    }
  }

  /// 単一ページのPDFバイト列を同期抽出
  Uint8List extractSinglePage(Uint8List sourceBytes, int pageIndex) {
    try {
      final PdfDocument sourceDoc = PdfDocument(inputBytes: sourceBytes);
      try {
        final int totalPages = sourceDoc.pages.count;
        if (totalPages <= 1) {
          // 既に単一ページ以下のドキュメントなら再生成不要でそのまま返却
          return sourceBytes;
        }
        final int safeIndex = pageIndex.clamp(0, totalPages - 1);
        final PdfPage sourcePage = sourceDoc.pages[safeIndex];

        final rotationStr = sourcePage.rotation.name;
        final bool isRotated =
            rotationStr.contains('90') || rotationStr.contains('270');
        final double effectiveWidth = isRotated
            ? sourcePage.size.height
            : sourcePage.size.width;
        final double effectiveHeight = isRotated
            ? sourcePage.size.width
            : sourcePage.size.height;
        final bool isLandscape = effectiveWidth > effectiveHeight;

        final PdfDocument singleDoc = PdfDocument();
        if (isLandscape && !isRotated) {
          singleDoc.pageSettings.orientation = PdfPageOrientation.landscape;
          singleDoc.pageSettings.size = Size(effectiveWidth, effectiveHeight);
        } else {
          singleDoc.pageSettings.size = sourcePage.size;
        }
        if (sourcePage.rotation != PdfPageRotateAngle.rotateAngle0) {
          singleDoc.pageSettings.rotate = sourcePage.rotation;
        }
        singleDoc.pageSettings.margins.all = 0;

        final PdfPage newPage = singleDoc.pages.add();
        newPage.rotation = sourcePage.rotation;

        final PdfTemplate template = sourcePage.createTemplate();
        newPage.graphics.drawPdfTemplate(
          template,
          Offset.zero,
          sourcePage.size,
        );

        final List<int> savedBytes = singleDoc.saveSync();
        singleDoc.dispose();
        return Uint8List.fromList(savedBytes);
      } finally {
        sourceDoc.dispose();
      }
    } catch (e) {
      debugPrint(
        '🚨 [ProgramViewerPdfPageCache] extractSinglePage fallback: $e',
      );
      return sourceBytes;
    }
  }

  /// 単一ページのPDFバイト列を取得（キャッシュがあれば即時返却、なければ抽出してキャッシュ）
  Uint8List getOrExtractSinglePage(
    String url,
    Uint8List sourceBytes,
    int pageIndex,
  ) {
    final pageMap = _singlePageBytesCache.putIfAbsent(url, () => {});
    if (pageMap.containsKey(pageIndex)) {
      return pageMap[pageIndex]!;
    }

    // 初回ならドキュメント情報も更新
    if (!_pageCountCache.containsKey(url)) {
      parseDocumentInfo(url, sourceBytes);
    }

    final Uint8List singlePageBytes = extractSinglePage(sourceBytes, pageIndex);
    pageMap[pageIndex] = singlePageBytes;
    return singlePageBytes;
  }

  /// キャッシュのクリア（メモリ解放用）
  void clear() {
    _singlePageBytesCache.clear();
    _pageCanvasSizeCache.clear();
    _pageCountCache.clear();
  }
}
