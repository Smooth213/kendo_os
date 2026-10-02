#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 【第605条 ガバナンス監査】🌐 Web/ネイティブプラグイン完全隔離・バウンダリ漏洩ゼロ規約
================================================================================
① Web非対応プラグイン（isar, printing, path_provider等）の直接呼び出し遮断規約
② kIsWeb ガード・プラットフォーム分離境界 永続保証規約
"""

import subprocess
import sys

SUB_AUDITS = [
    (
        "① Web非対応プラグイン直接呼出遮断・kIsWebガード境界規約",
        ["python3", "scripts/gov_test_helper.py", "test/governance/web_unsupported_plugin_leak_governance_test.dart"],
    ),
]

def main():
    print("=" * 68)
    print(" 📊 【第605条 ガバナンス監査】🌐 Web/ネイティブプラグイン完全隔離・バウンダリ漏洩ゼロ規約")
    print("=" * 68)

    all_passed = True
    for label, cmd in SUB_AUDITS:
        res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        is_ok = (res.returncode == 0)
        status = "🟢 適合 (Passed)" if is_ok else "🔴 違反 (Failed)"
        print(f" {label}: {status}")
        if not is_ok:
            all_passed = False
            print(f"\n--- [詳細エラー: {label}] ---")
            print(res.stdout + res.stderr)
            print("-" * 40)

    print("-" * 68)
    if all_passed:
        print(" 🟢 監査結果: 合格 (Web/ネイティブプラグイン完全隔離・バウンダリ漏洩ゼロ規約に完全適合！)")
        print("=" * 68)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (第605条 Web/ネイティブプラグイン完全隔離規約に違反があります)")
        print("=" * 68)
        sys.exit(1)

if __name__ == "__main__":
    main()
