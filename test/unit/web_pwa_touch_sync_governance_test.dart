import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('🛡️ iOS PWA ステータスバー独立＆WebKitタッチ座標同期ガバナンステスト (web/index.html)', () {
    late String indexHtmlContent;

    setUpAll(() {
      final file = File('web/index.html');
      expect(file.existsSync(), isTrue, reason: 'web/index.html が存在する必要があります');
      indexHtmlContent = file.readAsStringSync();
    });

    test('1. iOS PWA ステータスバー独立モード（black）が設定され、起動時タッチズレが物理根絶されていること', () {
      // 🛡️ black-translucent ではなく black を指定してステータスバーを独立管理し、起動時ズレを物理根絶
      expect(
        indexHtmlContent.contains(
          'name="apple-mobile-web-app-status-bar-style" content="black"',
        ),
        isTrue,
        reason:
            'ステータスバーを黒帯独立モード（black）にしてWebKitの起動時47px/54pxスクロールフリーズバグを物理根絶するために必須',
      );
      expect(
        indexHtmlContent.contains('viewport-fit=cover'),
        isTrue,
        reason: 'セーフエリア全体へ描画を展開するために必須',
      );
      expect(
        indexHtmlContent.contains('mobile-web-app-capable'),
        isTrue,
        reason: 'PWAスタンドアロン起動タグが必須',
      );
    });

    test('2. 起動時タッチズレの原因となる black-translucent 設定が排除されていること', () {
      expect(
        indexHtmlContent.contains('content="black-translucent"'),
        isFalse,
        reason: 'black-translucentは起動時スクロールオフセットフリーズを引き起こすため禁止',
      );
    });
  });
}
