// ignore_for_file: avoid_print
import 'dart:io';

// ============================================================================
// Phase 0: Documentation Validator
// 取説（Markdown）の存在、リンク切れ、タイトル欠落、孤立画像を監査します。
// ============================================================================
void main() {
  print('📚 [Doc Validator] Scanning documentation constraints...');
  
  final manualsDir = Directory('docs/manuals');
  if (!manualsDir.existsSync()) {
    print('✅ [PASS] docs/manuals does not exist yet. Skipping deep scan.');
    return;
  }

  bool hasError = false;
  
  // 簡易チェック実装 (md存在確認など)
  final mdFiles = manualsDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.md'));
  
  if (mdFiles.isEmpty) {
    print('⚠️ [WARN] No markdown files found in docs/manuals.');
  } else {
    for (var file in mdFiles) {
      final content = file.readAsStringSync();
      // Title missing check
      if (!content.contains('# ')) {
        print('❌ [FAIL] Missing H1 Title (# ) in: ${file.path}');
        hasError = true;
      }
      // TODO: Implement broken link and orphan image detection via RegExp or external markdown-link-check tool.
    }
  }

  if (hasError) {
    print('🚨 [BLOCK] Documentation Governance Validation Failed.');
    exit(1);
  }

  print('✅ [PASS] Documentation structure is valid.');
}