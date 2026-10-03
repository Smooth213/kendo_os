import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// PDFのマルチページ縦横混在バグを完全に回避するため、
/// 各ページを「単一ページPDF」として動的に抽出・キャッシュし、
/// ページの向きに応じたキャンバスサイズ（1000x1414 または 1414x1000）を提供するキャッシュ機構
class ProgramViewerPdfPageCache {
  static final ProgramViewerPdfPageCache shared = ProgramViewerPdfPageCache();

  /// 🔋 キャッシュする最大単一ページPDF数（LRU上限）
  static const int maxCachedPagesPerDoc = 8;

  /// URL -> (pageIndex -> 単一ページPDFのバイナリ)（挿入順を利用したLRUキャッシュ）
  final Map<String, Map<int, Uint8List>> _singlePageBytesCache = {};

  /// URL -> (pageIndex -> OSネイティブ高精細ラスタライズ画像PNG)
  final Map<String, Map<int, Uint8List>> _renderedPageImageCache = {};

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
  int parseDocumentInfo(
    String url,
    Uint8List sourceBytes, {
    bool force = false,
  }) {
    if (force) {
      _pageCountCache.remove(url);
      _pageCanvasSizeCache.remove(url);
    }
    final cachedCount = _pageCountCache[url];
    final cachedSizes = _pageCanvasSizeCache[url];
    final hasAllPageSizes =
        cachedCount != null &&
        cachedSizes != null &&
        List.generate(
          cachedCount,
          cachedSizes.containsKey,
        ).every((hasSize) => hasSize);
    if (cachedCount != null && hasAllPageSizes) {
      return cachedCount;
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
      debugPrint(
        '[ERROR] [ProgramViewerPdfPageCache] parseDocumentInfo error: $e',
      );
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

        // 対象のページ以外を末尾から削除して、完全なフォント・リソース構造（CIDFont/TrueType/画像）を保持したまま単一ページ化
        for (int i = totalPages - 1; i >= 0; i--) {
          if (i != safeIndex) {
            sourceDoc.pages.removeAt(i);
          }
        }
        final List<int> savedBytes = sourceDoc.saveSync();
        return Uint8List.fromList(savedBytes);
      } finally {
        sourceDoc.dispose();
      }
    } catch (e) {
      debugPrint(
        '[ERROR] [ProgramViewerPdfPageCache] extractSinglePage fallback: $e',
      );
      return sourceBytes;
    }
  }

  /// 単一ページのPDFバイト列を取得（キャッシュがあれば即時返却、なければ抽出してキャッシュ）
  /// 🔋 LRU（直近利用エントリを最新化、上限8件超過で最古エントリを自動破棄）
  Uint8List getOrExtractSinglePage(
    String url,
    Uint8List sourceBytes,
    int pageIndex,
  ) {
    final pageMap = _singlePageBytesCache.putIfAbsent(url, () => {});
    if (pageMap.containsKey(pageIndex)) {
      // LRU更新: アクセスされたキーを末尾（最新）に移動
      final bytes = pageMap.remove(pageIndex)!;
      pageMap[pageIndex] = bytes;
      return bytes;
    }

    // 初回ならドキュメント情報も更新
    if (!_pageCountCache.containsKey(url)) {
      parseDocumentInfo(url, sourceBytes);
    }

    final Uint8List singlePageBytes = extractSinglePage(sourceBytes, pageIndex);

    // LRU上限チェック: 上限に達していたら最も古いエントリ（先頭）を削除してメモリ解放
    if (pageMap.length >= maxCachedPagesPerDoc) {
      final oldestKey = pageMap.keys.first;
      pageMap.remove(oldestKey);
    }

    pageMap[pageIndex] = singlePageBytes;
    return singlePageBytes;
  }

  /// OSネイティブ高精細ラスタライズ画像を取得（フォント非埋め込み日本語PDFもOSシステムフォントで完全描画）
  Future<Uint8List?> getOrRenderPageImage(
    String url,
    Uint8List sourceBytes,
    int pageIndex,
  ) async {
    final pageMap = _renderedPageImageCache.putIfAbsent(url, () => {});
    if (pageMap.containsKey(pageIndex)) {
      return pageMap[pageIndex];
    }

    try {
      await for (final page in Printing.raster(
        sourceBytes,
        pages: [pageIndex],
        dpi: 200,
      )) {
        final pngBytes = await page.toPng();
        if (pageMap.length >= maxCachedPagesPerDoc) {
          final oldestKey = pageMap.keys.first;
          pageMap.remove(oldestKey);
        }
        pageMap[pageIndex] = pngBytes;
        return pngBytes;
      }
    } catch (e) {
      debugPrint(
        '[WARN] [ProgramViewerPdfPageCache] Printing.raster error: $e',
      );
    }
    return null;
  }

  /// 指定したURLの現在キャッシュされている単一ページ数を取得（LRU検証・メモリ監視用）
  int getCachedSinglePageCount(String url) {
    return _singlePageBytesCache[url]?.length ?? 0;
  }

  /// 特定URLのPDF単一ページバイナリキャッシュを解放（keepDocumentInfo: false の場合はページ情報も破棄）
  void clearUrl(String url, {bool keepDocumentInfo = true}) {
    _singlePageBytesCache.remove(url);
    _renderedPageImageCache.remove(url);
    if (!keepDocumentInfo) {
      _pageCanvasSizeCache.remove(url);
      _pageCountCache.remove(url);
    }
  }

  /// 全キャッシュのクリア（メモリ解放用）
  void clear() {
    _singlePageBytesCache.clear();
    _renderedPageImageCache.clear();
    _pageCanvasSizeCache.clear();
    _pageCountCache.clear();
  }
}
