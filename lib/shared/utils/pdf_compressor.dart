import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// 純粋 Dart / Syncfusion Flutter PDF を使用したクロスプラットフォーム PDF 最適化ユーティリティ。
/// テキストストリームやベクター情報を破壊することなく、PDF の内部データ構造を最適化します。
class PdfCompressor {
  /// 最適化を実行するデフォルトのファイルサイズ閾値（3MB）
  static const int defaultThresholdBytes = 3 * 1024 * 1024;

  /// PDF データの最適化・軽量化を非同期で行います。
  /// [bytes] を受け取り、最適化された `Uint8List` を返します。
  ///
  /// - [thresholdBytes] 未満の場合は、処理オーバーヘッドを避けるため最適化をスキップし [bytes] をそのまま返します。
  /// - テキストレイヤーやベクター情報は維持され、文字検索がそのまま機能します。
  /// - 最適化後のサイズが元のサイズ以上になる場合や、例外が発生した場合は、
  ///   呼び出し元で安全にオリジナルを使用できるよう元の [bytes] を返却します。
  static Future<Uint8List> compress({
    required Uint8List bytes,
    int thresholdBytes = defaultThresholdBytes,
  }) async {
    // 閾値未満の場合はオーバーヘッドを避けてスキップ
    if (bytes.length < thresholdBytes) {
      return bytes;
    }

    try {
      // 巨大データのパース・再構築による UI スレッドのブロックを防ぐため compute で実行
      final optimized = await compute(_compressInternal, bytes);
      return optimized ?? bytes;
    } catch (e) {
      debugPrint('[WARN] [PdfCompressor] 最適化処理中に例外が発生しました。フォールバックします: $e');
      return bytes;
    }
  }

  /// バックグラウンドスレッドで実行される同期処理の本体
  static Uint8List? _compressInternal(Uint8List inputBytes) {
    PdfDocument? document;
    try {
      document = PdfDocument(inputBytes: inputBytes);
      document.compressionLevel = PdfCompressionLevel.best;
      document.fileStructure.crossReferenceType =
          PdfCrossReferenceType.crossReferenceStream;

      final List<int> savedBytes = document.saveSync();
      if (savedBytes.isNotEmpty && savedBytes.length < inputBytes.length) {
        return Uint8List.fromList(savedBytes);
      }
      return null;
    } catch (e) {
      debugPrint('[WARN] [PdfCompressor] _compressInternal error: $e');
      return null;
    } finally {
      document?.dispose();
    }
  }
}
