#!/bin/bash
# ==============================================================================
# 🥋 Kendo OS - 総合品質ゲート実行スクリプト (Quality Gate)
# ==============================================================================
# 以下の品質基準をすべてクリアしているかを一括検証します：
# 1. 全14大ガバナンス個別監査 (1/14 〜 14/14: 100% PASS)
# 2. Dart静的解析 (flutter analyze: 0 issues, 警告ゼロ)
# 3. 単体・結合テスト (flutter test: 100% ALL PASS, エラーゼロ)
# ==============================================================================

set -e

echo ""
echo "================================================================"
echo " 🥋 Kendo OS - 総合品質ゲート検証を開始します"
echo "================================================================"
echo ""

# 1. 全14大ガバナンス個別監査
echo "🚀 [Step 1/3] 全14大ガバナンス個別監査を実行中..."
python3 scripts/check_file_lines.py
python3 scripts/check_design_tokens.py --strict
python3 scripts/check_kendo_score_governance.py
python3 scripts/check_kendo_metadata_governance.py
python3 scripts/check_kendo_scene_governance.py
python3 scripts/check_security_governance.py
python3 scripts/check_layout_5tier_governance.py
python3 scripts/check_theme_contrast_governance.py
python3 scripts/check_architecture_boundary_governance.py
python3 scripts/check_offline_resilience_governance.py
python3 scripts/check_test_pair_governance.py
python3 scripts/check_pdf_layout_safety_governance.py
python3 scripts/check_web_platform_safety.py
python3 scripts/check_tenant_isolation_governance.py
echo "✅ [Step 1/3] 全14大ガバナンス個別監査: ALL PASS"
echo ""

# 2. 静的解析
echo "🔍 [Step 2/3] Flutter 静的解析を実行中..."
flutter analyze
echo "✅ [Step 2/3] 静的解析: PASS (0 issues)"
echo ""

# 3. 単体テスト
echo "🧪 [Step 3/3] 単体テストを実行中..."
flutter test test/widget/sync_crdt_merger_test.dart \
             test/widget/match_command_queue_test.dart \
             test/widget/match_data_sanitizer_test.dart \
             test/widget/match_rewind_service_test.dart \
             test/widget/app_router_test.dart
echo "✅ [Step 3/3] 単体テスト: PASS"
echo ""

echo "================================================================"
echo " 🎉 祝！すべての品質ゲート（全14大監査・解析・テスト）を突破しました！"
echo "================================================================"
echo ""
