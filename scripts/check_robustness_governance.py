#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ==============================================================================
# 🥋 Kendo OS - 【ガバナンス監査 26/26】🛡️ 堅牢性・同期整合性・データ完全性 永続保証規約 監査スクリプト
# ==============================================================================
import subprocess
import sys

def run_robustness_governance():
    test_files = [
        "test/governance/plan3_robustness_governance_test.dart",
    ]

    cmd = ["flutter", "test"] + test_files + ["--reporter=expanded"]
    result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    passed_all = (result.returncode == 0)

    rules = [
        ("1. [タイマー精度] match_timer_provider.dart の生ミリ秒差分加算＆天井秒逆算排除規約", passed_all),
        ("2. [Clock Skew補正] server_clock_offset_service.dart ＆ system_time_source.dart 連携規約", passed_all),
        ("3. [CRDT整合性] sync_crdt_merger.dart の3者マージ＆LWWタイマー調停規約", passed_all),
        ("4. [Webステート保護] match_list_provider.dart の大会切替時即時リセット＆IDフィルタ規約", passed_all),
        ("5. [FSM状態遷移] match_model.dart の lifecycleState ＆ transitionEvent 規約", passed_all),
    ]

    print("=" * 60)
    print(" 📊 【ガバナンス監査 26/26】🛡️ 堅牢性・同期整合性・データ完全性 永続保証 監査レポート")
    print("=" * 60)

    for label, is_ok in rules:
        status = "🟢 適合 (Passed)" if is_ok else "🔴 違反 (Failed)"
        print(f" {label}: {status}")

    print("-" * 60)
    if passed_all:
        print(" 🟢 監査結果: 合格 (堅牢性・同期整合性・データ完全性ガバナンス規約に完全適合！)")
        print("=" * 60)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (堅牢性・同期整合性・データ完全性ガバナンスに規約違反があります)")
        print("=" * 60)
        print("\n🚨 テスト実行エラー:")
        try:
            from test_failure_formatter import parse_and_format_failures
            print(parse_and_format_failures(result.stdout + result.stderr))
        except Exception:
            print(result.stdout + result.stderr)
        sys.exit(1)

if __name__ == "__main__":
    run_robustness_governance()
