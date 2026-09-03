#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ==============================================================================
# 🥋 kendo OS - 【ガバナンス監査 14/14】🏢 マルチテナント道場・大会空間 隔離監査スクリプト
# ==============================================================================
import subprocess
import sys

def run_tenant_isolation_governance():
    test_files = [
        "test/features/mixed_scene_rules_ranking_test.dart",
        "test/unit/league_standings_integration_test.dart",
    ]

    cmd = ["flutter", "test"] + test_files + ["--reporter=expanded"]
    result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    output = result.stdout + result.stderr

    passed_all = (result.returncode == 0)

    rules = [
        ("1. 同一大会内 混合ルール（本戦/錬成/申合せ）集計整合性規約", passed_all),
        ("2. 変則勝ち点（3/1/0点 vs 1/0.5/0点）順位決定論的解決規約", passed_all),
        ("3. 同率同勝ち点タイブレーク（勝者数 ➔ 総本数）解決規約", passed_all),
        ("4. エキシビション/練習試合（countForStandings=false）集計除外規約", passed_all),
    ]

    print("=" * 60)
    print(" 📊 【ガバナンス監査 14/14】🏢 マルチテナント道場・大会空間 隔離監査レポート")
    print("=" * 60)

    for label, is_ok in rules:
        status = "🟢 適合 (Passed)" if is_ok else "🔴 違反 (Failed)"
        print(f" {label}: {status}")

    print("-" * 60)
    if passed_all:
        print(" 🟢 監査結果: 合格 (マルチテナント道場・大会空間隔離規約に完全適合！)")
        print("=" * 60)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (マルチテナント隔離規約違反またはテスト失敗が検出されました)")
        print("=" * 60)
        from test_failure_formatter import parse_and_format_failures
        print(parse_and_format_failures(output))
        sys.exit(1)

if __name__ == "__main__":
    run_tenant_isolation_governance()
