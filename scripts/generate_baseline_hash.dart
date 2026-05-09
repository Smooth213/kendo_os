// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';

// ============================================================================
// Phase 0: Baseline Hash Fixation
// 憲法、不変条件、禁止パターン等のガバナンスコアファイルのハッシュを固定し、
// AIによる「基準そのものの改変」を物理的に検知します。
// ============================================================================
void main() {
  print('🔒 [Baseline Freeze] Generating Governance Integrity Hashes...');

  final targetFiles = [
    'docs/governance/governance_constitution.md',
    'docs/governance/architecture_invariants.md',
    'governance/forbidden_patterns.yaml',
    'docs/governance/ai_worker_protocol.md',
  ];

  final Map<String, String> hashes = {};

  for (final path in targetFiles) {
    final file = File(path);
    if (!file.existsSync()) {
      print('❌ [ERROR] Missing core governance file: $path');
      exit(1);
    }
    
    final bytes = file.readAsBytesSync();
    final hash = sha256.convert(bytes).toString();
    hashes[path] = hash;
    print('✅ Frozen: $path ($hash)');
  }

  // ハッシュリストの保存（CIでの検証用）
  final hashFile = File('governance/baseline_hashes.json');
  hashFile.writeAsStringSync(jsonEncode(hashes));
  print('💾 Baseline hashes stored in ${hashFile.path}');
}