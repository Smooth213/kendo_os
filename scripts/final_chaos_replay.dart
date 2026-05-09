// ignore_for_file: avoid_print
import 'dart:io';

// ============================================================================
// Phase 10: Final Chaos Replay & Constitution Verification
// 凍結直前の最終検証。全リプレイ、全カオス、全ガバナンスチェックを実行し、
// Driftがゼロであることを最終証明します。
// ============================================================================
void main() async {
  print('🏁 [Final Phase] Starting Final Governance Verification Drill...');

  final tests = [
    'dart run tools/governance_lint/lint.dart',
    'dart run tools/governance_lint/semantic_drift_detector.dart',
    'dart run tools/governance_lint/package_verifier.dart',
    'flutter test test/chaos/drift_attack_test.dart',
    'flutter test test/integration/phase0_event_replay_snapshot_test.dart'
  ];

  bool allPassed = true;
  for (final test in tests) {
    print('🚀 Executing: $test');
    final parts = test.split(' ');
    final result = await Process.run(parts[0], parts.sublist(1));
    
    if (result.exitCode != 0) {
      print('❌ FAILED: $test');
      print(result.stderr);
      allPassed = false;
    } else {
      print('✅ PASSED');
    }
  }

  if (allPassed) {
    print('\n🏆 [GOVERNANCE FREEZE SUCCESS] kendo_os Governance Runtime v1.0 is now officially STABLE.');
    exit(0);
  } else {
    print('\n🚨 [FREEZE REJECTED] Governance integrity compromised!');
    exit(1);
  }
}