import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/platform/platform_boundary.dart';

void main() {
  group('[Unit] Webおよびネイティブ安全実行ゲートウェイ単体テスト', () {
    test('safePlatformCallにおいて現在のプラットフォームに応じた処理のみが分岐実行されること', () {
      bool ioExecuted = false;
      bool webExecuted = false;

      PlatformBoundary.safePlatformCall(
        () {
          ioExecuted = true;
        },
        () {
          webExecuted = true;
        },
      );

      if (kIsWeb) {
        expect(webExecuted, isTrue);
        expect(ioExecuted, isFalse);
      } else {
        expect(ioExecuted, isTrue);
        expect(webExecuted, isFalse);
      }

      expect(PlatformBoundary.isWeb, equals(kIsWeb));
    });
  });
}
