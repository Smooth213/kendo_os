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

from gov_static_scanner import GovStaticScanner

def check_match_type_parameter_contracts():
    """③ 試合形式6分類パラメータ契約静的整合性検査"""
    scanner = GovStaticScanner.get_instance()
    auto_reg_content = scanner.read_file("lib/features/tournament/domain/share_import/tournament_team_auto_register_service.dart")
    match_rule_content = scanner.read_file("lib/features/match/domain/rules/match_rule.dart")
    match_model_content = scanner.read_file("lib/features/match/domain/match_model.dart")

    expected_keys = [
        '団体戦（5人制）',
        '団体戦（3人制）',
        '個人戦',
        '勝ち抜き戦（5人制）',
        '勝ち抜き戦（3人制）',
        '日本剣道形',
        '木刀による剣道基本技稽古法',
        'リーグ団体戦',
    ]

    for key in expected_keys:
        if key not in auto_reg_content:
            return False, f"allCandidateMatchTypes に '{key}' が定義されていません"

    # match_rule.dart におけるパラメータ定義
    required_rule_fields = [
        "isKataMatch",
        "hasHantei",
        "isKachinuki",
        "positions",
        "isLeague",
        "isIpponShobu",
    ]
    for field in required_rule_fields:
        if field not in match_rule_content:
            return False, f"match_rule.dart に '{field}' が定義されていません"

    return True, "全試合形式パラメータ契約が整合"

SUB_AUDITS = [
    (
        "① 全試合形式・共通セレクタ統一 ＆ 旧式チップ根絶規約",
        ["python3", "scripts/check_match_type_selection_governance.py"],
    ),
    (
        "② 勝ち抜き戦（5人制/3人制）選択・適応・実行 総合保証規約",
        ["python3", "scripts/check_kachinuki_governance.py"],
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

    # ③ 試合形式6分類パラメータ契約直接静的検証
    p_ok, p_msg = check_match_type_parameter_contracts()
    status_p = "🟢 適合 (Passed)" if p_ok else "🔴 違反 (Failed)"
    print(f" ③ 試合形式6分類パラメータ契約静的整合性規約: {status_p}")
    if not p_ok:
        all_passed = False
        print(f"    ❌ {p_msg}")

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
