#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ==============================================================================
# 🥋 kendo OS - 【ガバナンス監査 17/18】🗂️ 独立カテゴリ・ルール設定（CategoryRule）フォールバック安全 監査スクリプト
# ==============================================================================
import subprocess
import sys

def run_category_rules_governance():
    test_files = [
        "test/governance/category_rules_fallback_governance_test.dart",
        "test/widget/category_rule_category_tile_test.dart",
    ]

    cmd = ["flutter", "test"] + test_files + ["--reporter=expanded"]
    result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    passed_all = (result.returncode == 0)

    rules = [
        ("1. 未設定・無効カテゴリIDフォールバック＆Null安全規約", passed_all),
        ("2. 部門削除後 既存試合整合性・安全縮退規約", passed_all),
        ("3. 延長方式（無制限一本勝負/判定/代表戦）整合性規約", passed_all),
        ("4. 上位戦（準決勝・決勝等）スマート判定＆ルール適用規約", passed_all),
    ]

    print("=" * 60)
    print(" 📊 【ガバナンス監査 17/18】🗂️ 独立カテゴリ・ルール設定（CategoryRule）フォールバック安全 監査レポート")
    print("=" * 60)

    for label, is_ok in rules:
        status = "🟢 適合 (Passed)" if is_ok else "🔴 違反 (Failed)"
        print(f" {label}: {status}")

    print("-" * 60)
    if passed_all:
        print(" 🟢 監査結果: 合格 (部門ルール独立化・フォールバック・整合性に完全適合！)")
        print("=" * 60)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (CategoryRuleフォールバック安全規約に違反があります)")
        print("=" * 60)
        print("\n🚨 テスト実行エラー:")
        try:
            from test_failure_formatter import parse_and_format_failures
            print(parse_and_format_failures(result.stdout + result.stderr))
        except Exception:
            print(result.stdout + result.stderr)
        sys.exit(1)

if __name__ == "__main__":
    run_category_rules_governance()
