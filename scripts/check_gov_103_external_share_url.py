#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 【第103条 ガバナンス監査】🔗 外部連携・観客用共有URL ＆ ライブ配信直行規約
================================================================================
① 観客用共有URL・ルーティング・パラメータ整合性規約
② BAND LIVE配信連携・外部直行遷移＆白紙ブラウザ残留ゼロ規約
③ QRコード共有UI（ポップアップ＆ボトムシート）デザイン統一永続保証規約
"""

import os
import re
import subprocess
import sys

script_dir = os.path.dirname(os.path.abspath(__file__))
if script_dir not in sys.path:
    sys.path.insert(0, script_dir)

from gov_static_scanner import get_scanner, get_file_content


def check_qr_share_design():
    """③ QRコード共有UI（ポップアップ＆ボトムシート）デザイン統一永続保証規約"""
    allowed_files = {
        "lib/shared/widgets/qr_share_dialog.dart",
        "lib/features/tournament/presentation/components/program_management/viewer_qr_bottom_sheet.dart",
        "lib/features/p2p/presentation/components/p2p_broadcast_dialog.dart",
    }
    scanner = get_scanner()
    lib_files = scanner.get_lib_files()
    for rel_path, content in lib_files.items():
        if any(rel_path.endswith(allowed) for allowed in allowed_files):
            continue
        if "QrImageView(" in content:
            return False
    return True


def check_url_qr_encoding_safety():
    """④ 共有URL＆QR特殊文字パーセントエンコード安全規約"""
    scanner = get_scanner()
    lib_files = scanner.get_lib_files()
    for rel_path, content in lib_files.items():
        has_dynamic = (
            ("kendo-os-beta.web.app" in content and "?" in content)
            or "generateShareUrl" in content
            or "buildViewerUrl" in content
        )
        if has_dynamic:
            has_encoding = any(
                term in content
                for term in [
                    "Uri.encodeComponent",
                    "Uri.encodeQueryComponent",
                    "queryParameters",
                    "Uri.https",
                    "Uri(",
                ]
            )
            if not has_encoding:
                return False
    return True


def main():
    print("=" * 68)
    print(" 📊 【第103条 ガバナンス監査】🔗 外部連携・観客用共有URL ＆ ライブ配信直行規約")
    print("=" * 68)

    res1 = subprocess.run(["python3", "scripts/check_share_url_governance.py"], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    res2 = subprocess.run(["python3", "scripts/check_band_live_integration_governance.py"], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    ok3 = check_qr_share_design()
    ok4 = check_url_qr_encoding_safety()

    audits = [
        ("① 観客用共有URL・ルーティング・パラメータ整合性規約", res1.returncode == 0),
        ("② BAND LIVE配信連携・外部直行遷移＆白紙ブラウザ残留ゼロ規約", res2.returncode == 0),
        ("③ QRコード共有UI（ポップアップ＆ボトムシート）デザイン統一永続保証規約", ok3),
        ("④ 共有URL＆QR特殊文字パーセントエンコード安全規約", ok4),
    ]

    all_passed = True
    for label, is_ok in audits:
        status = "🟢 適合 (Passed)" if is_ok else "🔴 違反 (Failed)"
        print(f" {label}: {status}")
        if not is_ok:
            all_passed = False
            print(f"\n--- [詳細エラー: {label}] ---")
            print(res.stdout + res.stderr)
            print("-" * 40)

    print("-" * 68)
    if all_passed:
        print(" 🟢 監査結果: 合格 (外部連携・観客用共有URL ＆ ライブ配信直行規約に完全適合！)")
        print("=" * 68)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (第103条 外部連携・観客用共有URL ＆ ライブ配信直行規約に違反があります)")
        print("=" * 68)
        sys.exit(1)

if __name__ == "__main__":
    main()
