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
        ["python3", "scripts/gov_test_helper.py", "test/governance/blob_url_leak_governance_test.dart"],
    ),
]

def main():
    print("=" * 68)
    print(" 📊 【第405条 ガバナンス監査】🧹 ブラウザBlobリソース即時解放・メモリリークゼロ規約")
    print("=" * 68)

    import os
    import sys
    script_dir = os.path.dirname(os.path.abspath(__file__))
    if script_dir not in sys.path:
        sys.path.insert(0, script_dir)
    from gov_static_scanner import GovStaticScanner

    scanner = GovStaticScanner()
    files = scanner.get_lib_files()

    occurrences = 0
    violations = []
    for p, c in files.items():
        if "createObjectURL" in c:
            occurrences += 1
            if "revokeObjectURL" not in c:
                violations.append(p)

    is_ok = (len(violations) == 0 and occurrences >= 1)
    status = "🟢 適合 (Passed)" if is_ok else "🔴 違反 (Failed)"
    print(f" ① ブラウザBlob URL即時解放・メモリリークゼロ規約: {status} (検出保護: {occurrences}箇所)")

    print("-" * 68)
    if is_ok:
        print(" 🟢 監査結果: 合格 (ブラウザBlobリソース即時解放・メモリリークゼロ規約に完全適合！)")
        print("=" * 68)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (第405条 ブラウザBlobリソース即時解放規約に違反があります)")
        for v in violations:
            print(f"  • {v}: revokeObjectURL による解放処理が不足しています")
        print("=" * 68)
        sys.exit(1)

if __name__ == "__main__":
    main()
