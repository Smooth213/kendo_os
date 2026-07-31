import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group(
    '🛡️ Code Quality & Regression Tests: Hardcoded Specific Names Protection',
    () {
      test('lib/ 配下のすべてのDartファイルに特定固有名詞(道上・道上剣友会)が直接ハードコードされていないこと', () {
        final libDir = Directory('lib');
        expect(libDir.existsSync(), isTrue, reason: 'lib ディレクトリが存在する必要があります');

        // 検出対象の禁止固有名詞リスト
        final forbiddenKeywords = ['道上剣友会', '道上'];

        final violations = <String>[];

        // lib/ 配下の全 .dart ファイルを再帰的に取得
        final files = libDir
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'));

        for (final file in files) {
          final lines = file.readAsLinesSync();
          for (int i = 0; i < lines.length; i++) {
            final line = lines[i];
            for (final keyword in forbiddenKeywords) {
              if (line.contains(keyword)) {
                violations.add(
                  '${file.path}:${i + 1} -> 禁止キーワード "$keyword" を検出: "${line.trim()}"',
                );
              }
            }
          }
        }

        expect(
          violations,
          isEmpty,
          reason:
              'プロダクトコード(lib/)内に特定の固有名詞が含まれています。\n汎用的な名称(〇〇剣友会, 山田 など)を使用してください:\n${violations.join('\n')}',
        );
      });
    },
  );
}
