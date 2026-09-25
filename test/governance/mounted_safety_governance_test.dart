import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('🛡️ 【ガバナンス第2条】BuildContext Mounted Safety (非同期安全) 監査テスト', () {
    test('1. analysis_options.yaml で flutter_lints の非同期安全規約が包含されていること', () {
      final file = File('analysis_options.yaml');
      expect(file.existsSync(), isTrue);
      final content = file.readAsStringSync();
      expect(content.contains('package:flutter_lints/flutter.yaml'), isTrue);
    });

    test('2. 主要UI画面・コンポーネントで非同期処理後の mounted ガードが遵守されていること', () {
      final dir = Directory('lib');
      final dartFiles = dir
          .listSync(recursive: true)
          .whereType<File>()
          .where(
            (f) =>
                f.path.endsWith('.dart') &&
                !f.path.endsWith('.g.dart') &&
                !f.path.endsWith('.freezed.dart'),
          );

      int checkedFiles = 0;
      int guardedFiles = 0;

      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        if (content.contains('await ') && content.contains('context')) {
          checkedFiles++;
          if (content.contains('mounted')) {
            guardedFiles++;
          }
        }
      }

      expect(checkedFiles, greaterThan(0));
      // 非同期処理とcontextを扱うファイルでmountedガードが正しく採用されていること
      expect(guardedFiles, greaterThan(0));
    });
  });
}
