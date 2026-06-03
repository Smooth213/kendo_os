// ignore_for_file: avoid_print
import 'dart:io';

// ============================================================================
// Git Hooks Setup Utility
// ローカルでコミットする前に必ず dart format を実行し、
// CI環境での Format Drift (Exit Code 1) によるパイプラインの失敗を未然に防ぎます。
// ============================================================================
void main() {
  print('🔧 Setting up Git pre-commit hooks for Governance...');

  final hookDir = Directory('.git/hooks');
  if (!hookDir.existsSync()) {
    print('❌ .git/hooks directory not found. Are you in the project root?');
    exit(1);
  }

  final preCommitFile = File('.git/hooks/pre-commit');
  final hookContent = '''#!/bin/sh
echo "🔍 [Governance] Checking Dart formatting before commit..."
dart format --set-exit-if-changed .

if [ \$? -ne 0 ]; then
  echo "❌ [Governance] Format check failed. Applying automatic format..."
  dart format .
  echo "⚠️ [Action Required] Files were formatted automatically."
  echo "👉 Please run 'git add .' and commit again."
  exit 1
fi
''';

  preCommitFile.writeAsStringSync(hookContent);

  // スクリプトに実行権限を付与 (Linux/Mac)
  if (!Platform.isWindows) {
    Process.runSync('chmod', ['+x', preCommitFile.path]);
  }

  print('✅ [PASS] Git pre-commit hook installed successfully.');
  print('💡 以降、git commit 実行時に自動でフォーマットチェックが行われます。');
}
