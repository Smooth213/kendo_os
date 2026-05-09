// ignore_for_file: avoid_print
import 'dart:io';

// Step 2-5: Machine Validation Tool
// AIや開発者がYAMLファイルを不正に書き換えていないかを検証するCLIツールです。
void main() {
  print('🤖 Running Machine Validation Tool...');
  final file = File('docs/governance/governance_rules.yaml');
  
  if (!file.existsSync()) {
    print('❌ [Error] governance_rules.yaml が見つかりません。');
    exit(1);
  }

  final content = file.readAsStringSync();
  bool hasViolation = false;

  // 絶対に true/false でなければならないコア不変条件の存在確認
  final requiredInvariants = {
    'deterministic: true': '決定論の保証が失われています',
    'stateless: true': '状態を持たない制約が失われています',
    'allow_io: false': 'IOアクセス禁止の制約が失われています',
    'mutation_forbidden: true': 'イベントの直接書き換え禁止の制約が失われています',
  };

  requiredInvariants.forEach((invariant, errorMessage) {
    if (!content.contains(invariant)) {
      print('❌ [Violation] $errorMessage ($invariant)');
      hasViolation = true;
    }
  });

  if (hasViolation) {
    print('🚨 Machine-readable Governance is corrupted! PR rejected.');
    exit(1);
  } else {
    print('✅ Machine-readable Governance is valid and immutable.');
    exit(0);
  }
}