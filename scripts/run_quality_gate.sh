#!/bin/bash
# ==============================================================================
# 🥋 Kendo OS - 総合品質ゲート実行スクリプト (Quality Gate)
# ==============================================================================
# 以下の品質基準をすべてクリアしているかを一括検証します：
# 1. 全18大ガバナンス個別監査 (1/18 〜 18/18: 100% PASS)
# 2. Dart静的解析 (flutter analyze: 0 issues, 警告ゼロ)
# 3. 単体・結合テスト (flutter test: 100% ALL PASS, エラーゼロ)
# ==============================================================================

set -e

echo ""
echo "================================================================"
echo " 🥋 Kendo OS - 総合品質ゲート検証を開始します"
echo "================================================================"
echo ""

# 1. 全18大ガバナンス個別監査
echo "🚀 [Step 1/3] 全18大ガバナンス個別監査を実行中..."
python3 scripts/run_all_governance.py
echo "✅ [Step 1/3] 全18大ガバナンス個別監査: ALL PASS"
echo ""

# 2. 静的解析
echo "🔍 [Step 2/3] Flutter 静的解析を実行中..."
flutter analyze
echo "✅ [Step 2/3] 静的解析: PASS (0 issues)"
echo ""

# 3. 単体・E2Eテスト
echo "🧪 [Step 3/3] 単体・結合・E2Eテストを実行中..."
flutter test test/governance/design_system_governance_test.dart \
             test/governance/text_scale_overflow_governance_test.dart \
             test/widget/all_screens_text_scale_no_overflow_test.dart \
             test/governance/cross_platform_parity_governance_test.dart \
             test/governance/ui_rebuild_governance_test.dart \
             test/governance/rendering_boundary_governance_test.dart \
             test/governance/list_virtualization_governance_test.dart \
             test/governance/isolate_and_concurrency_governance_test.dart \
             test/governance/low_load_and_timer_governance_test.dart \
             test/governance/memory_and_lifecycle_governance_test.dart \
             test/governance/io_batch_and_history_governance_test.dart \
             test/governance/sync_and_crdt_governance_test.dart \
             test/governance/resilience_and_twin_governance_test.dart \
             test/governance/match_calculator_governance_test.dart \
             test/governance/tournament_edit_sheet_governance_test.dart \
             test/governance/screens_and_bottom_sheets_governance_test.dart \
             test/governance/match_type_selection_governance_test.dart \
             test/governance/category_rules_fallback_governance_test.dart \
             test/widget/tournament_edit_dock_bottom_sheet_integration_test.dart \
             test/widget/tournament_share_import_and_order_flow_test.dart \
             test/widget/clipboard_import_button_and_service_test.dart \
             test/widget/expandable_notes_view_test.dart \
             test/widget/match_calculator_display_and_layout_test.dart \
             test/unit/match_allocation_engine_test.dart \
             test/unit/no_hardcoded_specific_names_test.dart \
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
             test/e2e/plan4_extreme_optimization_e2e_test.dart \
             test/e2e/plan7_perfection_e2e_test.dart
echo "✅ [Step 3/3] 単体・結合・E2Eテスト: PASS"
echo ""

echo "================================================================"
echo " 🎉 祝！すべての品質ゲート（全18大監査・解析・テスト）を突破しました！"
echo "================================================================"
echo "================================================================"
echo ""
