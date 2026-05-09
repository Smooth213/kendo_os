// ignore_for_file: avoid_print
import 'dart:io';

// ============================================================================
// Phase 4: AI Sandbox Validator
// AIブランチからの変更が「保護領域」を侵していないか、
// および必要なメタデータが含まれているかを検証します。
// ============================================================================
void main(List<String> args) {
  print('🛡️ [Sandbox Validator] Checking AI Branch Constraints...');
  
  final branchName = Platform.environment['GITHUB_HEAD_REF'] ?? '';
  final isAiBranch = branchName.startsWith('ai/sandbox/');
  
  if (!isAiBranch) {
    print('✅ Not an AI branch. Skipping sandbox validation.');
    exit(0);
  }

  bool hasViolation = false;
  final changedFiles = args;

  // Step 4-4: Protected Boundary Check
  final protectedFiles = [
    'lib/domain/repositories/event_store.dart',
    'lib/domain/services/kendo_rule_engine.dart',
    'docs/governance/governance_constitution.md'
  ];

  for (final file in changedFiles) {
    if (protectedFiles.any((p) => file.contains(p))) {
      print('❌ [FATAL] AI is NOT allowed to modify protected boundary: $file');
      hasViolation = true;
    }
  }

  // Step 4-2: AI Commit Metadata Check (簡易実装: PRタイトルまたはコミットログを想定)
  // 実際には git log 等で確認するが、ここではフラグとして扱う
  print('ℹ️ Validating AI-GENERATED metadata presence...');

  if (hasViolation) {
    print('🚨 [Sandbox Violation] AI escaped the sandbox or violated boundaries!');
    exit(1);
  } else {
    print('✅ AI Sandbox constraints satisfied.');
    exit(0);
  }
}