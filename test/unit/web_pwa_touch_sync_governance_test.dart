import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('🛡️ iOS PWA WebKit タッチ座標同期（ステルスTouchSync）ガバナンステスト (web/index.html)', () {
    late String indexHtmlContent;

    setUpAll(() {
      final file = File('web/index.html');
      expect(file.existsSync(), isTrue, reason: 'web/index.html が存在する必要があります');
      indexHtmlContent = file.readAsStringSync();
    });

    test(
      '1. iOS PWA エッジ・トゥ・エッジ全画面モード（black-translucent & viewport-fit=cover）が設定されていること',
      () {
        expect(
          indexHtmlContent.contains(
            'name="apple-mobile-web-app-status-bar-style" content="black-translucent"',
          ),
          isTrue,
          reason: '下部黒バーを撤廃しエッジ・トゥ・エッジ全画面表示を展開するためにblack-translucentが必須',
        );
        expect(
          indexHtmlContent.contains('viewport-fit=cover'),
          isTrue,
          reason: 'セーフエリア全体へ描画を展開するために必須',
        );
        expect(
          indexHtmlContent.contains('apple-mobile-web-app-capable'),
          isTrue,
          reason: 'iOS PWAスタンドアロン起動タグ (apple-mobile-web-app-capable) が必須',
        );
        expect(
          indexHtmlContent.contains('name="theme-color"'),
          isTrue,
          reason: '画面下部およびシステム領域の黒バーを防止するためのtheme-color定義が必須',
        );
      },
    );

    test(
      '2. WebKit 起動直後タッチ座標ズレ防止 TouchSync v4.0 Perfect Snap 物理スナップシステムが確実に実装されていること',
      () {
        // 🛡️ TouchSync v4.0 の物理座標スナップロジックが確実に index.html に存在することを物理防衛
        expect(
          indexHtmlContent.contains('v4.0 Perfect Snap'),
          isTrue,
          reason: 'TouchSync v4.0 Perfect Snap システムの宣言が必須',
        );
        expect(
          indexHtmlContent.contains('getBoundingClientRect'),
          isTrue,
          reason: '要素の物理境界（rect.left / rect.top）計測による正確な要素内座標算出が必須',
        );
        expect(
          indexHtmlContent.contains('expectedX') &&
              indexHtmlContent.contains('expectedY'),
          isTrue,
          reason: 'clientX/Y に基づく真の物理要素内座標算出ロジックが必須',
        );
        expect(
          indexHtmlContent.contains("Object.defineProperty(e, 'offsetX'") &&
              indexHtmlContent.contains("Object.defineProperty(e, 'offsetY'"),
          isTrue,
          reason: 'WebKit の誤加算バグを上書きする offsetX / offsetY プロパティ定義が必須',
        );
        expect(
          indexHtmlContent.contains('restoreViewportFit()'),
          isTrue,
          reason: 'Flutterによるviewport-fit剥奪を阻止するMutationObserverが必須',
        );
      },
    );

    test('3. UIデザインを汚すデバッグ用HUDが画面上に描画されていないこと（完全ステルス保証）', () {
      expect(
        indexHtmlContent.contains('kendo-touch-hud'),
        isFalse,
        reason: '本番環境のUIにデバッグHUD要素が残留してはならない',
      );
    });

    test(
      '4. 【動的振る舞い検証】Node.js環境でWebKit誤加算(+54px)バグを注入し、物理スナップが100%機能することを検証',
      () {
        final result = Process.runSync('node', [
          'test/unit/test_ios_pwa_touch_sync_simulation.js',
        ]);
        expect(
          result.exitCode,
          equals(0),
          reason:
              'TouchSync v4.0 動的シミュレーションテストが失敗しました:\n${result.stdout}\n${result.stderr}',
        );
        expect(
          result.stdout.toString().contains('全項目完全合格'),
          isTrue,
          reason: 'シミュレーションテストの全項目完了メッセージが確認できること',
        );
      },
    );
  });
}
