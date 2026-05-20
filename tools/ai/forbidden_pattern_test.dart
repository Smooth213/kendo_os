import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

// ============================================================================
// Phase 5: Hallucination replay attack test
// AIが禁止パターン（DateTime.now, Random, mutation等）を生成した際、
// AST Validatorが確実にそれをブロックし、CIがFailすることを保証する。
// ============================================================================
void main() {
  group('🛡️ AI Boundary & Hallucination Replay Attack Prevention', () {
    test('Linter should detect DateTime.now(), Random(), clear(), and removeWhere()', () async {
      final tempFile = File('test/ai/temp_rogue_file.dart');
      tempFile.writeAsStringSync('''
import 'dart:math';

void rogueFunction() {
  // Replay Destruction Attack
  final now = DateTime.now();
  
  // Hallucination Replay Attack
  final rand = Random();
  
  // Event Mutation / Projection Overwrite Attack
  final list = [1, 2, 3];
  list.clear();
  list.removeWhere((e) => e == 1);
}
''');

      final result = await Process.run('dart', ['run', 'tools/governance_lint/forbidden_ast_detector.dart', tempFile.path]);
      
      // CI Fail化の検証
      expect(result.exitCode, 1, reason: 'AIによる禁止コードの生成は必ずCIをFailさせなければならない');
      
      final stdout = result.stdout.toString();
      expect(stdout, contains('DateTime.now()'));
      expect(stdout, contains('Random()'));
      expect(stdout, contains('.clear()'));
      expect(stdout, contains('.removeWhere()'));
      expect(stdout, contains('AI Governance AST Policy Violation Detected!'));

      if (tempFile.existsSync()) {
        tempFile.deleteSync();
      }
    });

    test('Linter passes on compliant immutable logic', () async {
      final tempFile = File('test/ai/temp_clean_file.dart');
      tempFile.writeAsStringSync('''
void compliantFunction() {
  // Immutable operations are allowed
  final list = [1, 2, 3];
  final newList = list.where((e) => e != 1).toList();
}
''');

      final result = await Process.run('dart', ['run', 'tools/governance_lint/forbidden_ast_detector.dart', tempFile.path]);
      
      expect(result.exitCode, 0, reason: '遵守されたコードはCIをPassするべき');
      
      if (tempFile.existsSync()) {
        tempFile.deleteSync();
      }
    });
  });
}