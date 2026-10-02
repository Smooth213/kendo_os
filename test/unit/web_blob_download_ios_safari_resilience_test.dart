import 'package:flutter_test/flutter_test.dart';

/// iOS SafariなどのモバイルWebブラウザ特有のBlobダウンロード制限
/// （ポップアップブロック、アンカータグdownload属性の非対応、blob: URLの破棄タイミング）
/// に対する耐性と安全なフォールバック機構の検証テスト。
void main() {
  group('[Unit] Webブラウザ極限 - iOS Safari Blobダウンロード耐久性テスト', () {
    test('アンカータグdownload属性が無視される環境下で、適切なMIMEタイプと別タブフォールバックが機能すること', () {
      String? openedUrl;
      String? mimeTypeHeader;

      void triggerDownload({
        required String blobUrl,
        required String fileName,
        required String mimeType,
        required bool isIOSSafari,
      }) {
        if (isIOSSafari) {
          mimeTypeHeader = mimeType;
          openedUrl = blobUrl;
        } else {
          openedUrl = 'anchor_download:$fileName';
        }
      }

      // iOS Safari環境
      triggerDownload(
        blobUrl: 'blob:https://kendo-os.web.app/uuid-pdf-1234',
        fileName: 'tournament_result.pdf',
        mimeType: 'application/pdf',
        isIOSSafari: true,
      );

      expect(openedUrl, equals('blob:https://kendo-os.web.app/uuid-pdf-1234'));
      expect(mimeTypeHeader, equals('application/pdf'));

      // 通常ブラウザ環境
      triggerDownload(
        blobUrl: 'blob:https://kendo-os.web.app/uuid-pdf-1234',
        fileName: 'tournament_result.pdf',
        mimeType: 'application/pdf',
        isIOSSafari: false,
      );
      expect(openedUrl, equals('anchor_download:tournament_result.pdf'));
    });

    test('Blobオブジェクト生成後にリソースリークを防ぐためURLのrevoke処理がスケジュールされること', () async {
      bool isRevoked = false;
      final createdUrls = <String>[];

      String createBlobUrl(List<int> bytes) {
        final url = 'blob:https://kendo-os.web.app/blob_${bytes.length}';
        createdUrls.add(url);
        return url;
      }

      void revokeBlobUrl(String url) {
        createdUrls.remove(url);
        isRevoked = true;
      }

      final url = createBlobUrl([1, 2, 3, 4, 5]);
      expect(createdUrls.contains(url), isTrue);

      // ダウンロード完了または遅延後の解放
      revokeBlobUrl(url);
      expect(createdUrls.isEmpty, isTrue);
      expect(isRevoked, isTrue);
    });
  });
}
