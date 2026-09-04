import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/infrastructure/services/web_platform_optimizer.dart';

void main() {
  group('🌐 [Phase 7 Performance Governance] Safari & Chrome Web極限最適化テスト', () {
    test('1. WebPlatformOptimizer が安全に実行できること', () {
      expect(() => WebPlatformOptimizer.applyOptimizations(), returnsNormally);
      // 非Webテスト環境では false
      expect(WebPlatformOptimizer.isWebSafari, isFalse);
      expect(WebPlatformOptimizer.isWebChrome, isFalse);
    });

    test('2. web/index.html に Safari & Chrome 2大ブラウザ最適化定義が完全網羅されていること', () {
      final indexHtmlFile = File('web/index.html');
      expect(indexHtmlFile.existsSync(), isTrue);

      final htmlContent = indexHtmlFile.readAsStringSync();

      // ① Viewport最重要設定（ノッチ対応・ダブルタップズーム無効化）
      expect(
        htmlContent.contains('viewport-fit=cover'),
        isTrue,
        reason: 'iPhone Safariのノッチ領域全画面描画設定が必要です',
      );
      expect(
        htmlContent.contains('user-scalable=no'),
        isTrue,
        reason: '試合中の高速連打による画面誤拡大を防ぐ必要があります',
      );

      // ② Safari / Chrome 共通スタイル最適化（100dvh, オーバースクロール防止, タッチアクション）
      expect(
        htmlContent.contains('100dvh'),
        isTrue,
        reason: 'Mobile Safariのアドレスバー伸縮によるガタつきを防ぐdvh指定が必要です',
      );
      expect(
        htmlContent.contains('overscroll-behavior-y: none'),
        isTrue,
        reason: 'Safariのオーバースクロールバウンスを防止する必要があります',
      );
      expect(
        htmlContent.contains('touch-action: manipulation'),
        isTrue,
        reason: 'タップ遅延および誤ズームを排除するtouch-actionが必要です',
      );

      // ③ Safari 7日間消滅対策（IndexedDB永続化）
      expect(
        htmlContent.contains('navigator.storage.persist'),
        isTrue,
        reason: 'SafariのIndexedDB 7日間破棄を防ぐStorageManager APIが必要です',
      );

      // ④ Chrome / Safari BFCache（戻る・進むキャッシュ）高速復帰
      expect(
        htmlContent.contains('pageshow'),
        isTrue,
        reason: 'BFCacheからのページ復帰を検知するpageshowハンドラーが必要です',
      );
    });

    test('3. web/manifest.json が PWA として正しく設定されていること', () {
      final manifestFile = File('web/manifest.json');
      expect(manifestFile.existsSync(), isTrue);

      final manifestContent = manifestFile.readAsStringSync();
      expect(manifestContent.contains('"name": "Kendo OS"'), isTrue);
      expect(manifestContent.contains('"display": "standalone"'), isTrue);
    });
  });
}
