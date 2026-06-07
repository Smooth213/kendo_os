// ignore_for_file: avoid_print
import 'dart:io';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

// ============================================================================
// Phase 5: AI Governance AST Linter
// CI/CDで動作し、AIが生成したコードから禁止されたパターンを検出する。
// ============================================================================

void main(List<String> args) {
  print('🛡️ [Governance AST Linter] Starting AST inspection (Phase 5)...');
  bool hasViolation = false;

  final targetFiles = args.isEmpty
      ? _getAllDartFiles(Directory('lib')).toList()
      : args.where((f) => f.endsWith('.dart')).toList();

  for (final filePath in targetFiles) {
    final file = File(filePath);
    if (!file.existsSync()) continue;

    final content = file.readAsStringSync();

    try {
      final parseResult = parseString(content: content, path: filePath);
      final visitor = ForbiddenNodeVisitor(filePath);
      parseResult.unit.visitChildren(visitor);

      if (visitor.hasViolation) {
        hasViolation = true;
      }
    } catch (e) {
      print('⚠️ [Parse Error] Failed to parse $filePath: $e');
    }
  }

  if (hasViolation) {
    print('🚨 [FATAL] AI Governance AST Policy Violation Detected!');
    print('AIによるリプレイ破壊、Projection上書き、Event変異が検出されたため、CIをFailします。');
    exit(1);
  } else {
    print('✅ [PASS] No forbidden AST nodes found. AI boundary is intact.');
  }
}

Iterable<String> _getAllDartFiles(Directory dir) {
  if (!dir.existsSync()) return [];
  return dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .map((f) => f.path);
}

class ForbiddenNodeVisitor extends RecursiveAstVisitor<void> {
  final String filePath;
  bool hasViolation = false;

  ForbiddenNodeVisitor(this.filePath);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final targetName = node.target?.toSource() ?? '';
    final methodName = node.methodName.name;

    if (targetName == 'DateTime' && methodName == 'now') {
      _reportViolation(
        node,
        'Usage of DateTime.now() is forbidden. Use TimeSource to ensure replay determinism.',
      );
    }
    if (methodName == 'Random' && targetName.isEmpty) {
      _reportViolation(
        node,
        'Usage of Random() is forbidden. Hallucination replay attack prevented.',
      );
    }
    if (methodName == 'clear') {
      _reportViolation(
        node,
        'Usage of .clear() is forbidden. Event mutation / Projection overwrite detected.',
      );
    }
    if (methodName == 'removeWhere') {
      _reportViolation(
        node,
        'Usage of .removeWhere() is forbidden. Event mutation / Projection overwrite detected.',
      );
    }

    super.visitMethodInvocation(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final typeName = node.constructorName.type.toSource();
    if (typeName == 'Random') {
      _reportViolation(
        node,
        'Usage of Random() is forbidden. Hallucination replay attack prevented.',
      );
    }
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitInterpolationExpression(InterpolationExpression node) {
    // 文字列補間 `${...}` の内部でメソッドチェーン（例: .join()）が呼ばれていないか監視する
    if (node.expression is MethodInvocation) {
      _reportViolation(
        node,
        'Format Drift Prevention: Method chaining inside string interpolation (e.g. \${list.join()}) is forbidden. '
        'Extract to a local variable first to guarantee CI formatter stability.',
      );
    }
    super.visitInterpolationExpression(node);
  }

  void _reportViolation(AstNode node, String reason) {
    hasViolation = true;
    print('❌ [Violation] $filePath : $reason');
    print('   -> ${node.toSource()}');
  }
}
