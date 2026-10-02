import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';

/// Web Share API 共有とBlobダウンロードフォールバックのシミュレーション
class MockWebShareDownloadPipeline {
  bool shareApiSupported = true;
  bool userAbortedShare = false;
  final List<String> downloadedFiles = [];
  final List<String> revokedBlobUrls = [];

  Future<bool> shareFiles({
    required List<Uint8List> filesBytes,
    required List<String> filenames,
    required String mimeType,
  }) async {
    if (!shareApiSupported) {
      return false;
    }
    if (userAbortedShare) {
      // ユーザーが共有シートをキャンセルした場合（AbortError）
      return false;
    }
    return true;
  }

  void downloadBlob(Uint8List bytes, String filename) {
    downloadedFiles.add(filename);
    final blobUrl = 'blob:mock-uuid-$filename';
    // ダウンロードトリガー後に即時revoke
    revokedBlobUrls.add(blobUrl);
  }

  Future<void> executeExportFlow({
    required List<Uint8List> filesBytes,
    required List<String> filenames,
    required String mimeType,
  }) async {
    final success = await shareFiles(
      filesBytes: filesBytes,
      filenames: filenames,
      mimeType: mimeType,
    );

    if (!success) {
      // フォールバック: 個別Blobダウンロード
      for (int i = 0; i < filesBytes.length; i++) {
        downloadBlob(filesBytes[i], filenames[i]);
      }
    }
  }
}

void main() {
  group('[Unit] WebShareAPIユーザーキャンセル時ダウンロードフォールバックテスト', () {
    test('ユーザーが共有シートをキャンセルした場合に自動で個別ファイルダウンロードへフォールバックすること', () async {
      final pipeline = MockWebShareDownloadPipeline()
        ..shareApiSupported = true
        ..userAbortedShare = true; // ユーザーがキャンセル

      final files = [
        Uint8List.fromList([1, 2, 3]),
        Uint8List.fromList([4, 5, 6]),
      ];
      final names = ['page_1.png', 'page_2.png'];

      await pipeline.executeExportFlow(
        filesBytes: files,
        filenames: names,
        mimeType: 'image/png',
      );

      // キャンセル時は全ファイルがダウンロードフォールバックされること
      expect(pipeline.downloadedFiles.length, 2);
      expect(pipeline.downloadedFiles, contains('page_1.png'));
      expect(pipeline.downloadedFiles, contains('page_2.png'));
      // メモリリーク防止のため全Blobが破棄スケジュールされること
      expect(pipeline.revokedBlobUrls.length, 2);
    });

    test('WebShareAPI非対応のデスクトップ環境で直接ダウンロードフォールバックが稼働すること', () async {
      final pipeline = MockWebShareDownloadPipeline()
        ..shareApiSupported = false; // 非対応

      final files = [
        Uint8List.fromList([10, 20]),
      ];
      final names = ['official_record.pdf'];

      await pipeline.executeExportFlow(
        filesBytes: files,
        filenames: names,
        mimeType: 'application/pdf',
      );

      expect(pipeline.downloadedFiles.length, 1);
      expect(pipeline.downloadedFiles.first, 'official_record.pdf');
      expect(pipeline.revokedBlobUrls.length, 1);
    });
  });
}
