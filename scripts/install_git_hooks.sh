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

echo "🚀 kendo OS 全10大ガバナンス個別監査を実行中..."

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

echo "🔍 Flutter 静的解析を実行中..."
flutter analyze || {
    echo ""
    echo "🚨 【コミット拒否】Flutter静的解析で問題・警告が検出されました。"
    echo "   コード内の警告・問題を 0 件に修正してください。"
    exit 1
}

echo "✅ pre-commit 全10大ガバナンス監査・静的解析・フォーマット自動修復完了"
exit 0
EOF

# 2. pre-push フック作成
cat << 'EOF' > "$PRE_PUSH_FILE"
#!/bin/bash
# ==============================================================================
# 🥋 Kendo OS - 自動ガバナンス ＆ 全テスト完全保証 pre-push フック
# ==============================================================================

echo ""
echo "================================================================"
echo " 🛡️  Kendo OS Pre-Push Quality Gate (完全品質要塞)"
echo "================================================================"
echo ""

echo "🚀 [Step 1/3] 全10大ガバナンス個別監査を実行中..."
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

echo ""
echo "🔍 [Step 2/3] Flutter 静的解析を実行中..."
flutter analyze || {
    echo ""
    echo "🚨 【プッシュ拒否】Flutter静的解析で問題・警告が検出されたため、プッシュを中断しました。"
    exit 1
}

echo ""
echo "🧪 [Step 3/3] Flutter 全テストスイート完全実行中..."
flutter test || {
    echo ""
    echo "🚨 【プッシュ拒否】テストエラーが検出されたため、プッシュを中断しました。"
    echo "   全テストが 100% PASS するように修正してください。"
    exit 1
}

echo ""
echo "================================================================"
echo " 🎉 祝！全10大ガバナンス・静的解析・全テストを完全クリアしました！"
echo "    安全にリモートへのプッシュを実行します。"
echo "================================================================"
echo ""
exit 0
EOF

chmod +x "$PRE_COMMIT_FILE"
chmod +x "$PRE_PUSH_FILE"

echo "✅ [PASS] Git フック (pre-commit & pre-push) のインストールが完了しました！"
echo "💡 以降、git commit 時に全10大ガバナンス＋静的解析、git push 時に全テストが自動監査・完全保証されます。"
