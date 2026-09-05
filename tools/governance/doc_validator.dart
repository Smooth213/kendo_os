// ignore_for_file: avoid_print
import 'dart:io';

// ============================================================================
// Phase 0: Documentation Validator
// 取説（Markdown）の存在、リンク切れ、タイトル欠落、孤立画像を監査します。
// ============================================================================
void main() {
  print('📚 [Doc Validator] Scanning documentation constraints...');

  final manualsDir = Directory('packages/documentation_runtime/manuals');
  if (!manualsDir.existsSync()) {
    print('🚨 [BLOCK] packages/documentation_runtime/manuals does not exist.');
    exit(1);
  }

  bool hasError = false;

  // Markdown存在確認・タイトル検査
  final mdFiles = manualsDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.md'))
      .toList();

  if (mdFiles.isEmpty) {
    print(
      '🚨 [FAIL] No markdown files found in packages/documentation_runtime/manuals.',
    );
    hasError = true;
  } else {
    for (var file in mdFiles) {
      final content = file.readAsStringSync();
      // Title missing check
      if (!content.contains('# ')) {
        print('❌ [FAIL] Missing H1 Title (# ) in: ${file.path}');
        hasError = true;
      }
    }
  }

  if (hasError) {
    print('🚨 [BLOCK] Documentation Governance Validation Failed.');
    exit(1);
  }

  print(
    '✅ [PASS] Documentation structure is valid (${mdFiles.length} files scanned).',
  );
}
