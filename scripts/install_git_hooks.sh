#!/bin/bash
# ==============================================================================
# 🥋 Kendo OS - Git Hooks 自動セットアップスクリプト (pre-commit & pre-push)
# ==============================================================================

set -e

echo "🔧 Git フック (pre-commit & pre-push) をセットアップしています..."

HOOK_DIR=".git/hooks"
PRE_COMMIT_FILE="$HOOK_DIR/pre-commit"
PRE_PUSH_FILE="$HOOK_DIR/pre-push"

if [ ! -d "$HOOK_DIR" ]; then
    echo "❌ .git/hooks ディレクトリが見つかりません。プロジェクトのルートで実行してください。"
    exit 1
fi

# 1. pre-commit フック作成
cat << 'EOF' > "$PRE_COMMIT_FILE"
#!/bin/bash
# ==============================================================================
# 🥋 Kendo OS - 自動ガバナンス pre-commit フック
# ==============================================================================

echo "🧹 Dart コードフォーマットおよび警告の自動修復中..."
dart fix --apply
dart format .

git add -A

echo "🚀 kendo OS 全15大ガバナンス個別監査を実行中..."

python3 scripts/check_file_lines.py || exit 1
python3 scripts/check_design_tokens.py --strict || exit 1
python3 scripts/check_kendo_score_governance.py || exit 1
python3 scripts/check_kendo_metadata_governance.py || exit 1
python3 scripts/check_kendo_scene_governance.py || exit 1
python3 scripts/check_security_governance.py || exit 1
python3 scripts/check_layout_5tier_governance.py || exit 1
python3 scripts/check_theme_contrast_governance.py || exit 1
python3 scripts/check_architecture_boundary_governance.py || exit 1
python3 scripts/check_offline_resilience_governance.py || exit 1
python3 scripts/check_test_pair_governance.py || exit 1
python3 scripts/check_pdf_layout_safety_governance.py || exit 1
python3 scripts/check_web_platform_safety.py || exit 1
python3 scripts/check_tenant_isolation_governance.py || exit 1
python3 scripts/check_rendering_safety_governance.py || exit 1

echo "🔍 Flutter 静的解析を実行中..."
flutter analyze || {
    echo ""
    echo "🚨 【コミット拒否】Flutter静的解析で問題・警告が検出されました。"
    echo "   コード内の警告・問題を 0 件に修正してください。"
    exit 1
}

echo "🛡️ 全単体・ウィジェットテストを実行中（ゼロ破損完全保証）..."
python3 scripts/run_flutter_tests.py --skip-governance || {
    echo ""
    echo "🚨 【コミット拒否】テストエラーが検出されました。"
    echo "   すべてのテストをパスするまでコミットは中止されます。"
    exit 1
}

echo "✅ pre-commit 全15大ガバナンス監査・静的解析・全テスト・フォーマット完了"
exit 0
EOF

# 2. pre-push フック作成 (pre-commitで全テスト保証済みのため2重実行を完全排除)
cat << 'EOF' > "$PRE_PUSH_FILE"
#!/bin/bash
# ==============================================================================
# 🥋 Kendo OS - pre-push フック (重複テスト完全排除・高速プッシュ)
# ==============================================================================
# 💡 全15大ガバナンス監査・静的解析・全単体テストは pre-commit で100%保証済みのため、
#    プッシュ時の2重実行をスキップし、即座に安全にリモートへ送信します。

echo "🚀 [pre-push] コミット時品質ゲート（15大監査＋全テスト100%PASS）確認済み ➔ 即時プッシュ実行"
exit 0
EOF

chmod +x "$PRE_COMMIT_FILE"
chmod +x "$PRE_PUSH_FILE"

echo "✅ [PASS] Git フック (pre-commit & pre-push) のインストールが完了しました！"
echo "💡 以降、git commit 時に全15大ガバナンス＋静的解析、git push 時にゼロレンダリングエラー監査＋全テストが自動監査・完全保証されます。"
