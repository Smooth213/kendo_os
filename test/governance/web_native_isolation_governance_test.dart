import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('🌐 【ガバナンス第5条】Web境界・ネイティブ直接import遮断 監査テスト', () {
    final isolatedDirs = ['lib/features/match', 'lib/features/viewer'];

    test(
      '1. features/match および features/viewer 配下に dart:io / dart:ffi の直接importがないこと',
      () {
        final forbiddenPattern = RegExp(
          r'import\s+[\x27\x22](dart:io|dart:ffi)[\x27\x22]',
        );
        final violations = <String>[];

        for (final dirPath in isolatedDirs) {
          final dir = Directory(dirPath);
          if (!dir.existsSync()) continue;

          final dartFiles = dir
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'));

          for (final file in dartFiles) {
            final content = file.readAsStringSync();
            if (forbiddenPattern.hasMatch(content)) {
              violations.add(file.path);
            }
          }
        }

        expect(violations, isEmpty, reason: 'Web境界違反ファイル: $violations');
      },
    );
  });
}
