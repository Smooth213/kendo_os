import 'package:url_launcher/url_launcher.dart';

/// マニュアル画面のタブ解決・定数・ブラウザ起動ヘルパー
class EmbeddedManualTabResolver {
  const EmbeddedManualTabResolver._();

  static const String fullManualUrl =
      'https://github.com/Smooth213/kendo_os/releases/download/manuals/Kendo_Sync.pdf';
  static const String fullManualFileName = 'Kendo_Sync.pdf';
  static const String defaultMarkdownPath =
      'packages/documentation_runtime/manuals/quickstart/index.md';

  static const String normalQuickGuideAsset =
      'assets/manuals/kendo_sync_quickguide.pdf';
  static const String normalQuickGuideFileName = 'kendo_sync_quickguide.pdf';

  static const String bunaiksenQuickGuideAsset =
      'assets/manuals/kendo_sync_bunaiksen_quickguide.pdf';
  static const String bunaiksenQuickGuideFileName =
      'kendo_sync_bunaiksen_quickguide.pdf';

  /// initialTab や initialFilePath から初期表示タブのインデックス (0, 1, 2) を解決する
  ///
  /// - [initialTab] が明示されている場合はそれを優先
  /// - [initialFilePath] に 'bunaiksen' が含まれる場合は 1 (部内戦クイック)
  /// - [initialFilePath] に 'quickstart' が含まれる場合は 0 (通常クイック)
  /// - それ以外は 2 (総合マニュアル)
  static int resolveInitialTabIndex({
    int? initialTab,
    String? initialFilePath,
  }) {
    if (initialTab != null) {
      if (initialTab >= 0 && initialTab <= 2) {
        return initialTab;
      }
      return 2;
    }

    if (initialFilePath != null) {
      if (initialFilePath.contains('bunaiksen')) {
        return 1;
      } else if (initialFilePath.contains('quickstart')) {
        return 0;
      } else {
        return 2;
      }
    }

    return 2; // デフォルトは総合マニュアル
  }

  /// 検索バーを表示すべきかどうかを判定
  static bool shouldShowSearch({
    required int selectedTabIndex,
    required bool isWeb,
    required bool isPdfDownloaded,
    required bool forceMarkdownFallback,
  }) {
    return selectedTabIndex == 2 &&
        (isWeb || (isPdfDownloaded && !forceMarkdownFallback));
  }

  /// PDFを外部ブラウザ（Google Docs Viewer経由）で開く
  static Future<void> openPdfInExternalViewer(String rawUrl) async {
    final encodedUrl = Uri.encodeComponent(rawUrl);
    final viewerUrl = 'https://docs.google.com/viewer?url=$encodedUrl';
    final uri = Uri.parse(viewerUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
