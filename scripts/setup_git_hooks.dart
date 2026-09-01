// ignore_for_file: avoid_print
import 'dart:io';

// ============================================================================
// Git Hooks Setup Utility
// 1. コードフォーマット自動修復 (dart fix & dart format)
// 2. ファイル行数ガバナンス監査 (500行以上の肥大化防止)
// 3. デザインシステムトークン厳格監査 (18項目100%遵守)
// ============================================================================
void main() {
  print('🔧 Setting up Git pre-commit hooks for Governance...');

  final hookDir = Directory('.git/hooks');
  if (!hookDir.existsSync()) {
    print('❌ .git/hooks directory not found. Are you in the project root?');
    exit(1);
  }

  final preCommitFile = File('.git/hooks/pre-commit');
  final hookContent = '''#!/bin/bash
# ==============================================================================
# 🥋 Kendo OS - 自動ガバナンス pre-commit フック
# ==============================================================================

echo "🧹 Dart コードフォーマットおよび警告の自動修復中..."
dart fix --apply
dart format .

git add -A

echo "📏 kendo OS ファイル行数ガバナンス監査を実行中..."
python3 scripts/check_file_lines.py
if [ \$? -ne 0 ]; then
    echo ""
    echo "🚨 【コミット拒否】500行以上の肥大化ファイルが検出されたため、コミットを中断しました。"
    echo "   単一責任原則に基づき、パーツやヘルパーに切り出して500行未満にスリム化してください。"
    exit 1
fi

echo "🛡️ kendo OS デザインシステム ガバナンス自動監査を実行中..."
python3 scripts/check_design_tokens.py --strict
if [ \$? -ne 0 ]; then
    echo ""
    echo "💡 デザインシステム違反が検出されたため、コミットを中断しました。"
    echo "   AIアシスタントに「デザインシステム違反を文脈に合わせて修正して」とご指示いただければ自動修復いたします。"
    exit 1
fi

echo "⚔️ kendo OS 試合シーン（本戦・錬成・申合せ）表記＆配色ガバナンス監査を実行中..."
python3 scripts/check_kendo_scene_governance.py
if [ \$? -ne 0 ]; then
    echo ""
    echo "🚨 【コミット拒否】試合シーンの表記・配色違反が検出されたため、コミットを中断しました。"
    echo "   表記は「本戦」「錬成」「申合せ」とし、配色は KendoSceneHelper を使用してください。"
    exit 1
fi

echo "✅ pre-commit ガバナンス監査・フォーマット自動修復完了"
exit 0
''';

  preCommitFile.writeAsStringSync(hookContent);

  // pre-push フックが存在する場合は重複防止のため削除
  final prePushFile = File('.git/hooks/pre-push');
  if (prePushFile.existsSync()) {
    prePushFile.deleteSync();
  }

  if (!Platform.isWindows) {
    Process.runSync('chmod', ['+x', preCommitFile.path]);
  }

  print('✅ [PASS] Git pre-commit hook installed successfully.');
  print('💡 以降、git commit 実行時に行数・デザイン・試合シーンガバナンスが自動監査されます。');
}
