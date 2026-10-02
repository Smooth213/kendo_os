#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 【第405条 ガバナンス監査】🧹 ブラウザBlobリソース即時解放・メモリリークゼロ規約
================================================================================
① ブラウザBlob URL生成（createObjectURL）と即時解放（revokeObjectURL）整合性規約
② メディア・PDF・エクスポート時のブラウザメモリリーク完全防止規約
"""

import subprocess
import sys

SUB_AUDITS = [
    (
        "① ブラウザBlob URL即時解放・メモリリークゼロ規約",
        ["flutter", "test", "test/governance/blob_url_leak_governance_test.dart"],
    ),
]

def main():
    print("=" * 68)
    print(" 📊 【第405条 ガバナンス監査】🧹 ブラウザBlobリソース即時解放・メモリリークゼロ規約")
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
        print(" 🟢 監査結果: 合格 (ブラウザBlobリソース即時解放・メモリリークゼロ規約に完全適合！)")
        print("=" * 68)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (第405条 ブラウザBlobリソース即時解放規約に違反があります)")
        print("=" * 68)
        sys.exit(1)

if __name__ == "__main__":
    main()
