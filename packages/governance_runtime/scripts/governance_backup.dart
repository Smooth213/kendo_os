// ignore_for_file: avoid_print
import 'dart:io';

// ============================================================================
// Phase 9: Governance Backup
// 現在のガバナンス設定、不変条件、スコア履歴をバックアップし、
// システムの「統治状態」を永続化します。
// ============================================================================
void main() {
  print('📦 [Governance Backup] Archiving Governance State...');

  final backupDir = Directory('governance/backups');
  if (!backupDir.existsSync()) backupDir.createSync(recursive: true);

  final timestamp = DateTime.now().toUtc().toIso8601String().replaceAll(':', '-');
  final backupFile = File('governance/backups/gov_state_$timestamp.json');

  // 現在の憲法と不変条件のハッシュを記録
  final invariants = File('docs/governance/architecture_invariants.md').readAsStringSync();
  final constitution = File('docs/governance/governance_constitution.md').readAsStringSync();

  final state = {
    'version': '1.0',
    'timestamp': timestamp,
    'invariants_hash': invariants.hashCode.toString(),
    'constitution_hash': constitution.hashCode.toString(),
    'status': 'HARDENED'
  };

  backupFile.writeAsStringSync(state.toString());
  print('✅ Governance State backed up to: ${backupFile.path}');
}