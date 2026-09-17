#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 【第3条 ガバナンス監査】🎨 デザインシステム・UIレイアウト 5段構造 ＆ テーマ視認性規約
================================================================================
① デザインシステム トークン規約（Hardcoded Color/Spacing排除）
② UIレイアウト 5段構造永続保持規約
③ テーマ視認性・白飛び黒潰れゼロ規約（コントラスト保証）
"""

import subprocess
import sys

SUB_AUDITS = [
    ("① デザインシステム トークン規約 (strict)", ["python3", "scripts/check_design_tokens.py", "--strict"]),
    ("② UIレイアウト 5段構造永続保持規約", ["python3", "scripts/check_layout_5tier_governance.py"]),
    ("③ テーマ視認性・白飛び黒潰れゼロ規約", ["python3", "scripts/check_theme_contrast_governance.py"]),
]

def main():
    print("=" * 68)
    print(" 📊 【第3条 ガバナンス監査】🎨 デザインシステム・UIレイアウト 5段構造 ＆ テーマ視認性規約")
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
        print(" 🟢 監査結果: 合格 (デザインシステム・UIレイアウト 5段構造 ＆ テーマ視認性規約に完全適合！)")
        print("=" * 68)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (第3条 デザインシステム・UIレイアウト 5段構造 ＆ テーマ視認性規約に違反があります)")
        print("=" * 68)
        sys.exit(1)

if __name__ == "__main__":
    main()
