#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 【第2条 ガバナンス監査】📏 コード品質・行数制限 (Max 500 lines) ＆ アーキテクチャ境界規約
================================================================================
① ファイル行数監査（450行警告 🟡 / 500行上限 🔴 アラート完全維持）
② アーキテクチャ境界＆疎結合規約
③ 新設ファイル・テストペア対生成規約
④ 特定固有名詞(道上・道上剣友会)ハードコード完全禁止規約
"""

import subprocess
import sys

def main():
    print("=" * 68)
    print(" 📊 【第2条 ガバナンス監査】📏 コード品質・行数制限 (Max 500 lines) ＆ アーキテクチャ境界規約")
    print("=" * 68)

    all_passed = True

    # 1. 行数監査 (check_file_lines.py)
    print("▶ ① ファイル行数監査 (450行警告 🟡 / 500行上限 🔴) 実行中...")
    res_lines = subprocess.run(
        ["python3", "scripts/check_file_lines.py"],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    is_lines_ok = (res_lines.returncode == 0)
    print(res_lines.stdout)
    if not is_lines_ok:
        all_passed = False
        print(res_lines.stderr)

    # 2. アーキテクチャ境界
    res_arch = subprocess.run(
        ["python3", "scripts/check_architecture_boundary_governance.py"],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    is_arch_ok = (res_arch.returncode == 0)
    arch_status = "🟢 適合 (Passed)" if is_arch_ok else "🔴 違反 (Failed)"
    print(f" ② アーキテクチャ境界＆疎結合規約: {arch_status}")
    if not is_arch_ok:
        all_passed = False
        print(res_arch.stdout + res_arch.stderr)

    # 3. テストペア対生成
    res_pair = subprocess.run(
        ["python3", "scripts/check_test_pair_governance.py"],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    is_pair_ok = (res_pair.returncode == 0)
    pair_status = "🟢 適合 (Passed)" if is_pair_ok else "🔴 違反 (Failed)"
    print(f" ③ 新設ファイル・テストペア対生成規約: {pair_status}")
    if not is_pair_ok:
        all_passed = False
        print(res_pair.stdout + res_pair.stderr)

    # 4. 特定固有名詞ハードコード禁止規約
    res_names = subprocess.run(
        ["python3", "scripts/check_no_hardcoded_specific_names.py"],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    is_names_ok = (res_names.returncode == 0)
    names_status = "🟢 適合 (Passed)" if is_names_ok else "🔴 違反 (Failed)"
    print(f" ④ 特定固有名詞ハードコード完全禁止規約: {names_status}")
    if not is_names_ok:
        all_passed = False
        print(res_names.stdout + res_names.stderr)

    # 5. BuildContext Mounted Safety (非同期安全) 規約
    res_mounted = subprocess.run(
        ["python3", "scripts/check_mounted_safety_governance.py"],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    is_mounted_ok = (res_mounted.returncode == 0)
    mounted_status = "🟢 適合 (Passed)" if is_mounted_ok else "🔴 違反 (Failed)"
    print(f" ⑤ BuildContext Mounted Safety (非同期安全) 規約: {mounted_status}")
    if not is_mounted_ok:
        all_passed = False
        print(res_mounted.stdout + res_mounted.stderr)

    print("-" * 68)
    if all_passed:
        print(" 🟢 監査結果: 合格 (コード品質・行数制限 ＆ アーキテクチャ境界規約に完全適合！)")
        print("=" * 68)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (第2条 コード品質・行数制限 ＆ アーキテクチャ境界規約に違反があります)")
        print("=" * 68)
        sys.exit(1)

if __name__ == "__main__":
    main()
