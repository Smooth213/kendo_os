#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 【第606条 ガバナンス監査】⚡ ガバナンススクリプト静的検査専念 ＆ 二重テスト起動完全禁止規約
================================================================================
【目的】
ガバナンス監査スクリプト（scripts/check_gov_*.py）内で、重厚な Flutter プロセス
（flutter test）を直接サブプロセス起動するアンチパターン（CI・ローカルの二重実行による
極端な速度劣化）を永久に自動防止・検知します。

【検査項目】
① ガバナンススクリプト群における `flutter test` 直接起動の完全排除（ゼロ検知）
② ガバナンステスト契約検証における `scripts/gov_test_helper.py` 正当準拠規約
"""
import glob
import os
import re
import sys

def check_no_direct_flutter_test():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    all_check_scripts = sorted(glob.glob(os.path.join(script_dir, "check_*.py")))

    violations = []
    # 自身（第606条）は除外
    target_scripts = [s for s in all_check_scripts if not s.endswith("check_gov_606_governance_runner_efficiency.py")]

    pattern = re.compile(r'\[\s*["\']flutter["\']\s*,\s*["\']test["\']')

    for s_path in target_scripts:
        file_name = os.path.basename(s_path)
        try:
            with open(s_path, "r", encoding="utf-8") as f:
                for line_idx, line in enumerate(f, 1):
                    if pattern.search(line):
                        violations.append(
                            f"❌ {file_name}:{line_idx} - ガバナンス内で flutter test を直接実行しています (gov_test_helper を使用してください): {line.strip()}"
                        )
        except Exception as e:
            violations.append(f"❌ {file_name} 読み込み失敗: {e}")

    return violations


def check_gov_test_helper_exists():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    helper_path = os.path.join(script_dir, "gov_test_helper.py")
    if not os.path.isfile(helper_path):
        return [f"❌ 必須契約ヘルパーが存在しません: {helper_path}"]
    return []


def main():
    print("=" * 68)
    print(" 📊 【第606条 ガバナンス監査】⚡ ガバナンススクリプト静的検査専念 ＆ 二重テスト起動完全禁止規約")
    print("=" * 68)

    all_passed = True

    # ① 直接起動禁止検査
    v1 = check_no_direct_flutter_test()
    status1 = "🟢 適合 (Passed)" if not v1 else "🔴 違反 (Failed)"
    print(f" ① ガバナンススクリプト群 `flutter test` 直接起動完全排除規約: {status1}")
    if v1:
        all_passed = False
        for err in v1:
            print(f"    {err}")

    # ② ヘルパー存在検査
    v2 = check_gov_test_helper_exists()
    status2 = "🟢 適合 (Passed)" if not v2 else "🔴 違反 (Failed)"
    print(f" ② ガバナンステスト契約ヘルパー (gov_test_helper.py) 整合性規約: {status2}")
    if v2:
        all_passed = False
        for err in v2:
            print(f"    {err}")

    print("-" * 68)
    if all_passed:
        print(" 🟢 監査結果: 合格 (ガバナンススクリプト静的検査専念 ＆ 二重テスト起動完全禁止規約に完全適合！)")
        print("=" * 68)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (ガバナンススクリプト内に flutter test 直接起動アンチパターンが検出されました)")
        print("=" * 68)
        sys.exit(1)


if __name__ == "__main__":
    main()
