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
      '1. iOS PWA 全画面最適化（black-translucent & viewport-fit=cover）が設定されていること',
      () {
        expect(
          indexHtmlContent.contains(
            'name="apple-mobile-web-app-status-bar-style" content="black-translucent"',
          ),
          isTrue,
          reason: 'iOS PWAの全画面表示のためにblack-translucentが必須',
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
      },
    );

    test('2. WebKit 起動直後タッチ座標56pxズレ防止 TouchSync ステルス補正システムが確実に実装されていること', () {
      // 🛡️ TouchSync の核心ロジックが確実に index.html に存在することを物理防衛
      expect(
        indexHtmlContent.contains('getStatusBarHeight()'),
        isTrue,
        reason: 'ステータスバーインセット（safe-area-inset-top）の動的計測ロジックが必須',
      );
      expect(
        indexHtmlContent.contains('env(safe-area-inset-top'),
        isTrue,
        reason: 'CSS safe-area-inset-top による正確なインセット検出が必須',
      );
      expect(
        indexHtmlContent.contains('markSynced()'),
        isTrue,
        reason: 'スワイプ検知による補正自動解除（正規化）機構が必須',
      );
      expect(
        indexHtmlContent.contains('nativeClientY'),
        isTrue,
        reason: 'MouseEventプロトタイプgetterによる多重減算防止機構が必須',
      );
      expect(
        indexHtmlContent.contains('restoreViewportFit()'),
        isTrue,
        reason: 'Flutterによるviewport-fit剥奪を阻止するMutationObserverが必須',
      );
    });

    test('3. UIデザインを汚すデバッグ用HUDが画面上に描画されていないこと（完全ステルス保証）', () {
      expect(
        indexHtmlContent.contains('kendo-touch-hud'),
        isFalse,
        reason: '本番環境のUIにデバッグHUD要素が残留してはならない',
      );
    });
  });
}
