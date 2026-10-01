import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kendo_os/shared/platform/platform_boundary.dart';

void main() {
  group('[Governance] プラットフォーム境界Webネイティブ完全分離実行保証規約', () {
    test('safePlatformCallにおいてWeb環境とIO環境が相互干渉なく安全に分離実行されること', () {
      int ioRunCount = 0;
      int webRunCount = 0;

      PlatformBoundary.safePlatformCall(
        () {
          ioRunCount++;
        },
        () {
          webRunCount++;
        },
      );

      if (kIsWeb) {
        expect(webRunCount, equals(1));
        expect(ioRunCount, equals(0));
      } else {
        expect(ioRunCount, equals(1));
        expect(webRunCount, equals(0));
      }
    });

    test('静的解析においてPlatformBoundaryが純粋な条件分岐ロジックを保持していること', () {
      final boundaryFile = File('lib/shared/platform/platform_boundary.dart');
      expect(boundaryFile.existsSync(), isTrue);

      final content = boundaryFile.readAsStringSync();
      expect(content.contains('class PlatformBoundary'), isTrue);
      expect(content.contains('safePlatformCall'), isTrue);
      expect(content.contains('kIsWeb'), isTrue);
    });
  });
}
