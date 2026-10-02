#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 【第604条 ガバナンス監査】📦 重厚ライブラリ遅延読み込み（Deferred Loading）＆ 初期バンドル最小化規約
================================================================================
① クリティカルUI隔離規約: 試合操作画面（lib/features/match/）からの直接同期インポート禁止
② 観客ビュアーUI隔離規約: リアルタイム観客画面（lib/features/viewer/）からの直接同期インポート禁止
③ PDF機能局所化規約: package:pdf/ の lib/features/pdf/ への完全カプセル化
"""

import subprocess
import sys

def main():
    print("=" * 68)
    print(" 📊 【第604条 ガバナンス監査】📦 重厚ライブラリ遅延読み込み＆初期バンドル最小化規約")
    print("=" * 68)

    cmd = ["flutter", "test", "test/governance/deferred_loading_governance_test.dart", "--reporter=expanded"]
    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    is_ok = (res.returncode == 0)

    rules = [
        ("① クリティカルUI隔離規約 (lib/features/match/ ゼロ依存)", is_ok),
        ("② 観客ビュアーUI隔離規約 (lib/features/viewer/ ゼロ依存)", is_ok),
        ("③ PDF機能局所化規約 (lib/features/pdf/ カプセル化)", is_ok),
    ]

    for label, ok in rules:
        status = "🟢 適合 (Passed)" if ok else "🔴 違反 (Failed)"
        print(f" {label}: {status}")

    print("-" * 68)
    if is_ok:
        print(" 🟢 監査結果: 合格 (重厚ライブラリの遅延読み込み・初期バンドル最小化規約に完全適合！)")
        print("=" * 68)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (第604条 重厚ライブラリ遅延読み込み規約に違反があります)")
        print("=" * 68)
        print(res.stdout + res.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
