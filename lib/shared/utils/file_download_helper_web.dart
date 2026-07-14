// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

/// Webプラットフォームでのファイルダウンロードを支援するヘルパー（Web用実体：package:web 版）
void downloadFileWeb(Uint8List bytes, String filename, String mimeType) {
  final jsBytes = bytes.toJS;
  final blob = web.Blob([jsBytes].toJS, web.BlobPropertyBag(type: mimeType));
  final url = web.URL.createObjectURL(blob);

  final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = url;
  anchor.download = filename;
  anchor.style.display = 'none';

  web.document.body?.appendChild(anchor);
  anchor.click();
  web.document.body?.removeChild(anchor);
  web.URL.revokeObjectURL(url);
}

/// Webプラットフォームでのファイル共有を支援するヘルパー（Web用実体：navigator.share 直接駆動版）
Future<bool> shareFilesWeb(
  List<Uint8List> filesBytes,
  List<String> filenames,
  String mimeType,
  String text,
) async {
  final navigator = web.window.navigator;

  // 1. navigator.share / canShare が存在するか確認
  if (!navigator.hasProperty('share'.toJS).toDart ||
      !navigator.hasProperty('canShare'.toJS).toDart) {
    return false;
  }

  // 2. JSの File オブジェクトの配列を作成
  final jsFiles = <web.File>[].toJS;
  for (int i = 0; i < filesBytes.length; i++) {
    final bytes = filesBytes[i];
    final filename = filenames[i];

    final blobParts = [bytes.toJS].toJS;
    final file = web.File(
      blobParts,
      filename,
      web.FilePropertyBag(type: mimeType),
    );
    jsFiles.add(file);
  }

  // 3. 共有データオブジェクトを JSObject として安全に構築
  final shareData =
      {'files': jsFiles, 'text': text, 'title': '公式記録'}.jsify() as JSObject;

  try {
    // 4. canShare を呼び出す
    final canShareFn = navigator.getProperty('canShare'.toJS) as JSFunction;
    final isShareable =
        (canShareFn.callAsFunction(navigator, shareData) as JSBoolean).toDart;
    if (!isShareable) {
      return false;
    }

    // 5. share を呼び出す（Promiseを返却するため、JSPromise を toDart で await）
    final shareFn = navigator.getProperty('share'.toJS) as JSFunction;
    final promise = shareFn.callAsFunction(navigator, shareData) as JSPromise;
    await promise.toDart;
    return true;
  } catch (e) {
    return false;
  }
}
