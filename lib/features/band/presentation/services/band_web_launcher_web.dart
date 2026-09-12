// ignore_for_file: avoid_web_libraries_in_flutter

import 'package:web/web.dart' as web;

/// Web環境用の直接起動（window.location.href / <a>タグ擬似クリック）
///
/// url_launcher の window.open('noopener,noreferrer') を回避し、
/// iOS PWA standalone モードで SFSafariViewController が手前に白紙で居残る問題を物理的に防ぎます。
bool launchWebDirect(String url) {
  try {
    // <a> タグを生成して target="_self" でクリック（iOS Safari / PWA で別ウィンドウを作らずアプリスキームをキック）
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
    anchor.href = url;
    anchor.target = '_self';
    anchor.style.display = 'none';
    web.document.body?.appendChild(anchor);
    anchor.click();
    web.document.body?.removeChild(anchor);
    return true;
  } catch (_) {
    try {
      web.window.location.href = url;
      return true;
    } catch (_) {
      return false;
    }
  }
}
