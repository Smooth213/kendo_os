#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 【第403条 ガバナンス監査】🚨 サーマル適応警告・省電力UIトースト非ブロッキング表示 ＆ メモリリークゼロ規約
================================================================================
① サーマル・省電力トースト非ブロッキング表示規約（タップ阻害完全ゼロ）
② 自動消去・OverlayEntry / Timer / StreamSubscription 明示的完全破棄規約
"""

import subprocess
import sys

def main():
    print("=" * 68)
    print(" 📊 【第403条 ガバナンス監査】🚨 サーマル適応警告・省電力UIトースト非ブロッキング表示 ＆ メモリリークゼロ規約")
    print("=" * 68)

    cmd = [
        "flutter",
        "test",
        "test/governance/thermal_toast_governance_test.dart",
        "--reporter=expanded",
    ]

    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    is_ok = (res.returncode == 0)

    rules = [
        ("① [非ブロッキング] トースト表示中のタップ操作阻害ゼロ ＆ 即時応答規約", is_ok),
        ("② [リソース完全解放] OverlayEntry / Timer / StreamSubscription dispose破棄規約", is_ok),
    ]

    for label, ok in rules:
        status = "🟢 適合 (Passed)" if ok else "🔴 違反 (Failed)"
        print(f" {label}: {status}")

    print("-" * 68)
    if is_ok:
        print(" 🟢 監査結果: 合格 (サーマル適応警告・省電力UIトースト非ブロッキング表示 ＆ メモリリークゼロ規約に完全適合！)")
        print("=" * 68)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (第403条 サーマル適応警告・省電力UIトースト非ブロッキング表示 ＆ メモリリークゼロ規約に違反があります)")
        print("=" * 68)
        print(res.stdout + res.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
