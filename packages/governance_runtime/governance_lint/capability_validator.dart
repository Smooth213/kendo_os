// ignore_for_file: avoid_print
import 'dart:io';

// ============================================================================
// Phase 1: AI Capability Validator (Unified Runtime)
// ============================================================================
void main(List<String> args) {
  print('🛡️ [Capability Validator] Checking AI authority boundaries...');

  final changedFiles = args;
  final declaredLevel = Platform.environment['AI_CAPABILITY_LEVEL'] ?? 'L0';

  bool hasViolation = false;
  for (final file in changedFiles) {
    if (declaredLevel == 'L1' && file.contains('lib/domain/rules/')) {
      print('❌ [VIOLATION] L1 Agent attempted to modify Domain Rules: $file');
      hasViolation = true;
    }
    if (file.contains('score_event.dart')) {
      print('❌ [ROOT VIOLATION] AI is prohibited from mutating Event Schema: $file');
      hasViolation = true;
    }
  }

  if (hasViolation) exit(1);
  print('✅ [Capability Guard] AI output conforms to level $declaredLevel.');
}