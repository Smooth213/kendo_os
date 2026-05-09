// ignore_for_file: avoid_print
import 'dart:io';

// ============================================================================
// Phase 5: ADR Consistency Automation
// ADR 001 の制約（Architecture Invariants）とコード実装の乖離を自動検出する
// 静的解析ツールです。
// ============================================================================
void main() {
  print('🔍 [Phase 5] Running ADR Consistency Analyzer...');
  bool hasViolation = false;

  // Step 5-1: ADR Rule Extractor作成 (ADRから絶対不変条件を読み込む)
  final adrFile = File('docs/adr/001_rule_engine_pluginization.md');
  if (!adrFile.existsSync()) {
    print('❌ [Error] ADR 001 が見つかりません。');
    exit(1);
  }
  final adrContent = adrFile.readAsStringSync();
  if (!adrContent.contains('RuleModule must remain stateless') ||
      !adrContent.contains('Hidden global mutable state is prohibited')) {
    print('❌ [Error] ADR 001 から必須の Architecture Invariants が欠落しています。');
    hasViolation = true;
  }

  // Step 5-3: RuleModule Stateless検査
  final ruleDir = Directory('lib/domain/rules');
  if (ruleDir.existsSync()) {
    final files = ruleDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
    for (final file in files) {
      final lines = file.readAsLinesSync();
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        // 簡易的な非Stateless検知: 'var' や非 'final' なプロパティ宣言を警告
        if (line.startsWith('var ') || (line.startsWith('static ') && !line.contains('const') && !line.contains('final'))) {
          print('❌ [ADR Violation] RuleModule is NOT stateless. Found mutable state in ${file.path}:${i+1} -> $line');
          hasViolation = true;
        }
      }
    }
  }

  // Step 5-4: Forbidden Dependency Graph検査
  // ドメイン層が外層（presentation, infrastructure）に依存することはADR違反
  final domainDir = Directory('lib/domain');
  if (domainDir.existsSync()) {
    final files = domainDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
    for (final file in files) {
      final lines = file.readAsLinesSync();
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.startsWith('import ') && 
           (line.contains('package:kendo_os/presentation/') || line.contains('package:kendo_os/infrastructure/'))) {
          print('❌ [ADR Violation] Forbidden Layer Dependency (Domain -> Outer Layer) in ${file.path}:${i+1} -> $line');
          hasViolation = true;
        }
      }
    }
  }

  // Step 5-5: Replay Safety Enforcement は CI上の `replay_regression_test.dart` に委譲

  if (hasViolation) {
    print('🚨 ADR Consistency Audit Failed! コードが Architecture Invariants から乖離（Drift）しています。');
    exit(1);
  } else {
    print('✅ ADR Consistency Audit Passed. コードは ADR の制約を完全に遵守しています。');
    exit(0);
  }
}