import 'package:flutter_test/flutter_test.dart';

/// PWA運用時におけるService Workerキャッシュと最新リリースのバージョン不整合検知、
/// およびCache-Busting（キャッシュ更新通知・自動リフレッシュ）プロトコルの検証テスト。
void main() {
  group('[Unit] Webブラウザ極限 - PWA Service Workerキャッシュバージョン整合性テスト', () {
    test('サーバー側のバージョンハッシュとローカルキャッシュが不一致の場合、アップデートフラグが立脚すること', () {
      const currentClientVersion = 'v1.4.0-build105';
      const latestServerVersion = 'v1.4.1-build108';

      bool isUpdateAvailable(String current, String server) {
        return current != server;
      }

      final updateNeeded = isUpdateAvailable(
        currentClientVersion,
        latestServerVersion,
      );
      expect(updateNeeded, isTrue);
    });

    test('アセットリクエストURLにキャッシュバスターが付与され、古いService Workerキャッシュをバイパスできること', () {
      const baseUrl = 'https://kendo-os.web.app/assets/tournament_rules.json';
      const buildHash = 'hash_20261002_abc';

      String buildCacheBustedUrl(String url, String hash) {
        final uri = Uri.parse(url);
        final queryParams = Map<String, String>.from(uri.queryParameters);
        queryParams['v'] = hash;
        return uri.replace(queryParameters: queryParams).toString();
      }

      final bustedUrl = buildCacheBustedUrl(baseUrl, buildHash);
      expect(
        bustedUrl,
        equals(
          'https://kendo-os.web.app/assets/tournament_rules.json?v=hash_20261002_abc',
        ),
      );
    });
  });
}
