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

def check_league_detection_strictness():
    """④ リーグ戦判定・曖昧一致根絶 ＆ メモ・グループ名厳格性保証規約
    
    メモ欄（note）やグループ名（groupName）に含まれる単なる「Bリーグ」等の文字列によって
    通常の団体戦や対抗戦が誤ってリーグ戦（星取表）として扱われないよう、
    コードベース全体で曖昧な部分一致判定（.contains('リーグ')）の再混入を物理的に禁止する。
    """
    import os
    import re

    scanner = GovStaticScanner.get_instance()

    target_dirs = [
        "lib/features/tournament",
        "lib/features/match",
    ]

    # 禁止される曖昧一致パターン (単なる 'リーグ' の部分一致)
    forbidden_regexes = [
        (
            re.compile(r"""note(?:\?|\.toString\(\))?\.contains\(\s*['"]リーグ['"]\s*\)"""),
            "note.contains('リーグ') による曖昧判定は禁止です。'[リーグ戦]' 完全タグまたは matchType で判定してください",
        ),
        (
            re.compile(r"""groupName(?:\?|\.toString\(\))?\.contains\(\s*['"]リーグ['"]\s*\)"""),
            "groupName.contains('リーグ') による曖昧判定は禁止です",
        ),
    ]

    violations = []
    for t_dir in target_dirs:
        for root, _, files in os.walk(t_dir):
            for file in files:
                if not file.endswith(".dart"):
                    continue
                path = os.path.join(root, file)
                content = scanner.read_file(path)
                for pattern, msg in forbidden_regexes:
                    if pattern.search(content):
                        violations.append(f"{path}: {msg}")

    # BunaiksenHelper の必須防護アサーション
    helper_path = "lib/features/tournament/domain/services/bunaiksen_helper.dart"
    helper_content = scanner.read_file(helper_path)
    if "[リーグ戦]" not in helper_content:
        violations.append(f"{helper_path}: [リーグ戦] 完全タグ判定が定義されていません")
    if "isTeamMatch" not in helper_content or "participants.length <= 2" not in helper_content:
        violations.append(f"{helper_path}: 2チーム以下対抗戦の星取表除外セーフティガードが定義されていません")

    if violations:
        return False, "\n".join(f"  ❌ {v}" for v in violations)

    return True, "リーグ判定曖昧一致ゼロ ＆ 厳格タグ判定整合"


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

    # ④ リーグ戦判定・曖昧一致根絶 ＆ メモ・グループ名厳格性保証規約
    l_ok, l_msg = check_league_detection_strictness()
    status_l = "🟢 適合 (Passed)" if l_ok else "🔴 違反 (Failed)"
    print(f" ④ リーグ判定曖昧一致根絶 ＆ メモ厳格性規約: {status_l}")
    if not l_ok:
        all_passed = False
        print(f"    {l_msg}")

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
