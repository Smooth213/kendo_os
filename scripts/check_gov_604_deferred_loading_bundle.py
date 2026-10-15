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

    import os
    import sys
    script_dir = os.path.dirname(os.path.abspath(__file__))
    if script_dir not in sys.path:
        sys.path.insert(0, script_dir)
    from gov_static_scanner import GovStaticScanner

    scanner = GovStaticScanner()
    files = scanner.get_lib_files()

    prohibited = [
        "package:pdf/pdf.dart",
        "package:pdf/widgets.dart",
        "package:printing/printing.dart",
        "package:syncfusion_flutter_pdfviewer/pdfviewer.dart",
    ]

    v_match = []
    v_viewer = []
    v_pdf = []

    for p, c in files.items():
        if "/features/match/" in p:
            for pkg in prohibited:
                if pkg in c:
                    v_match.append(f"{p}: {pkg}")
        if "/features/viewer/" in p:
            for pkg in prohibited:
                if pkg in c:
                    v_viewer.append(f"{p}: {pkg}")
        if "/features/pdf/" not in p:
            if "import 'package:pdf/" in c or 'import "package:pdf/' in c:
                v_pdf.append(p)

    rules = [
        ("① クリティカルUI隔離規約 (lib/features/match/ ゼロ依存)", len(v_match) == 0),
        ("② 観客ビュアーUI隔離規約 (lib/features/viewer/ ゼロ依存)", len(v_viewer) == 0),
        ("③ PDF機能局所化規約 (lib/features/pdf/ カプセル化)", len(v_pdf) == 0),
    ]

    all_passed = True
    for label, ok in rules:
        status = "🟢 適合 (Passed)" if ok else "🔴 違反 (Failed)"
        print(f" {label}: {status}")
        if not ok:
            all_passed = False

    print("-" * 68)
    if all_passed:
        print(" 🟢 監査結果: 合格 (重厚ライブラリの遅延読み込み・初期バンドル最小化規約に完全適合！)")
        print("=" * 68)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (第604条 重厚ライブラリ遅延読み込み規約に違反があります)")
        if v_match:
            print("【試合画面 違反ファイル】:", v_match)
        if v_viewer:
            print("【ビュアー画面 違反ファイル】:", v_viewer)
        if v_pdf:
            print("【PDFカプセル化 違反ファイル】:", v_pdf)
        print("=" * 68)
        sys.exit(1)

if __name__ == "__main__":
    main()
