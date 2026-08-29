#!/bin/bash
# ==============================================================================
# 🥋 Kendo OS - Git Hooks 自動セットアップスクリプト
# ==============================================================================

set -e

echo "🔧 Git pre-commit フックをセットアップしています..."

HOOK_DIR=".git/hooks"
PRE_COMMIT_FILE="$HOOK_DIR/pre-commit"

if [ ! -d "$HOOK_DIR" ]; then
    echo "❌ .git/hooks ディレクトリが見つかりません。プロジェクトのルートで実行してください。"
    exit 1
fi

cat << 'EOF' > "$PRE_COMMIT_FILE"
#!/bin/bash
# ==============================================================================
# 🥋 Kendo OS - 自動ガバナンス pre-commit フック
# ==============================================================================

echo "🧹 Dart コードフォーマットおよび警告の自動修復中..."
dart fix --apply
dart format .

git add -A

echo "📏 kendo OS ファイル行数ガバナンス監査を実行中..."
python3 scripts/check_file_lines.py
if [ $? -ne 0 ]; then
    echo ""
    echo "🚨 【コミット拒否】500行以上の肥大化ファイルが検出されたため、コミットを中断しました。"
    echo "   単一責任原則に基づき、パーツやヘルパーに切り出して500行未満にスリム化してください。"
    exit 1
fi

python3 scripts/check_design_tokens.py --strict
if [ $? -ne 0 ]; then
    echo ""
    echo "💡 デザインシステム違反が検出されたため、コミットを中断しました。"
    echo "   AIアシスタントに「デザインシステム違反を文脈に合わせて修正して」とご指示いただければ自動修復いたします。"
    exit 1
fi

python3 scripts/check_kendo_score_governance.py
if [ $? -ne 0 ]; then
    echo ""
    echo "🚨 【コミット拒否】剣道公式スコア表示・PDF描画のガバナンス違反が検出されました。"
    echo "   KendoScoreBox規約およびPDFセル寸法(25px)に適合するように修正してください。"
    exit 1
fi

python3 scripts/check_kendo_metadata_governance.py
if [ $? -ne 0 ]; then
    echo ""
    echo "🚨 【コミット拒否】剣道メタデータ（シーンバッジ・名前パース・結果タグ）のガバナンス違反が検出されました。"
    echo "   KendoEntityNameParser / KendoSceneBadge 規約に適合するように修正してください。"
    exit 1
fi

echo "✅ pre-commit 全4大ガバナンス監査・フォーマット自動修復完了"
exit 0
EOF

chmod +x "$PRE_COMMIT_FILE"

echo "✅ [PASS] Git pre-commit フックのインストールが完了しました！"
echo "💡 以降、git commit 実行時に全4大ガバナンス（行数、デザイン、スコア表示・PDF、メタデータ）が自動監査・完全ブロックされます。"
