// ignore_for_file: avoid_print
import 'dart:io';

// ============================================================================
// Phase 3: Constitution Freeze Validator
// ============================================================================
void main(List<String> args) {
  print('❄️ [Freeze Validator] Checking for unauthorized governance changes...');

  final changedFiles = args;
  final protectedPaths = [
    'docs/governance/governance_constitution.md',
    'docs/governance/architecture_invariants.md',
    'governance/runtime_version.yaml',
    'governance/baseline_hashes.json'
  ];

  bool hasConstitutionChange = false;
  for (final file in changedFiles) {
    if (protectedPaths.any((p) => file == p)) {
      print('⚠️ [ALERT] Constitution/Invariant change detected: $file');
      hasConstitutionChange = true;
    }
  }

  if (hasConstitutionChange) {
    // 人間による明示的な承認トークンをチェック
    final humanToken = Platform.environment['GOVERNANCE_HUMAN_TOKEN'];
    
    if (humanToken == null || humanToken.isEmpty) {
      print('❌ [BLOCK] AI is prohibited from modifying Frozen Governance files.');
      print('👉 To modify these, a Human must provide GOVERNANCE_HUMAN_TOKEN.');
      exit(1);
    }
    
    print('✅ [PASS] Governance change authorized by Human Authority.');
  } else {
    print('✅ [PASS] No changes to frozen governance files.');
  }
}