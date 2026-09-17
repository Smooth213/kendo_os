#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 【第7条 ガバナンス監査】📚 大会運用マニュアル ＆ 独立ルール安全フォールバック規約
================================================================================
① アプリ内マニュアル＆取説整合性規約
② 独立カテゴリ・ルール設定フォールバック安全規約
"""

import subprocess
import sys

SUB_AUDITS = [
    ("① アプリ内マニュアル＆取説整合性規約", ["python3", "scripts/check_manual_governance.py"]),
    ("② 独立カテゴリ・ルール設定フォールバック安全規約", ["python3", "scripts/check_category_rules_governance.py"]),
]

def main():
    print("=" * 68)
    print(" 📊 【第7条 ガバナンス監査】📚 大会運用マニュアル ＆ 独立ルール安全フォールバック規約")
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
        print(" 🟢 監査結果: 合格 (大会運用マニュアル ＆ 独立ルール安全フォールバック規約に完全適合！)")
        print("=" * 68)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (第7条 大会運用マニュアル ＆ 独立ルール安全フォールバック規約に違反があります)")
        print("=" * 68)
        sys.exit(1)

if __name__ == "__main__":
    main()
