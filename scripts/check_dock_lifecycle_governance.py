#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ==============================================================================
# 🥋 kendo OS - 【ガバナンス監査 18/18】📌 ドック・常設ミニパネル（Floating Dock）オーバーレイ解放・ライフサイクル 監査スクリプト
# ==============================================================================
import subprocess
import sys

def run_dock_lifecycle_governance():
    test_files = [
        "test/governance/floating_dock_lifecycle_governance_test.dart",
        "test/widget/viewer_no_dock_governance_test.dart",
    ]

    cmd = ["flutter", "test"] + test_files + ["--reporter=expanded"]
    result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    passed_all = (result.returncode == 0)

    rules = [
        ("1. OverlayEntry ライフサイクル解放＆即時破棄規約", passed_all),
        ("2. 二重展開防止・旧オーバーレイ自動解放規約", passed_all),
        ("3. 未展開時安全 close＆例外ゼロ規約", passed_all),
        ("4. 観客（Viewer）全7画面 ドック物理完全排除規約", passed_all),
    ]

    print("=" * 60)
    print(" 📊 【ガバナンス監査 18/18】📌 ドック・常設ミニパネル（Floating Dock）オーバーレイ解放・ライフサイクル 監査レポート")
    print("=" * 60)

    for label, is_ok in rules:
        status = "🟢 適合 (Passed)" if is_ok else "🔴 違反 (Failed)"
        print(f" {label}: {status}")

    print("-" * 60)
    if passed_all:
        print(" 🟢 監査結果: 合格 (常設ドック・オーバーレイ解放・ライフサイクルに完全適合！)")
        print("=" * 60)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (ドックライフサイクル・オーバーレイ解放に違反があります)")
        print("=" * 60)
        print("\n🚨 テスト実行エラー:")
        try:
            from test_failure_formatter import parse_and_format_failures
            print(parse_and_format_failures(result.stdout + result.stderr))
        except Exception:
            print(result.stdout + result.stderr)
        sys.exit(1)

if __name__ == "__main__":
    run_dock_lifecycle_governance()
