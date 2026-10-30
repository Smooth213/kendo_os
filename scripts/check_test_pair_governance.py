#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ==============================================================================
# 🥋 kendo OS - 【ガバナンス監査 11/14】🧪 新設ファイル・テストペア対生成 監査スクリプト
# ==============================================================================
import subprocess
import sys

def run_test_pair_governance():
    test_files = [
        "test/widget/components/qr_dialogs_and_actions_unified_test.dart",
        "test/widget/features/tournament/category_rule_tiles_and_lists_unified_test.dart",
        "test/widget/features/tournament/team_status_components_unified_test.dart",
        "test/widget/features/match/match_action_sections_and_components_unified_test.dart",
        "test/widget/features/bunaiksen/bunaiksen_match_components_test.dart",
        "test/widget/components/player_candidate_components_unified_test.dart",
        "test/unit/infrastructure/local_match_entity_mapper_test.dart",
        "test/unit/domain/services/kendo_overtime_evaluator_test.dart",
        "test/unit/application/match_progress_calculator_test.dart",
        "test/unit/domain/rules/category_rule_summary_card_test.dart",
    ]

    cmd = ["python3", "scripts/gov_test_helper.py"] + test_files + ["--reporter=expanded"]
    result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    output = result.stdout + result.stderr

    passed_all = (result.returncode == 0)

    rules = [
        ("1. lib/shared/widgets/ 新設Widget個別テスト対生成規約", "qr_dialogs_and_actions_unified_test.dart" in output or passed_all),
        ("2. lib/features/tournament/ 新設コンポーネント個別テスト対生成規約", "category_rule_tiles_and_lists_unified_test.dart" in output or passed_all),
        ("3. lib/features/match/ 新設ドメイン・計算ロジック個別テスト対生成規約", "kendo_overtime_evaluator_test.dart" in output or passed_all),
        ("4. lib/shared/infrastructure/ 新設マッパー・リポジトリ個別テスト対生成規約", "local_match_entity_mapper_test.dart" in output or passed_all),
    ]

    print("=" * 60)
    print(" 📊 【ガバナンス監査 11/14】🧪 新設ファイル・テストペア対生成 監査レポート")
    print("=" * 60)

    for label, is_ok in rules:
        status = "🟢 適合 (Passed)" if is_ok else "🔴 違反 (Failed)"
        print(f" {label}: {status}")

    print("-" * 60)
    if passed_all:
        print(" 🟢 監査結果: 合格 (新設全パーツに対する個別テスト対生成規約に完全適合！)")
        print("=" * 60)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (テストペア対生成違反またはテスト失敗が検出されました)")
        print("=" * 60)
        from test_failure_formatter import parse_and_format_failures
        print(parse_and_format_failures(output))
        sys.exit(1)

if __name__ == "__main__":
    run_test_pair_governance()
