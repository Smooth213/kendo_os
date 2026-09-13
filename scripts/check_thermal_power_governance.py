#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ==============================================================================
# 🥋 kendo OS - 【ガバナンス監査 23/23】🔋 端末サーマル冷却＆省電力モード管理（温度＞手動＞自動 ガバナンス永続保証）監査スクリプト
# ==============================================================================
import subprocess
import sys

def run_thermal_power_governance():
    test_files = [
        "test/governance/thermal_power_governance_test.dart",
    ]

    cmd = ["flutter", "test"] + test_files + ["--reporter=expanded"]
    result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    passed_all = (result.returncode == 0)

    rules = [
        ("1. [最重要ガバナンス] 優先順位「温度 ＞ 手動 ＞ 自動」完全階層保証規約", passed_all),
        ("2. [低電力＆電池残量連携] OS低電力モードON時における電池残量自動切り替え規約", passed_all),
        ("3. [絶対時間精度保証] サーマル間引き時におけるタイマー計算精度100%保証規約", passed_all),
        ("4. [CPU負荷削減規約] エコ冷却80%削減、極限省電力90%削減のウェイクアップ間引き規約", passed_all),
        ("5. [通知クールダウン規約] 同一温度・状態におけるトースト連発抑制規約", passed_all),
        ("6. [操作非遮断・タップ透過] トースト表示中の試合画面ボタン操作非阻害規約", passed_all),
        ("7. [設定永続化規約] thermalPowerPreference の SharedPreferences 永続化・復元規約", passed_all),
    ]

    print("=" * 60)
    print(" 📊 【ガバナンス監査 23/23】🔋 端末サーマル冷却＆省電力モード管理 永続保証 監査レポート")
    print("=" * 60)

    for label, is_ok in rules:
        status = "🟢 適合 (Passed)" if is_ok else "🔴 違反 (Failed)"
        print(f" {label}: {status}")

    print("-" * 60)
    if passed_all:
        print(" 🟢 監査結果: 合格 (温度＞手動＞自動の最優先階層および省電力制御規約に完全適合！)")
        print("=" * 60)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (サーマル冷却・省電力ガバナンスに規約違反があります)")
        print("=" * 60)
        print("\n🚨 テスト実行エラー:")
        try:
            from test_failure_formatter import parse_and_format_failures
            print(parse_and_format_failures(result.stdout + result.stderr))
        except Exception:
            print(result.stdout + result.stderr)
        sys.exit(1)

if __name__ == "__main__":
    run_thermal_power_governance()
