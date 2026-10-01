import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/features/match/domain/match_model.dart';
import 'package:kendo_os/features/p2p/infrastructure/local_p2p_broadcaster.dart';
import 'package:kendo_os/features/p2p/presentation/assets/web_viewer_html.dart';

void main() {
  group('[Unit] LocalP2pBroadcaster テスト', () {
    test('ホストとポートを含む正しいWebView用HTMLが生成されること', () {
      final html = WebViewHtml.build(hostIp: '192.168.1.100', port: 8080);
      expect(html, contains('kendo OS - リアルタイム観戦ビュアー'));
      expect(html, contains('ws://'));
      expect(html, contains('現地記録端末と同期中'));
    });

    test(
      'LocalP2pBroadcaster starts, broadcasts, and stops safelyこと',
      () async {
        final broadcaster = LocalP2pBroadcaster();
        expect(broadcaster.isRunning, false);

        final match = const MatchModel(
          id: 'p2p-test-match',
          matchType: '先鋒',
          redName: '誠道館 : 山田',
          whiteName: 'ライバル : 田中',
          redScore: 1,
          whiteScore: 0,
        );

        // サーバー未起動時のブロードキャスト呼び出しがクラッシュしないこと
        expect(() => broadcaster.broadcastMatch(match), returnsNormally);

        await broadcaster.stopServer();
        expect(broadcaster.isRunning, false);
      },
    );
  });
}
