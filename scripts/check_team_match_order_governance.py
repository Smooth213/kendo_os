#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ==============================================================================
# 🥋 kendo OS - 【ガバナンス監査 22/22】🥋 団体戦試合順序（先鋒〜大将・代表戦）剣道標準配列 永続保証 監査スクリプト
# ==============================================================================
import subprocess
import sys

def run_team_match_order_governance():
    test_files = [
        "test/governance/team_match_order_governance_test.dart",
    ]

    cmd = ["flutter", "test"] + test_files + ["--reporter=expanded"]
    result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    passed_all = (result.returncode == 0)

    rules = [
        ("1. [静的コード規約] 団体戦スコアボード・記録コンポーネントにおける KendoPositionSorter 適用規約", passed_all),
        ("2. [動的規約: 観戦ビュアー] 入力順序乱れ時の先鋒〜大将・代表戦 自動整列保証規約", passed_all),
        ("3. [動的規約: 通常ビュアー] 大会ホーム側スコアボードにおける剣道ポジション順序保証規約", passed_all),
        ("4. [動的規約: プロジェクション層] TeamMatchProjection.matches 剣道標準配列 永続保持規約", passed_all),
        ("5. [動的規約: ポジション体系網羅] 3人制・5人制・7人制・代表戦・順位戦・追加試合 全配列整合性規約", passed_all),
        ("6. [動的規約: 異常系耐性] order反転・未設定・同値および文字揺れ耐性規約", passed_all),
    ]

    print("=" * 60)
    print(" 📊 【ガバナンス監査 22/22】🥋 団体戦試合順序（先鋒〜大将・代表戦）剣道標準配列 永続保証 監査レポート")
    print("=" * 60)

    for label, is_ok in rules:
        status = "🟢 適合 (Passed)" if is_ok else "🔴 違反 (Failed)"
        print(f" {label}: {status}")

    print("-" * 60)
    if passed_all:
        print(" 🟢 監査結果: 合格 (通常・観戦ビュアー双方での団体戦スコア順序・剣道ポジション配列に完全適合！)")
        print("=" * 60)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (団体戦スコア順序・剣道ポジション配列に規約違反があります)")
        print("=" * 60)
        print("\n🚨 テスト実行エラー:")
        try:
            from test_failure_formatter import parse_and_format_failures
            print(parse_and_format_failures(result.stdout + result.stderr))
        except Exception:
            print(result.stdout + result.stderr)
        sys.exit(1)

if __name__ == "__main__":
    run_team_match_order_governance()
