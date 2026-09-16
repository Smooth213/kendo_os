#!/bin/bash
# ==============================================================================
# 🥋 Kendo OS - 総合品質ゲート実行スクリプト (Quality Gate)
# ==============================================================================
# 以下の品質基準をすべてクリアしているかを一括検証します：
# 1. 全32大ガバナンス個別監査 (1/32 〜 32/32: 100% PASS)
# 2. Dart静的解析 (flutter analyze: 0 issues, 警告ゼロ)
# 3. 単体・結合テスト (flutter test: 100% ALL PASS, エラーゼロ)
# ==============================================================================

set -e

echo ""
echo "================================================================"
echo " 🥋 Kendo OS - 総合品質ゲート検証を開始します"
echo "================================================================"
echo ""

# 1. 全32大ガバナンス個別監査
echo "🚀 [Step 1/3] 全32大ガバナンス個別監査を実行中..."
python3 scripts/run_all_governance.py
echo "✅ [Step 1/3] 全32大ガバナンス個別監査: ALL PASS"
echo ""

# 2. 静的解析
echo "🔍 [Step 2/3] Flutter 静的解析を実行中..."
flutter analyze
echo "✅ [Step 2/3] 静的解析: PASS (0 issues)"
echo ""

# 3. 単体・E2Eテスト
echo "🧪 [Step 3/3] 単体・結合・E2Eテストを実行中..."
flutter test test/governance/cross_platform_parity_governance_test.dart \
             test/governance/plan1_speed_and_isolate_governance_test.dart \
             test/widget/sync_crdt_merger_test.dart \
             test/widget/match_command_queue_test.dart \
             test/widget/match_data_sanitizer_test.dart \
             test/widget/match_rewind_service_test.dart \
             test/widget/app_router_test.dart \
             test/performance/adaptive_power_saving_thermal_test.dart \
             test/e2e/plan1_ui_responsiveness_e2e_test.dart \
             test/e2e/rapid_fire_score_responsiveness_e2e_test.dart \
             test/e2e/plan2_low_load_e2e_test.dart \
             test/e2e/plan3_robustness_e2e_test.dart \
             test/e2e/plan3_stability_resilience_e2e_test.dart \
             test/e2e/event_history_partition_e2e_test.dart \
             test/e2e/plan4_extreme_optimization_e2e_test.dart
echo "✅ [Step 3/3] 単体・結合・E2Eテスト: PASS"
echo ""

echo "================================================================"
echo " 🎉 祝！すべての品質ゲート（全32大監査・解析・テスト）を突破しました！"
echo "================================================================"
echo "================================================================"
echo ""
