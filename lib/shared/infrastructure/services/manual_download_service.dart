import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// マニュアルPDFのダウンロードとローカル保存・キャッシュ状態チェックを管理するサービス
class ManualDownloadService {
  /// ダウンロードしたファイルが保存されるローカルのディレクトリパスを取得する
  Future<String> _getLocalDirectoryPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  /// 指定されたファイル名がローカルに保存されているか確認する
  Future<bool> isFileDownloaded(String fileName) async {
    if (kIsWeb) return false; // Webはローカル保存を行わない
    try {
      final dirPath = await _getLocalDirectoryPath();
      final file = File('$dirPath/$fileName');
      return await file.exists();
    } catch (e) {
      debugPrint('Error checking file existence: $e');
      return false;
    }
  }

  /// 保存されたローカルのFileオブジェクトを取得する（存在しない場合はnull）
  Future<File?> getLocalFile(String fileName) async {
    if (kIsWeb) return null;
    try {
      final dirPath = await _getLocalDirectoryPath();
      final file = File('$dirPath/$fileName');
      if (await file.exists()) {
        return file;
      }
    } catch (e) {
      debugPrint('Error getting local file: $e');
    }
    return null;
  }

  /// PDFマニュアルをダウンロードして保存する。進捗率を onProgress にコールバックする。
  Future<File?> downloadManual(
    String fileName,
    String downloadUrl,
    void Function(double progress) onProgress,
  ) async {
    if (kIsWeb) return null;

    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(downloadUrl));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw HttpException(
          'Failed to download file: status code ${response.statusCode}',
        );
      }

      final contentLength = response.contentLength ?? 1;
      int downloadedBytes = 0;
      final List<int> bytes = [];

      await for (final chunk in response.stream) {
        bytes.addAll(chunk);
        downloadedBytes += chunk.length;
        // 進捗率をコールバック (0.0 から 1.0)
        onProgress(downloadedBytes / contentLength);
      }

      final dirPath = await _getLocalDirectoryPath();
      final file = File('$dirPath/$fileName');
      await file.writeAsBytes(bytes, flush: true);
      return file;
    } catch (e) {
      debugPrint('Error downloading manual: $e');
      rethrow;
    } finally {
      client.close();
    }
  }

  /// ダウンロードしたローカルファイルを削除する（テスト用・キャッシュクリア用）
  Future<void> deleteLocalFile(String fileName) async {
    if (kIsWeb) return;
    try {
      final dirPath = await _getLocalDirectoryPath();
      final file = File('$dirPath/$fileName');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error deleting local file: $e');
    }
  }
}
