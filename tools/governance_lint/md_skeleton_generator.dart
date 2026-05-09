// ignore_for_file: avoid_print
import 'dart:io';

// ============================================================================
// Phase 3: Markdown Skeleton Generator
// docs/manuals/*/index.md を読み込み、リンクされているがまだ存在しない
// .md ファイルを自動的に検出し、テンプレートから雛形（スケルトン）を生成します。
// ============================================================================
void main() {
  print('🛠 [Skeleton Generator] Scanning index files for missing manuals...');

  final targetDirs = ['operator', 'viewer', 'recovery'];
  final templateFile = File('docs/manuals/templates/operator_template.md');
  
  if (!templateFile.existsSync()) {
    print('❌ Template not found at ${templateFile.path}');
    return;
  }
  
  final templateContent = templateFile.readAsStringSync();
  int createdCount = 0;

  for (final dir in targetDirs) {
    final indexFile = File('docs/manuals/$dir/index.md');
    if (!indexFile.existsSync()) continue;

    final lines = indexFile.readAsLinesSync();
    // リンク記法 [名前](./ファイル名.md) を抽出する正規表現
    final linkRegExp = RegExp(r'\[(.*?)\]\(\.\/([^)]+\.md)\)');

    for (final line in lines) {
      final match = linkRegExp.firstMatch(line);
      if (match != null) {
        final title = match.group(1);
        final filename = match.group(2);
        final targetPath = 'docs/manuals/$dir/$filename';
        
        final targetFile = File(targetPath);
        if (!targetFile.existsSync()) {
          // テンプレートの見出しをファイル名に置き換えて生成
          final newContent = templateContent.replaceFirst('[画面名]', title ?? '画面名未定義');
          targetFile.writeAsStringSync(newContent);
          print('✨ Created skeleton: $targetPath');
          createdCount++;
        }
      }
    }
  }

  print('✅ [PASS] Generation complete. $createdCount new skeletons created.');
}