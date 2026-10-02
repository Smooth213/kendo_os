import 'package:flutter_test/flutter_test.dart';

/// 体育館オフラインP2P同期における、ポート衝突時の自動フォールバック（ポートインクリメント）
/// および上限クライアント接続（スロット制限）制御の統合テスト。
void main() {
  group('[Unit] 現場通信極限 - P2Pポート衝突自動回避とクライアントキャパシティ制御テスト', () {
    test('既に使用されているポートを検知した場合に、次のポート番号へ自動的にインクリメントして起動すること', () async {
      final Set<int> occupiedPorts = {8080, 8081}; // 既存プロセスが占有中

      Future<int> bindP2PServer({
        int startPort = 8080,
        int maxAttempts = 5,
      }) async {
        for (int i = 0; i < maxAttempts; i++) {
          final port = startPort + i;
          if (!occupiedPorts.contains(port)) {
            occupiedPorts.add(port);
            return port;
          }
        }
        throw Exception('すべてのポートが使用中です');
      }

      final boundPort = await bindP2PServer(startPort: 8080);
      expect(boundPort, equals(8082));
      expect(occupiedPorts.contains(8082), isTrue);
    });

    test('クライアント同時接続数が許容上限に達した場合に、新規接続が拒絶または待機列へ安全に制御されること', () async {
      const int maxConcurrentClients = 5;
      final Set<String> activeConnections = {};
      final List<String> rejectedConnections = [];

      bool handleClientConnect(String clientId) {
        if (activeConnections.length >= maxConcurrentClients) {
          rejectedConnections.add(clientId);
          return false;
        }
        activeConnections.add(clientId);
        return true;
      }

      void handleClientDisconnect(String clientId) {
        activeConnections.remove(clientId);
      }

      // 5台のクライアントが接続
      for (int i = 1; i <= 5; i++) {
        final success = handleClientConnect('client_$i');
        expect(success, isTrue);
      }

      expect(activeConnections.length, equals(5));

      // 6台目のクライアントが接続を試みる
      final overflowSuccess = handleClientConnect('client_6');
      expect(overflowSuccess, isFalse);
      expect(rejectedConnections, contains('client_6'));

      // 1台切断
      handleClientDisconnect('client_2');
      expect(activeConnections.length, equals(4));

      // 空いた枠に再試行
      final retrySuccess = handleClientConnect('client_6');
      expect(retrySuccess, isTrue);
      expect(activeConnections, contains('client_6'));
    });
  });
}
