#!/bin/bash
# ==============================================================================
# 🥋 Kendo OS - 総合品質ゲート実行スクリプト (Quality Gate)
# ==============================================================================
# 以下の品質基準をすべてクリアしているかを一括検証します：
# 1. ファイル行数ガバナンス (500行未満)
# 2. デザインシステムトークン厳格監査 (18項目100%遵守)
# 3. Dart静的解析 (flutter analyze: 0 issues)
# 4. 単体・ウィジェットテスト (flutter test: 100% ALL PASS)
# ==============================================================================

set -e

echo ""
echo "================================================================"
echo " 🥋 Kendo OS - 総合品質ゲート検証を開始します"
echo "================================================================"
echo ""

# 1. ファイル行数ガバナンス監査
echo "📏 [Step 1/4] ファイル行数ガバナンス監査を実行中..."
python3 scripts/check_file_lines.py
echo "✅ [Step 1/4] ファイル行数監査: PASS"
echo ""

# 2. デザインシステム厳格監査
echo "🎨 [Step 2/4] デザインシステム ガバナンス監査を実行中..."
python3 scripts/check_design_tokens.py --strict
echo "✅ [Step 2/4] デザインシステム監査: PASS"
echo ""

# 3. 静的解析
echo "🔍 [Step 3/4] Flutter 静的解析を実行中..."
flutter analyze
echo "✅ [Step 3/4] 静的解析: PASS"
echo ""

# 4. 単体テスト
echo "🧪 [Step 4/4] 単体テストを実行中..."
flutter test test/widget/sync_crdt_merger_test.dart \
             test/widget/match_command_queue_test.dart \
             test/widget/match_data_sanitizer_test.dart \
             test/widget/match_rewind_service_test.dart \
             test/widget/app_router_test.dart
echo "✅ [Step 4/4] 単体テスト: PASS"
echo ""

echo "================================================================"
echo " 🎉 祝！すべての品質ゲート（行数・デザイン・解析・テスト）を突破しました！"
echo "================================================================"
echo ""
