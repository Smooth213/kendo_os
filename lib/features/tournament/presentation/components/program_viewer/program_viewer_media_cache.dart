import 'dart:async';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// プログラムビューワー用の画像サイズ取得・PDFバイトキャッシュヘルパー
class ProgramViewerMediaCache {
  final Map<String, Future<Size>> imageSizeCache = {};
  final Map<String, Future<Uint8List>> sdkPdfBytesCache = {};
  final int sessionBuster = DateTime.now().millisecondsSinceEpoch;

  String getSafeUrl(String url) {
    if (!kIsWeb || url.isEmpty || !url.startsWith('http')) return url;
    final separator = url.contains('?') ? '&' : '?';
    return '$url${separator}_cb=$sessionBuster';
  }

  Future<Uint8List> getCachedPdfBytesViaSdk(String url) {
    if (!sdkPdfBytesCache.containsKey(url)) {
      sdkPdfBytesCache[url] = FirebaseStorage.instance
          .refFromURL(url)
          .getData(32 * 1024 * 1024)
          .then((value) => value!);
    }
    return sdkPdfBytesCache[url]!;
  }

  Future<Size> fetchImageSize(String url) async {
    if (url.isEmpty || url.contains('placehold.co')) {
      return const Size(400, 600);
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
}
