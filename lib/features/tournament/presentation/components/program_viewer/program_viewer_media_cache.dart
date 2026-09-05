import 'dart:async';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;

/// プログラムビューワー用の画像サイズ取得・PDFバイトキャッシュヘルパー
class ProgramViewerMediaCache {
  static final ProgramViewerMediaCache shared = ProgramViewerMediaCache();

  final Map<String, Future<Size>> imageSizeCache = {};
  final Map<String, Future<Uint8List>> sdkPdfBytesCache = {};
  final int sessionBuster = DateTime.now().millisecondsSinceEpoch;

  String getSafeUrl(String url) {
    if (!kIsWeb || url.isEmpty || !url.startsWith('http')) return url;
    final separator = url.contains('?') ? '&' : '?';
    return '$url${separator}_cb=$sessionBuster';
  }

  Future<Uint8List> getCachedPdfBytesViaSdk(String url) {
    return getCachedPdfBytes(url);
  }

  Future<Uint8List> getCachedPdfBytes(String url) {
    if (!sdkPdfBytesCache.containsKey(url)) {
      sdkPdfBytesCache[url] = _fetchPdfBytes(url);
    }
    return sdkPdfBytesCache[url]!;
  }

  Future<Uint8List> _fetchPdfBytes(String url) async {
    // 1. Firebase Storage URL の場合は SDK 経由で取得（Web CORS対策）
    if (url.startsWith('gs://') ||
        url.contains('firebasestorage.googleapis.com')) {
      try {
        final bytes = await FirebaseStorage.instance
            .refFromURL(url)
            .getData(32 * 1024 * 1024);
        if (bytes != null && bytes.isNotEmpty) {
          return bytes;
        }
      } catch (e) {
        debugPrint(
          '⚠️ [ProgramViewerMediaCache] SDK fetch failed, falling back to HTTP: $e',
        );
      }
    }

    // 2. HTTP フォールバック
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    }
    throw Exception(
      'Failed to load PDF bytes from $url: status ${response.statusCode}',
    );
  }

  Future<Size> fetchImageSize(String url) async {
    if (url.isEmpty || url.contains('placehold.co')) {
      return const Size(400, 600);
    }
    if (url.contains('example.com')) {
      return const Size(800, 1000);
    }
    final Completer<Size> completer = Completer();
    final safeUrl = getSafeUrl(url);
    final Image image = Image.network(safeUrl);

    final listener = ImageStreamListener(
      (ImageInfo info, bool _) {
        if (!completer.isCompleted) {
          completer.complete(
            Size(info.image.width.toDouble(), info.image.height.toDouble()),
          );
        }
      },
      onError: (dynamic exception, StackTrace? stackTrace) {
        if (!completer.isCompleted) {
          completer.complete(const Size(800, 1000));
        }
      },
    );

    image.image.resolve(const ImageConfiguration()).addListener(listener);
    return completer.future.timeout(
      const Duration(seconds: 3),
      onTimeout: () {
        if (!completer.isCompleted) {
          image.image
              .resolve(const ImageConfiguration())
              .removeListener(listener);
        }
        return const Size(800, 1000);
      },
    );
  }

  Future<Size> getCachedImageSize(String url) {
    if (!imageSizeCache.containsKey(url)) {
      imageSizeCache[url] = fetchImageSize(url);
    }
    return imageSizeCache[url]!;
  }

  void clear() {
    imageSizeCache.clear();
    sdkPdfBytesCache.clear();
  }
}
