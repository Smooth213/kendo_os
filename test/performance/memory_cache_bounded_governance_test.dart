import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:kendo_os/bootstrap/app_startup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('💾 [Phase 2 Performance Governance] 画像キャッシュ上限・メモリ制御テスト', () {
    test('デフォルト設定で画像キャッシュ上限が50MBかつ100枚に制限されること', () {
      // 実行
      AppStartup.configureImageCache();

      final imageCache = PaintingBinding.instance.imageCache;

      // 50MB (52,428,800 bytes)
      expect(imageCache.maximumSizeBytes, 50 * 1024 * 1024);
      // 100枚
      expect(imageCache.maximumSize, 100);
    });

    test('カスタム値での画像キャッシュ制限設定が正確に反映されること', () {
      // 実行
      AppStartup.configureImageCache(
        maxSizeBytes: 20 * 1024 * 1024,
        maxSize: 50,
      );

      final imageCache = PaintingBinding.instance.imageCache;

      // 20MB (20,971,520 bytes)
      expect(imageCache.maximumSizeBytes, 20 * 1024 * 1024);
      // 50枚
      expect(imageCache.maximumSize, 50);

      // テスト後にデフォルト値（50MB/100枚）に戻しておく
      AppStartup.configureImageCache();
      expect(imageCache.maximumSizeBytes, 50 * 1024 * 1024);
      expect(imageCache.maximumSize, 100);
    });
  });
}
