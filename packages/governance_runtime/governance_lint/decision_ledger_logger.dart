// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:convert';

// ============================================================================
// Phase 5: Governance Decision Ledger Logger
// AIの各作業におけるメタデータを記録し、永久監査を可能にします。
// ============================================================================
void main(List<String> args) {
  print('📝 [Decision Ledger] Recording AI decision metadata...');

  final ledgerFile = File('governance/ledger/decision_ledger.jsonl');
  if (!ledgerFile.parent.existsSync()) {
    ledgerFile.parent.createSync(recursive: true);
  }

  // AIの出力メタデータを環境変数または引数から取得
  final decision = {
    'decision_id': DateTime.now().millisecondsSinceEpoch.toString(),
    'timestamp': DateTime.now().toUtc().toIso8601String(),
    'task_type': Platform.environment['AI_TASK_TYPE'] ?? 'ROUTINE_UPDATE',
    'capability_level': Platform.environment['AI_CAPABILITY_LEVEL'] ?? 'L1',
    'risk_level': Platform.environment['GOV_RISK_LEVEL'] ?? 'LOW',
    'replay_risk': Platform.environment['REPLAY_RISK'] ?? 'NO',
    'escalated': Platform.environment['ESCALATED'] == 'true',
    'human_approved': Platform.environment['GOVERNANCE_HUMAN_TOKEN'] != null,
    'affected_files': args,
  };

  // 追加専用（Append-only）で保存 (Step 5-3)
  ledgerFile.writeAsStringSync(
    '${jsonEncode(decision)}\n', 
    mode: FileMode.append,
    flush: true
  );

  print('✅ Decision archived: ${decision['decision_id']}');
}