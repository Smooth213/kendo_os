#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 【第6条 ガバナンス監査】📄 UIレンダリング安全・PDF組版 ＆ 常設ドック規約
================================================================================
① 全ページ UIゼロレンダリングエラー保証（オーバーフローゼロ）
② PDF組版・長文字列あふれ・改ページ安全
③ ドック常設ミニパネル・オーバーレイ解放規約
"""

import subprocess
import sys

SUB_AUDITS = [
    ("① 全ページ UIゼロレンダリングエラー保証規約", ["python3", "scripts/check_rendering_safety_governance.py"]),
    ("② PDF組版・長文字列あふれ・改ページ安全規約", ["python3", "scripts/check_pdf_layout_safety_governance.py"]),
    ("③ ドック常設ミニパネル・オーバーレイ解放規約", ["python3", "scripts/check_dock_lifecycle_governance.py"]),
]

def main():
    print("=" * 68)
    print(" 📊 【第6条 ガバナンス監査】📄 UIレンダリング安全・PDF組版 ＆ 常設ドック規約")
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
        print(" 🟢 監査結果: 合格 (UIレンダリング安全・PDF組版 ＆ 常設ドック規約に完全適合！)")
        print("=" * 68)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (第6条 UIレンダリング安全・PDF組版 ＆ 常設ドック規約に違反があります)")
        print("=" * 68)
        sys.exit(1)

if __name__ == "__main__":
    main()
