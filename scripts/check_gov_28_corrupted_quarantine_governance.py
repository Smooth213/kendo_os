#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 【第28条 ガバナンス監査】🚨 障害データ隔離（Quarantine）・フェイルセーフ二次破壊完全阻止 ＆ 生データ救済規約
================================================================================
① 破損状態における編集完全ロック（打突・タイマー・操作遮断）規約
② リアルタイムViewer継続閲覧（電波障害・現地パニック防止）規約
③ 生データ（イベントログ）救済エクスポート許可 ＆ 赤色警告バナー表示規約
"""

import subprocess
import sys

def main():
    print("=" * 68)
    print(" 📊 【第28条 ガバナンス監査】🚨 障害データ隔離（Quarantine）・フェイルセーフ二次破壊完全阻止 ＆ 生データ救済規約")
    print("=" * 68)

    cmd = [
        "flutter",
        "test",
        "test/governance/corrupted_state_quarantine_governance_test.dart",
        "--reporter=expanded",
    ]

    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    is_ok = (res.returncode == 0)

    rules = [
        ("① [二次破壊完全阻止] 破損試合における編集・打突・タイマー完全ロック規約", is_ok),
        ("② [現地パニック防止] 観戦用Viewer画面でのリアルタイム状況閲覧継続規約", is_ok),
        ("③ [フェイルセーフ救済] 生データテキスト書き出し許可 ＆ 赤色警告バナー規約", is_ok),
    ]

    for label, ok in rules:
        status = "🟢 適合 (Passed)" if ok else "🔴 違反 (Failed)"
        print(f" {label}: {status}")

    print("-" * 68)
    if is_ok:
        print(" 🟢 監査結果: 合格 (障害データ隔離・フェイルセーフ二次破壊完全阻止 ＆ 生データ救済規約に完全適合！)")
        print("=" * 68)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (第28条 障害データ隔離・フェイルセーフ二次破壊完全阻止 ＆ 生データ救済規約に違反があります)")
        print("=" * 68)
        print(res.stdout + res.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
