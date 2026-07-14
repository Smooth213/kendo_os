import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// 純粋 Dart (image パッケージ) を使用した、クロスプラットフォーム画像圧縮ユーティリティ。
/// Web / Native の両方で全く同一のコードで安定して動作します。
class ImageCompressor {
  /// 画像データの圧縮・リサイズを非同期で行います。
  /// [bytes] を受け取り、圧縮された `Uint8List` を返します。
  ///
  /// メモリ負荷を考慮し、処理全体は `compute`（別スレッド / Web Worker）を介して実行されます。
  ///
  /// [maxWidth]、[maxHeight] を超える場合は、アスペクト比を維持して縮小します。
  /// HEICなど Dart (image) でデコードできない形式の場合は、例外をスローせず `null` を返却し、
  /// 呼び出し元で安全に「オリジナルファイルのままアップロード」するフォールバック設計となっています。
  static Future<Uint8List?> compress({
    required Uint8List bytes,
    int maxWidth = 2000,
    int maxHeight = 2000,
    int quality = 80,
  }) async {
    try {
      // 巨大データのデコードによるメモリ圧迫を防ぐため、バックグラウンドで処理します。
      return await compute(_compressInternal, {
        'bytes': bytes,
        'maxWidth': maxWidth,
        'maxHeight': maxHeight,
        'quality': quality,
      });
    } catch (e) {
      debugPrint('⚠️ [ImageCompressor] 圧縮処理中に例外が発生しました。フォールバックします: $e');
      return null;
    }
  }

  /// バックグラウンドスレッドで実行される同期処理の本体
  static Uint8List? _compressInternal(Map<String, dynamic> args) {
    final Uint8List inputBytes = args['bytes'] as Uint8List;
    final int maxWidth = args['maxWidth'] as int;
    final int maxHeight = args['maxHeight'] as int;
    final int quality = args['quality'] as int;

    // 1. デコードを試みる
    final img.Image? image = img.decodeImage(inputBytes);
    if (image == null) {
      // HEICなど未サポートの形式の場合は、呼び出し元でオリジナルを使うように null を返す
      debugPrint('⚠️ [ImageCompressor] 未サポートまたは破損画像のため、デコードをスキップしました。');
      return null;
    }

    // 2. 解像度が最大制限を超える場合はアスペクト比を維持してリサイズ
    img.Image resized = image;
    if (image.width > maxWidth || image.height > maxHeight) {
      final double aspectRatio = image.width / image.height;
      int targetWidth;
      int targetHeight;

      if (aspectRatio > 1) {
        // 横長画像
        targetWidth = maxWidth;
        targetHeight = (maxWidth / aspectRatio).round();
      } else {
        // 縦長または正方形画像
        targetHeight = maxHeight;
        targetWidth = (maxHeight * aspectRatio).round();
      }

      resized = img.copyResize(image, width: targetWidth, height: targetHeight);
    }

    // 3. 指定された品質でJPEG形式としてエンコード
    final Uint8List outputBytes = Uint8List.fromList(
      img.encodeJpg(resized, quality: quality),
    );

    return outputBytes;
  }
}
