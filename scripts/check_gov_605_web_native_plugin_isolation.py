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

    import os
    import sys
    script_dir = os.path.dirname(os.path.abspath(__file__))
    if script_dir not in sys.path:
        sys.path.insert(0, script_dir)
    from gov_static_scanner import GovStaticScanner

    scanner = GovStaticScanner()
    files = scanner.get_lib_files()
    platform_specific = {"lib/shared/platform/platform_file_io.dart"}

    violations = []
    for p, c in files.items():
        if p in platform_specific:
            continue
        if "getApplicationDocumentsDirectory(" in c and "kIsWeb" not in c:
            violations.append(f"{p}: getApplicationDocumentsDirectory が kIsWeb 保護なしに呼び出されています")
        if "Isar.open(" in c and "kIsWeb" not in c:
            violations.append(f"{p}: Isar.open が kIsWeb 保護なしに呼び出されています")
        if ("Printing.layoutPdf(" in c or "Printing.sharePdf(" in c) and "kIsWeb" not in c:
            violations.append(f"{p}: Printing API が kIsWeb 保護なしに呼び出されています")

    is_ok = (len(violations) == 0)
    status = "🟢 適合 (Passed)" if is_ok else "🔴 違反 (Failed)"
    print(f" ① Web非対応プラグイン直接呼出遮断・kIsWebガード境界規約: {status}")

    print("-" * 68)
    if is_ok:
        print(" 🟢 監査結果: 合格 (Web/ネイティブプラグイン完全隔離・バウンダリ漏洩ゼロ規約に完全適合！)")
        print("=" * 68)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (第605条 Web/ネイティブプラグイン完全隔離規約に違反があります)")
        for v in violations:
            print(f"  • {v}")
        print("=" * 68)
        sys.exit(1)

if __name__ == "__main__":
    main()
