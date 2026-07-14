import 'dart:typed_data';

/// Webプラットフォームでのファイルダウンロードを支援するヘルパー（スタブ定義）
void downloadFileWeb(Uint8List bytes, String filename, String mimeType) {
  // ネイティブ環境では何もしません
}

/// Webプラットフォームでのファイル共有を支援するヘルパー（スタブ定義）
Future<bool> shareFilesWeb(
  List<Uint8List> filesBytes,
  List<String> filenames,
  String mimeType,
  String text,
) async {
  return false;
}
