#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 【第18条 ガバナンス監査】🧮 試合数計算・コート配分シミュレーション ＆ 部内戦ドック品質規約
================================================================================
① 試合数計算機 設計憲法・モデル不変性・行数境界（Max 500行）規約
② 試合数計算機 UI表示・視認性・アコーディオンレイアウト完全性規約
③ 試合数計算・コート割り振りシミュレーションエンジン完全性規約
"""

import subprocess
import sys

SUB_AUDITS = [
    (
        "① [設計憲法・行数制限] 試合数計算機 イミュータブルモデル・トークン遵守・500行境界規約",
        ["flutter", "test", "test/governance/match_calculator_governance_test.dart"],
    ),
    (
        "② [UI表示・視認性] 試合数計算機 アコーディオン展開・チップ文字色・レイアウト完全性規約",
        ["flutter", "test", "test/widget/match_calculator_display_and_layout_test.dart"],
    ),
    (
        "③ [計算エンジン完全性] 総試合数算出・コート割当・所要時間シミュレーション完全性規約",
        ["flutter", "test", "test/unit/match_allocation_engine_test.dart"],
    ),
]

def main():
    print("=" * 68)
    print(" 📊 【第18条 ガバナンス監査】🧮 試合数計算・コート配分シミュレーション ＆ 部内戦ドック品質規約")
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
        print(" 🟢 監査結果: 合格 (試合数計算・コート配分シミュレーション ＆ 部内戦ドック品質規約に完全適合！)")
        print("=" * 68)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (第18条 試合数計算・コート配分シミュレーション ＆ 部内戦ドック品質規約に違反があります)")
        print("=" * 68)
        sys.exit(1)

if __name__ == "__main__":
    main()
