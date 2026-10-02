import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('[Governance] Webネイティブプラグイン完全隔離およびバウンダリ漏洩ゼロ規約テスト', () {
    test('Web非対応プラグインの呼び出し箇所でkIsWebガードまたはプラットフォーム分離が施されていること', () {
      final libDir = Directory('lib');
      expect(libDir.existsSync(), isTrue);

      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      // プラットフォーム固有の条件分岐ファイル（条件付きエクスポート等）は除外
      final platformSpecificFiles = {
        'lib/shared/platform/platform_file_io.dart',
      };

      for (final file in dartFiles) {
        final normalizedPath = file.path.replaceAll('\\', '/');
        if (platformSpecificFiles.contains(normalizedPath)) {
          continue;
        }

        final content = file.readAsStringSync();

        // 1. path_provider (getApplicationDocumentsDirectory)
        if (content.contains('getApplicationDocumentsDirectory(')) {
          final isProtected =
              content.contains('kIsWeb') || content.contains('!kIsWeb');
          expect(
            isProtected,
            isTrue,
            reason:
                '$normalizedPath で getApplicationDocumentsDirectory が kIsWeb 保護なしに呼び出されています',
          );
        }

        // 2. Isar.open 直接呼び出し
        if (content.contains('Isar.open(')) {
          final isProtected =
              content.contains('kIsWeb') || content.contains('!kIsWeb');
          expect(
            isProtected,
            isTrue,
            reason: '$normalizedPath で Isar.open が kIsWeb 保護なしに呼び出されています',
          );
        }

        // 3. Printing.layoutPdf 直接呼び出し
        if (content.contains('Printing.layoutPdf(') ||
            content.contains('Printing.sharePdf(')) {
          final isProtected =
              content.contains('kIsWeb') || content.contains('!kIsWeb');
          expect(
            isProtected,
            isTrue,
            reason: '$normalizedPath で Printing API が kIsWeb 保護なしに呼び出されています',
          );
        }
      }
    });
  });
}
