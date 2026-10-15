#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 【第107条 ガバナンス監査】🥋 試合形式6分類・勝ち抜き戦・共通セレクタ 総合保証規約
================================================================================
本規約は、Kendo OS の全試合形式（団体戦・個人戦・勝ち抜き戦・剣道形・基本判定・部内戦）において、
① 全画面共通セレクタ統一番 ＆ 旧式フラットチップ完全ゼロ
② 勝ち抜き戦（5人制 / 3人制）の選択・適応・実行ライフサイクル完全保証
③ 試合形式6分類パラメータ契約・Dartガバナンスアサーション完全合格
を静的整合性およびテスト実行により恒久的に保証します。
"""

import subprocess
import sys

SUB_AUDITS = [
    (
        "① 全試合形式・共通セレクタ統一 ＆ 旧式チップ根絶規約",
        ["python3", "scripts/check_match_type_selection_governance.py"],
    ),
    (
        "② 勝ち抜き戦（5人制/3人制）選択・適応・実行 総合保証規約",
        ["python3", "scripts/check_kachinuki_governance.py"],
    ),
    (
        "③ 試合形式6分類パラメータ契約ガバナンステスト",
        [
            "python3",
            "scripts/gov_test_helper.py",
            "test/governance/match_type_parameter_contract_governance_test.dart",
        ],
    ),
]


def main():
    print("=" * 72)
    print(" 📊 【第107条 ガバナンス監査】🥋 試合形式6分類・勝ち抜き戦・共通セレクタ 総合保証規約")
    print("=" * 72)

    all_passed = True
    for label, cmd in SUB_AUDITS:
        res = subprocess.run(
            cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
        )
        is_ok = res.returncode == 0
        status = "🟢 適合 (Passed)" if is_ok else "🔴 違反 (Failed)"
        print(f" {label}: {status}")
        if not is_ok:
            all_passed = False
            print(f"\n--- [詳細エラー: {label}] ---")
            print(res.stdout + res.stderr)
            print("-" * 40)

    print("-" * 72)
    if all_passed:
        print(" 🟢 監査結果: 合格 (第107条 試合形式6分類・勝ち抜き戦規約に完全適合！)")
        print("=" * 72)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (第107条 試合形式6分類・勝ち抜き戦規約に違反があります)")
        print("=" * 72)
        sys.exit(1)


if __name__ == "__main__":
    main()
