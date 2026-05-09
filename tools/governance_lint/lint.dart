// ignore_for_file: avoid_print
import 'dart:io';

// ============================================================================
// Phase 1: Governance Linter
// Governance Policy as Code (YAML) に基づき、AIや開発者が
// 禁止されたAPIや状態を持っていないかを機械的に検証します。
// ============================================================================
void main() {
  print('🛡️ [Governance Linter] Starting AI Output Audit...');
  bool hasViolation = false;

  final ruleDir = Directory('lib/domain/rules');
  if (!ruleDir.existsSync()) {
    print('✅ Rule directory not found. Skipping rule lint.');
    exit(0);
  }

  final files = ruleDir.listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('_test.dart'));

  for (final file in files) {
    final lines = file.readAsLinesSync();
    bool hasRuleVersion = false;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // 1. Forbidden API Check
      if (line.contains('DateTime.now()') || line.contains('Random()') || line.contains('sleep(')) {
        print('❌ [FATAL] Forbidden API used in ${file.path}:${i + 1} -> $line');
        hasViolation = true;
      }

      // 2. Mutable State Check
      if (line.contains('static ') && !line.contains('const') && !line.contains('final')) {
        print('❌ [FATAL] Mutable global state detected in ${file.path}:${i + 1} -> $line');
        hasViolation = true;
      }

      // 3. IO Check
      if (line.contains('dart:io') || line.contains('package:http')) {
        print('❌ [FATAL] IO usage is prohibited in domain rules: ${file.path}:${i + 1}');
        hasViolation = true;
      }

      // 4. RuleVersion Check (簡易)
      if (line.contains('ruleVersion') || line.contains('version')) {
        hasRuleVersion = true;
      }
    }

    // クラス定義がありそうなファイルに対するバージョン定義チェック
    if (!hasRuleVersion && file.readAsStringSync().contains('class ') && !file.path.contains('factory')) {
      print('⚠️ [WARNING] RuleVersion might be missing in ${file.path}');
    }
  }

  if (hasViolation) {
    print('🚨 [Governance Linter] Violation detected! Blocking the merge/commit.');
    exit(1);
  } else {
    print('✅ [Governance Linter] All AI outputs conform to the Governance Policies.');
    exit(0);
  }
}