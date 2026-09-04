import 'dart:convert';
import 'dart:io' as io;
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';

/// 📶 【Phase 9】通信パケット・同期ペイロード極小化ヘルパー
///
/// 体育館などの微弱電波やテザリング環境において、大量の試合データや
/// バックアップ、P2P同期メッセージのサイズを 70%〜90% 削減します。
/// Native では OS ネイティブの C 最速 zlib（dart:io gzip）を使用し、
/// Web 環境では pure Dart（package:archive）に自動フォールバックします。
class PayloadCompressionHelper {
  /// Gzip マジックバイト（0x1f, 0x8b）
  static const List<int> gzipMagicBytes = [0x1f, 0x8b];

  /// スマート圧縮の最小閾値（バイト数）。これ以下の極小データは圧縮してもヘッダーオーバーヘッドで増えるため生転送を推奨。
  static const int minCompressionThreshold = 256;

  /// バイト配列が Gzip 形式であるかを高速判定
  static bool isGzip(List<int> bytes) {
    if (bytes.length < 2) return false;
    return bytes[0] == gzipMagicBytes[0] && bytes[1] == gzipMagicBytes[1];
  }

  /// バイト配列を Gzip 圧縮
  static Uint8List compressBytes(List<int> input) {
    if (input.isEmpty) return Uint8List(0);

    if (!kIsWeb) {
      try {
        final compressed = io.gzip.encode(input);
        return Uint8List.fromList(compressed);
      } catch (e) {
        debugPrint(
          '⚠️ [Compression] io.gzip failed, falling back to archive: $e',
        );
      }
    }

    final compressed = GZipEncoder().encode(input);
    return Uint8List.fromList(compressed);
  }

  /// Gzip 圧縮されたバイト配列を解凍
  static Uint8List decompressBytes(List<int> input) {
    if (input.isEmpty) return Uint8List(0);

    // Gzip マジックヘッダーが存在しない場合はそのまま返却
    if (!isGzip(input)) {
      return Uint8List.fromList(input);
    }

    if (!kIsWeb) {
      try {
        final decompressed = io.gzip.decode(input);
        return Uint8List.fromList(decompressed);
      } catch (e) {
        debugPrint(
          '⚠️ [Decompression] io.gzip failed, falling back to archive: $e',
        );
      }
    }

    final decompressed = GZipDecoder().decodeBytes(input);
    return Uint8List.fromList(decompressed);
  }

  /// 文字列（JSON等）を Gzip 圧縮バイト配列に変換
  static Uint8List compressString(String text) {
    if (text.isEmpty) return Uint8List(0);
    final utf8Bytes = utf8.encode(text);
    return compressBytes(utf8Bytes);
  }

  /// Gzip 圧縮バイト配列を UTF-8 文字列に解凍
  static String decompressToString(List<int> compressedBytes) {
    if (compressedBytes.isEmpty) return '';
    final decompressedBytes = decompressBytes(compressedBytes);
    return utf8.decode(decompressedBytes);
  }

  /// 文字列（JSON等）を圧縮し、安全な Base64 文字列として返却（FirestoreやテキストWebSokcet等での送信用）
  static String compressToBase64(String text) {
    if (text.isEmpty) return '';
    final compressed = compressString(text);
    return base64Encode(compressed);
  }

  /// Base64 形式の圧縮文字列を元のテキストに解凍
  static String decompressFromBase64(String base64Str) {
    if (base64Str.isEmpty) return '';
    final bytes = base64Decode(base64Str);
    return decompressToString(bytes);
  }

  /// 圧縮率（0.0 〜 1.0）を計算（例: 0.25 = 元のサイズの25%に圧縮、75%削減）
  static double calculateCompressionRatio({
    required int originalSize,
    required int compressedSize,
  }) {
    if (originalSize <= 0) return 0.0;
    return compressedSize / originalSize;
  }

  /// 削減率のパーセント（0.0 〜 100.0%）を計算（例: 75.0% 削減）
  static double calculateSavingsPercent({
    required int originalSize,
    required int compressedSize,
  }) {
    if (originalSize <= 0) return 0.0;
    final ratio = calculateCompressionRatio(
      originalSize: originalSize,
      compressedSize: compressedSize,
    );
    return ((1.0 - ratio) * 100.0).clamp(0.0, 100.0);
  }
}
