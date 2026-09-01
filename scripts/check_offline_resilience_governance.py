#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ==============================================================================
# 🥋 kendo OS - 【ガバナンス監査 10/10】🌪️ 現場障害耐性・オフライン・耐久 監査スクリプト
# ==============================================================================
import subprocess
import sys

def run_resilience_governance():
    cmd = [
        "flutter", "test",
        "test/offline/phase4_offline_tolerance_test.dart",
        "test/endurance/phase7_long_term_endurance_test.dart",
        "test/chaos/phase7_operational_chaos_test.dart",
        "--reporter=expanded"
    ]
    result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    output = result.stdout + result.stderr
    passed_all = (result.returncode == 0)

    rules = [
        ("1. オフライン1,000連続入力・分散競合自動解決規約", "オフライン完全耐性"),
        ("2. 12時間連続タイマー・10,000回更新メモリリーク監視規約", "長時間運営耐久"),
        ("3. 体育館Wi-Fi断・端末回転・バックグラウンド復帰耐性規約", "Chaos & Operational Safety"),
    ]

    print("=" * 60)
    print(" 📊 【ガバナンス監査 10/10】🌪️ 現場障害耐性・オフライン・耐久 監査レポート")
    print("=" * 60)

    for label, pattern in rules:
        if passed_all:
            status = "🟢 適合 (Passed)"
        else:
            if pattern in output and "[E]" in output:
                status = "🔴 違反 (Failed)"
            else:
                status = "🟢 適合 (Passed)"
        print(f" {label}: {status}")

    print("-" * 60)
    if passed_all:
        print(" 🟢 監査結果: 合格 (現場過酷環境での完全耐久・耐性を保証！)")
        print("=" * 60)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (現場障害耐性・オフライン耐久テストに違反が検出されました)")
        print("=" * 60)
        print(output)
        sys.exit(1)

if __name__ == "__main__":
    run_resilience_governance()
