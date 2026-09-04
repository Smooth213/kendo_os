import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:pasteboard/pasteboard.dart';

/// クリップボードから大会プログラム（ファイル・画像・URL）を取得・構築するヘルパークラス
class ClipboardProgramHelper {
  final http.Client _httpClient;

  ClipboardProgramHelper({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  /// クリップボードからファイル・画像・URLを検知し、[PlatformFile] として取得する
  ///
  /// 1. クリップボード内のファイルパス（PDFや画像）を検査
  /// 2. クリップボード内の画像バイナリを検査
  /// 3. クリップボード内のテキスト（URL または file URI）を検査
  /// 4. いずれも該当しない場合は null を返却
  Future<PlatformFile?> getPlatformFileFromClipboard() async {
    try {
      // 1. クリップボード内のファイルパス（iOS/Android/macOS等でPDFを「コピー」した場合）
      final fileFromClipboard = await extractFileFromPasteboard();
      if (fileFromClipboard != null) {
        return fileFromClipboard;
      }

      // 2. クリップボード内の画像バイナリを検査
      final imageBytes = await extractImageFromClipboard();
      if (imageBytes != null && imageBytes.isNotEmpty) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        return PlatformFile(
          name: 'clipboard_image_$timestamp.png',
          size: imageBytes.length,
          bytes: imageBytes,
        );
      }

      // 3. テキスト・URL の検査
      final textData = await Clipboard.getData(Clipboard.kTextPlain);
      final text = textData?.text?.trim() ?? '';
      if (text.isNotEmpty) {
        if (_isValidHttpUrl(text)) {
          return await extractFileFromUrl(text);
        } else if (!kIsWeb && text.startsWith('file://')) {
          return await _extractFromFileUri(text);
        }
      }
    } catch (e) {
      debugPrint('⚠️ [ClipboardProgramHelper] 取得エラー: $e');
    }

    return null;
  }

  /// クリップボードからファイルパス（PDFや画像）を取り出す
  @visibleForTesting
  Future<PlatformFile?> extractFileFromPasteboard() async {
    try {
      final paths = await Pasteboard.files();
      if (paths.isNotEmpty) {
        for (final path in paths) {
          final lower = path.toLowerCase();
          if (lower.endsWith('.pdf') ||
              lower.endsWith('.png') ||
              lower.endsWith('.jpg') ||
              lower.endsWith('.jpeg')) {
            if (!kIsWeb) {
              final ioFile = File(path);
              if (await ioFile.exists()) {
                final bytes = await ioFile.readAsBytes();
                final fileName = path.split('/').last.split('\\').last;
                return PlatformFile(
                  name: fileName,
                  path: path,
                  bytes: bytes,
                  size: bytes.length,
                );
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ [ClipboardProgramHelper] ファイルパス取得失敗: $e');
    }
    return null;
  }

  /// クリップボードから画像バイト列を取り出す（画像がない場合は null）
  @visibleForTesting
  Future<Uint8List?> extractImageFromClipboard() async {
    try {
      return await Pasteboard.image;
    } catch (e) {
      debugPrint('⚠️ [ClipboardProgramHelper] 画像取得失敗: $e');
      return null;
    }
  }

  /// 指定された URL からデータをダウンロードし、[PlatformFile] を生成する
  @visibleForTesting
  Future<PlatformFile?> extractFileFromUrl(String url) async {
    try {
      final normalizedUrl = normalizeUrl(url);
      final uri = Uri.parse(normalizedUrl);
      final response = await _httpClient.get(uri);

      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        return null;
      }

      final contentType = response.headers['content-type']?.toLowerCase() ?? '';
      final pathSegments = uri.pathSegments;
      final rawFileName = pathSegments.isNotEmpty ? pathSegments.last : '';

      String extension = '';
      if (contentType.contains('pdf') ||
          rawFileName.toLowerCase().endsWith('.pdf')) {
        extension = 'pdf';
      } else if (contentType.contains('png') ||
          rawFileName.toLowerCase().endsWith('.png')) {
        extension = 'png';
      } else if (contentType.contains('jpeg') ||
          contentType.contains('jpg') ||
          rawFileName.toLowerCase().endsWith('.jpg') ||
          rawFileName.toLowerCase().endsWith('.jpeg')) {
        extension = 'jpg';
      } else {
        // 画像やPDF以外のコンテンツ（HTMLなど）は除外
        return null;
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = rawFileName.isNotEmpty && rawFileName.contains('.')
          ? rawFileName
          : 'downloaded_program_$timestamp.$extension';

      return PlatformFile(
        name: fileName,
        size: response.bodyBytes.length,
        bytes: response.bodyBytes,
      );
    } catch (e) {
      debugPrint('⚠️ [ClipboardProgramHelper] URLダウンロード失敗: $e');
      return null;
    }
  }

  /// Google Drive や Dropbox などの共有リンクを直接ダウンロード可能なURLに正規化
  @visibleForTesting
  String normalizeUrl(String url) {
    // Google Drive: https://drive.google.com/file/d/{ID}/view...
    final gDriveMatch = RegExp(
      r'https:\/\/drive\.google\.com\/file\/d\/([a-zA-Z0-9_-]+)',
    ).firstMatch(url);
    if (gDriveMatch != null) {
      final fileId = gDriveMatch.group(1);
      return 'https://drive.google.com/uc?export=download&id=$fileId';
    }

    // Dropbox: ?dl=0 -> ?dl=1
    if (url.contains('dropbox.com') && url.contains('dl=0')) {
      return url.replaceAll('dl=0', 'dl=1');
    }

    return url;
  }

  Future<PlatformFile?> _extractFromFileUri(String fileUri) async {
    try {
      final filePath = Uri.parse(fileUri).toFilePath();
      final ioFile = File(filePath);
      if (await ioFile.exists()) {
        final bytes = await ioFile.readAsBytes();
        final fileName = filePath.split('/').last.split('\\').last;
        return PlatformFile(
          name: fileName,
          path: filePath,
          bytes: bytes,
          size: bytes.length,
        );
      }
    } catch (e) {
      debugPrint('⚠️ [ClipboardProgramHelper] file:// 読込失敗: $e');
    }
    return null;
  }

  bool _isValidHttpUrl(String string) {
    final uri = Uri.tryParse(string);
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }
}
