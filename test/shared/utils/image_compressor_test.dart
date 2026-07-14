import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:kendo_os/shared/utils/image_compressor.dart';

void main() {
  // compute等を使うためバインディング初期化
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🎨 ImageCompressor ユニットテスト要塞 (自動リサイズ・圧縮 & HEICフォールバック保証)', () {
    test(
      '【正常系】巨大な画像 (3000 x 4000) が、アスペクト比を維持したまま最大解像度2000pxに自動縮小され、バイトサイズが削減されること',
      () async {
        // 1. テスト用に巨大画像 (横3000 x 縦4000) を動的に生成
        final original = img.Image(width: 3000, height: 4000);
        // 赤い適当な四角を描く（中身がないと圧縮率が高すぎるため）
        img.fill(original, color: img.ColorRgb8(255, 0, 0));

        final originalBytes = Uint8List.fromList(
          img.encodeJpg(original, quality: 100),
        );
        expect(originalBytes.length, greaterThan(0));

        // 2. 自動圧縮を実行
        final compressedBytes = await ImageCompressor.compress(
          bytes: originalBytes,
          maxWidth: 2000,
          maxHeight: 2000,
          quality: 80,
        );

        // 3. 検証: 正常に圧縮バイトデータが取得できること
        expect(compressedBytes, isNotNull);
        expect(compressedBytes!.length, lessThan(originalBytes.length));

        // 4. 検証: デコードしてサイズが 2000px 制限以下にリサイズされていること
        final decoded = img.decodeImage(compressedBytes);
        expect(decoded, isNotNull);
        // アスペクト比 3000:4000 (= 3:4) が維持されていること
        // 高さが 2000px にリサイズされ、幅は (2000 * 3 / 4) = 1500px になるはず
        expect(decoded!.height, equals(2000));
        expect(decoded.width, equals(1500));
      },
    );

    test('【正常系】最大解像度以下の画像 (800 x 600) は、リサイズされずにクオリティ圧縮のみ適用されること', () async {
      final original = img.Image(width: 800, height: 600);
      img.fill(original, color: img.ColorRgb8(0, 0, 255));
      final originalBytes = Uint8List.fromList(
        img.encodeJpg(original, quality: 100),
      );

      final compressedBytes = await ImageCompressor.compress(
        bytes: originalBytes,
        maxWidth: 2000,
        maxHeight: 2000,
        quality: 80,
      );

      expect(compressedBytes, isNotNull);

      final decoded = img.decodeImage(compressedBytes!);
      expect(decoded, isNotNull);
      // リサイズ閾値（2000）未満のため、解像度はオリジナルのまま
      expect(decoded!.width, equals(800));
      expect(decoded.height, equals(600));
    });

    test(
      '【異常系·HEIC等フォールバック】デコードできない無効なバイト配列が渡された場合、例外をスローせず null を返すこと',
      () async {
        // 壊れた画像データ (デコード不能なダミーデータ)
        final brokenBytes = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);

        final compressedBytes = await ImageCompressor.compress(
          bytes: brokenBytes,
        );

        // null が返ることで、呼び出し元がオリジナルデータをそのまま流すフォールバックを行えること
        expect(compressedBytes, isNull);
      },
    );
  });
}
