// ignore_for_file: avoid_print
import 'dart:io';

// ============================================================================
// Phase 2: AI Output Diff Auditor
// PRで変更されたファイルを解析し、Critical Pathの変更検知、
// リスク分類（LOW ~ CATASTROPHIC）を行います。
// ============================================================================
void main(List<String> args) {
  print('🔍 [Diff Auditor] Analyzing changed files...');
  
  final changedFiles = args.isNotEmpty ? args : <String>[];
  
  if (changedFiles.isEmpty) {
    print('✅ No changed files provided for analysis.');
    exit(0);
  }

  // Step 2-1: Critical Boundary (簡易ハードコード、実運用ではYAMLパース)
  final criticalPaths = [
    'lib/domain/rules/',
    'lib/domain/entities/score_event.dart',
    'lib/application/projections/',
    'lib/domain/services/kendo_rule_engine.dart'
  ];

  bool affectsReplay = false;
  bool affectsSchema = false;
  String riskLevel = 'LOW';

  for (final file in changedFiles) {
    print('  - $file');
    
    // Step 2-2: Diff Analyzer
    if (file.contains('score_event.dart')) {
      affectsSchema = true;
      affectsReplay = true;
    }
    
    if (file.contains('lib/domain/rules/') || file.contains('kendo_rule_engine.dart')) {
      affectsReplay = true;
    }

    // Step 2-3: Risk Classifier
    if (affectsSchema) {
      riskLevel = 'CATASTROPHIC';
    } else if (affectsReplay) {
      riskLevel = 'CRITICAL';
    } else if (criticalPaths.any((p) => file.startsWith(p))) {
      riskLevel = 'HIGH';
    } else if (file.contains('lib/domain/')) {
      riskLevel = 'MEDIUM';
    }
  }

  print('\n📊 --- Audit Report ---');
  print('Risk Classification: $riskLevel');
  print('Replay Affected: ${affectsReplay ? 'YES' : 'NO'}');
  print('Schema Affected: ${affectsSchema ? 'YES' : 'NO'}');

  // Step 2-4: GitHub Actions Outputs
  final outputFile = Platform.environment['GITHUB_OUTPUT'];
  if (outputFile != null) {
    final file = File(outputFile);
    file.writeAsStringSync('risk_level=$riskLevel\n', mode: FileMode.append);
    file.writeAsStringSync('replay_risk=${affectsReplay ? 'YES' : 'NO'}\n', mode: FileMode.append);
  }

  if (riskLevel == 'CATASTROPHIC' || riskLevel == 'CRITICAL') {
    print('⚠️ [WARNING] Mandatory Human Review Required due to high risk level.');
  }

  exit(0);
}