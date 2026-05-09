// ignore_for_file: avoid_print
import 'dart:io';

void main() {
  print('🛡️ Running Governance Scanner...');
  bool hasViolation = false;

  // 1. Rule Purity & Forbidden API Check
  final ruleDir = Directory('lib/domain/rules');
  if (ruleDir.existsSync()) {
    final files = ruleDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
    
    for (final file in files) {
      final lines = file.readAsLinesSync();
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        
        // Step 1-2: Forbidden API Scanner
        if (line.contains('DateTime.now()') || line.contains('Random()')) {
          print('❌ [Violation] Forbidden API in ${file.path}:${i+1} -> $line');
          hasViolation = true;
        }
        
        // Step 1-5: Rule Purity (No IO)
        if (line.contains('dart:io') || line.contains('package:http')) {
          print('❌ [Violation] IO usage in RuleModule ${file.path}:${i+1} -> $line');
          hasViolation = true;
        }
        
        // Step 1-4: Mutable State Scanner
        if (line.contains('static ') && !line.contains('final') && !line.contains('const')) {
          print('❌ [Violation] Mutable static state in ${file.path}:${i+1} -> $line');
          hasViolation = true;
        }
      }
    }
  }

  // 2. Layer Violation Check (Domain -> Presentation/Infrastructure)
  final domainDir = Directory('lib/domain');
  if (domainDir.existsSync()) {
    final files = domainDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
    for (final file in files) {
      final lines = file.readAsLinesSync();
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        // Step 1-3: Layer Violation Scanner
        if (line.startsWith('import ') && (line.contains('presentation/') || line.contains('infrastructure/'))) {
          print('❌ [Violation] Layer Dependency Violation in ${file.path}:${i+1} -> $line');
          hasViolation = true;
        }
      }
    }
  }

  if (hasViolation) {
    print('🚨 Governance constraints violated! PR rejected.');
    exit(1);
  } else {
    print('✅ All governance checks passed.');
    exit(0);
  }
}