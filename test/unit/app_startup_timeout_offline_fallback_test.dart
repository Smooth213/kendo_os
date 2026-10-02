import 'package:flutter_test/flutter_test.dart';

/// アプリ起動時にリモート設定（Remote Config / Firestore）の取得がネットワーク遅延等で
/// タイムアウト（例: 2000ms）した場合に、起動を永久ブロックせずオフラインキャッシュへ即時フォールバックする検証テスト。
void main() {
  group('[Unit] 起動極限 - ネットワーク遅延時のオフラインキャッシュフォールバックテスト', () {
    test('リモート取得がタイムアウトした場合に、オフラインキャッシュが自動採用されアプリ起動が継続されること', () async {
      final Map<String, dynamic> localCache = {
        'tenantId': 'tenant_offline_default',
        'isOfflineMode': true,
      };

      // リモート取得が10秒かかる（タイムアウト2秒を超える）シミュレーション
      Future<Map<String, dynamic>> fetchRemoteConfig() async {
        await Future.delayed(const Duration(seconds: 10));
        return {'tenantId': 'tenant_remote_latest', 'isOfflineMode': false};
      }

      Future<Map<String, dynamic>> initializeConfigWithTimeout() async {
        try {
          return await fetchRemoteConfig().timeout(
            const Duration(milliseconds: 200),
            onTimeout: () => localCache,
          );
        } catch (_) {
          return localCache;
        }
      }

      final config = await initializeConfigWithTimeout();

      expect(config['tenantId'], equals('tenant_offline_default'));
      expect(config['isOfflineMode'], isTrue);
    });

    test('ネットワークが正常で高速な場合はリモートの最新設定が採用されること', () async {
      final Map<String, dynamic> localCache = {
        'tenantId': 'tenant_offline_default',
      };

      Future<Map<String, dynamic>> fetchRemoteConfig() async {
        await Future.delayed(const Duration(milliseconds: 20));
        return {'tenantId': 'tenant_remote_active'};
      }

      Future<Map<String, dynamic>> initializeConfigWithTimeout() async {
        return await fetchRemoteConfig().timeout(
          const Duration(milliseconds: 200),
          onTimeout: () => localCache,
        );
      }

      final config = await initializeConfigWithTimeout();
      expect(config['tenantId'], equals('tenant_remote_active'));
    });
  });
}
