// ignore_for_file: avoid_print
import 'dart:io';

// ============================================================================
// Phase 5: Governance Score Engine
// 変更ファイルの性質からガバナンスリスクを定量化（0-100）します。
// ============================================================================
void main(List<String> args) {
  print('📊 [Score Engine] Calculating Governance Risk Score...');
  
  if (args.isEmpty) {
    print('✅ No changes detected. Score: 0');
    exit(0);
  }

  double totalScore = 0;
  final changedFiles = args;

  for (final file in changedFiles) {
    if (file.contains('score_event.dart')) {
      totalScore += 90;
    } else if (file.contains('lib/domain/rules/')) {
      totalScore += 70;
    } else if (file.contains('lib/application/projections/')) {
      totalScore += 30;
    } else if (file.contains('_test.dart')) {
      totalScore += 5;
    } else if (file.endsWith('.md') || file.endsWith('.yaml')) {
      totalScore += 1;
    }
  }

  // スコアの正規化（最大100）
  final finalScore = totalScore > 100 ? 100 : totalScore;
  print('⚖️ Final Governance Risk Score: $finalScore / 100');

  // Step 5-3: Metrics output for CI
  final outputFile = Platform.environment['GITHUB_OUTPUT'];
  if (outputFile != null) {
    File(outputFile).writeAsStringSync('gov_score=$finalScore\n', mode: FileMode.append);
  }

  if (finalScore >= 85) {
    print('🚨 [CRITICAL RISK] Score exceeds safety threshold!');
  }
}