// ignore_for_file: avoid_print
import 'dart:io';

void main() {
  final libDir = Directory('lib');
  final testDir = Directory('test');
  bool hasError = false;

  // 禁止された古いアーキテクチャパスの定義
  final forbiddenPatterns = {
    'package:kendo_os/core/':
        'core/ ディレクトリは廃止されました。shared/ または security/ を使用してください。',
    'package:kendo_os/presentation/shared/widgets/':
        'widgets は shared/widgets/ へ移行されました。',
  };

  void checkFile(File file) {
    final lines = file.readAsLinesSync();
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      for (final pattern in forbiddenPatterns.keys) {
        if (line.contains(pattern)) {
          print(
            '❌ アーキテクチャ違反 [${file.path}:${i + 1}]: ${forbiddenPatterns[pattern]}',
          );
          print('   > $line');
          hasError = true;
        }
      }
    }
  }

  void scan(Directory dir) {
    if (!dir.existsSync()) return;
    for (final entity in dir.listSync(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        checkFile(entity);
      }
    }
  }

  print('🔍 アーキテクチャ・ガバナンス境界の検証を開始します...');
  scan(libDir);
  scan(testDir);

  if (hasError) {
    print('🚨 アーキテクチャ整合性チェックに失敗しました。上記の違反を修正してください。');
    exit(1);
  } else {
    print('✅ すべてのアーキテクチャ境界が強固に守られています！');
    exit(0);
  }
}
