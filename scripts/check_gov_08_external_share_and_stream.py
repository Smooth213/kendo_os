#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 【第8条 ガバナンス監査】🔗 外部連携・観客用共有URL ＆ ライブ配信直行規約
================================================================================
① 観客用共有URL・ルーティング・パラメータ整合性規約
② BAND LIVE配信連携・外部直行遷移＆白紙ブラウザ残留ゼロ規約
"""

import subprocess
import sys

SUB_AUDITS = [
    ("① 観客用共有URL・ルーティング・パラメータ整合性規約", ["python3", "scripts/check_share_url_governance.py"]),
    ("② BAND LIVE配信連携・外部直行遷移＆白紙ブラウザ残留ゼロ規約", ["python3", "scripts/check_band_live_integration_governance.py"]),
]

def main():
    print("=" * 68)
    print(" 📊 【第8条 ガバナンス監査】🔗 外部連携・観客用共有URL ＆ ライブ配信直行規約")
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
        print(" 🟢 監査結果: 合格 (外部連携・観客用共有URL ＆ ライブ配信直行規約に完全適合！)")
        print("=" * 68)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (第8条 外部連携・観客用共有URL ＆ ライブ配信直行規約に違反があります)")
        print("=" * 68)
        sys.exit(1)

if __name__ == "__main__":
    main()
