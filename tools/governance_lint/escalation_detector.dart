// ignore_for_file: avoid_print
import 'dart:io';

// ============================================================================
// Phase 2: AI Escalation Detector
// AIの出力（コード、コメント、説明文）をスキャンし、
// 推測実装（"maybe", "assume"）や曖昧な提案を検知して強制停止させます。
// ============================================================================
void main(List<String> args) {
  print('🕵️ [Escalation Guard] Scanning for AI ambiguity and risk...');

  final aiOutput = args.join(' ');
  final triggers = ['maybe', 'assume', 'I think', 'たぶん', 'おそらく', '推測'];

  bool hasAmbiguity = false;
  for (final trigger in triggers) {
    if (aiOutput.contains(trigger)) {
      print('❌ [AMBIGUITY DETECTED] AI attempted to guess: "$trigger"');
      hasAmbiguity = true;
    }
  }

  // 特定の重要ファイルに対する変更も強制エスカレーション
  final changedFiles = args.where((a) => a.contains('.dart')).toList();
  for (final file in changedFiles) {
    if (file.contains('score_event.dart')) {
      print('❌ [CATASTROPHIC RISK] Event Schema modification detected!');
      hasAmbiguity = true;
    }
  }

  if (hasAmbiguity) {
    print('🚨 [Escalation Protocol] ABORT: AI must stop and wait for Human Arbitration.');
    exit(1);
  } else {
    print('✅ [Escalation Guard] No obvious ambiguity detected.');
    exit(0);
  }
}