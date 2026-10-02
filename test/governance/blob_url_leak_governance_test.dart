import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('[Governance] ブラウザBlobリソース即時解放およびメモリリークゼロ規約テスト', () {
    test('createObjectURLを呼び出した全ファイルで必ずrevokeObjectURLによるリソース破棄が行われていること', () {
      final libDir = Directory('lib');
      expect(libDir.existsSync(), isTrue);

      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      int createObjectUrlOccurrences = 0;

      for (final file in dartFiles) {
        final content = file.readAsStringSync();

        if (content.contains('createObjectURL')) {
          createObjectUrlOccurrences++;

          // createObjectURL を含むファイルには、必ず対応する revokeObjectURL が存在すること
          final hasRevoke = content.contains('revokeObjectURL');
          expect(
            hasRevoke,
            isTrue,
            reason:
                '${file.path} で createObjectURL が呼ばれていますが、revokeObjectURL による解放処理が存在しません',
          );
        }
      }

      // 少なくとも1箇所（file_download_helper_web.dart）で正常に検出・保護されていることを確認
      expect(createObjectUrlOccurrences, greaterThanOrEqualTo(1));
    });
  });
}
