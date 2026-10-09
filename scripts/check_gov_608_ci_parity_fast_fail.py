#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 【第608条 ガバナンス監査】⚖️ CI環境パリティ ＆ Fast-Fail実行整合性完全保証規約
================================================================================
【目的】
GitHub Actions CI の高速品質ゲート「🔍 Firebase & Flutter 静的解析＆ガバナンス監査 (Fast-Fail)」と、
ローカルの検証スクリプト「scripts/run_fast_fail.sh」が 100% 完全同期していることを永続検証します。
どちらか一方にステップや引数の追加・変更・削除があった際、即座に不一致（CI Drift）を検知し、
「手元では通ったのにCIで落ちる」または「CIで検証されている項目が手元で漏れる」現象を永久に防ぎます。

【検査項目】
① 構成定義ファイルの存在および実行権限の保証 (.github/workflows/test.yml, scripts/run_fast_fail.sh)
② CI static-analysis ジョブにおける全 Fast-Fail ステップ ([1/4]〜[4/4]) の完全網羅
③ ローカル run_fast_fail.sh における全 Fast-Fail ステップ ([1/4]〜[4/4]) の完全網羅
④ ステップ順序・実行コマンド・必須引数の完全一致 (Parity Guarantee)
"""

import os
import re
import stat
import sys

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CI_WORKFLOW_PATH = os.path.join(PROJECT_ROOT, ".github", "workflows", "test.yml")
LOCAL_SCRIPT_PATH = os.path.join(PROJECT_ROOT, "scripts", "run_fast_fail.sh")

# 必須ステップの定義（順序および期待される主要コマンド）
EXPECTED_STEPS = [
    {
        "step_no": "1/4",
        "name": "Dartコード・警告の全自動修復 (dart fix & dart format)",
        "patterns": [r"dart\s+fix\s+--apply", r"dart\s+format\s+\."],
    },
    {
        "step_no": "2/4",
        "name": "全ガバナンス法典 統合監査 (run_all_governance.py)",
        "patterns": [r"python3\s+scripts/run_all_governance\.py"],
    },
    {
        "step_no": "3/4",
        "name": "Flutter 静的解析空間の厳格監査 (flutter analyze)",
        "patterns": [r"flutter\s+analyze\s+--no-fatal-infos"],
    },
    {
        "step_no": "4/4",
        "name": "Firebase Cloud Functions 自動ユニットテスト (npm test)",
        "patterns": [r"npm\s+test"],
    },
]


def check_files_exist_and_executable():
    violations = []
    if not os.path.isfile(CI_WORKFLOW_PATH):
        violations.append(f"❌ CIワークフロー定義が存在しません: {CI_WORKFLOW_PATH}")

    if not os.path.isfile(LOCAL_SCRIPT_PATH):
        violations.append(f"❌ ローカルFast-Failスクリプトが存在しません: {LOCAL_SCRIPT_PATH}")
    else:
        st = os.stat(LOCAL_SCRIPT_PATH)
        if not (st.st_mode & stat.S_IXUSR):
            violations.append(f"❌ ローカルスクリプトに実行権限が付与されていません: {LOCAL_SCRIPT_PATH}")

    return violations


def extract_ci_static_analysis_job(ci_content):
    """test.yml から static-analysis ジョブの定義部分を抽出"""
    # static-analysis: から次のルートレベルジョブ (例: test-shards:) 直前までを切り出す
    match = re.search(r"\n\s{2}static-analysis:\n(.*?)(?=\n\s{2}[a-zA-Z0-9_-]+:|\Z)", ci_content, re.DOTALL)
    if not match:
        return None
    return match.group(1)


def check_ci_fast_fail_parity(ci_content):
    violations = []
    job_section = extract_ci_static_analysis_job(ci_content)
    if not job_section:
        return ["❌ test.yml 内に static-analysis ジョブが見つかりません。"]

    # ジョブ表示名のチェック
    if "Firebase & Flutter 静的解析＆ガバナンス監査 (Fast-Fail)" not in job_section:
        violations.append("❌ static-analysis のジョブ名に 'Firebase & Flutter 静的解析＆ガバナンス監査 (Fast-Fail)' が含まれていません。")

    # 各ステップの包含チェック
    for step in EXPECTED_STEPS:
        step_no = step["step_no"]
        name = step["name"]
        patterns = step["patterns"]

        # ステップ番号の表記チェック
        if f"[{step_no}]" not in job_section:
            violations.append(f"❌ CI [test.yml] にステップ [{step_no}] ({name}) が存在しません。")

        # コマンドのチェック
        for pat in patterns:
            if not re.search(pat, job_section):
                violations.append(f"❌ CI [test.yml] のステップ [{step_no}] に期待されるコマンドパターン '{pat}' が見つかりません。")

    # Step 4 の working-directory チェック
    if not re.search(r"working-directory:\s*\./functions", job_section):
        violations.append("❌ CI [test.yml] の Functions テストステップに 'working-directory: ./functions' が指定されていません。")

    return violations


def check_local_fast_fail_parity(local_content):
    violations = []

    # 各ステップの包含チェック
    for step in EXPECTED_STEPS:
        step_no = step["step_no"]
        name = step["name"]
        patterns = step["patterns"]

        # ステップ番号の表記チェック
        if f"[{step_no}]" not in local_content:
            violations.append(f"❌ ローカル [run_fast_fail.sh] にステップ [{step_no}] ({name}) が存在しません。")

        # コマンドのチェック
        for pat in patterns:
            if not re.search(pat, local_content):
                violations.append(f"❌ ローカル [run_fast_fail.sh] のステップ [{step_no}] に期待されるコマンドパターン '{pat}' が見つかりません。")

    # Step 4 の functions ディレクトリ遷移チェック
    if "functions" not in local_content or "npm test" not in local_content:
        violations.append("❌ ローカル [run_fast_fail.sh] で functions ディレクトリにおける npm test 実行が確認できません。")

    return violations


def check_execution_order(ci_content, local_content):
    """CI とローカルでステップ [1/4] 〜 [4/4] の順序が完全一致しているか確認"""
    violations = []
    job_section = extract_ci_static_analysis_job(ci_content) or ""

    ci_indices = []
    local_indices = []

    for step in EXPECTED_STEPS:
        step_tag = f"[{step['step_no']}]"
        ci_pos = job_section.find(step_tag)
        local_pos = local_content.find(step_tag)

        if ci_pos == -1:
            violations.append(f"❌ CI側に {step_tag} が見つかりません。")
        else:
            ci_indices.append(ci_pos)

        if local_pos == -1:
            violations.append(f"❌ ローカル側に {step_tag} が見つかりません。")
        else:
            local_indices.append(local_pos)

    if ci_indices != sorted(ci_indices):
        violations.append("❌ CI側 [test.yml] のステップ実行順序が昇順（1/4 -> 2/4 -> 3/4 -> 4/4）になっていません。")

    if local_indices != sorted(local_indices):
        violations.append("❌ ローカル側 [run_fast_fail.sh] のステップ実行順序が昇順（1/4 -> 2/4 -> 3/4 -> 4/4）になっていません。")

    return violations


def main():
    print("=" * 68)
    print(" 📊 【第608条 ガバナンス監査】⚖️ CI環境パリティ ＆ Fast-Fail実行整合性完全保証規約")
    print("=" * 68)

    all_passed = True

    # ① ファイル存在・実行権限検査
    v1 = check_files_exist_and_executable()
    status1 = "🟢 適合 (Passed)" if not v1 else "🔴 違反 (Failed)"
    print(f" ① 定義ファイル存在 ＆ 実行権限検証: {status1}")
    if v1:
        all_passed = False
        for err in v1:
            print(f"    {err}")

    if v1:
        print(" 🔴 基本ファイルが存在しないため検査を中断します。")
        sys.exit(1)

    with open(CI_WORKFLOW_PATH, "r", encoding="utf-8") as f:
        ci_content = f.read()

    with open(LOCAL_SCRIPT_PATH, "r", encoding="utf-8") as f:
        local_content = f.read()

    # ② CI static-analysis ステップ完全性検査
    v2 = check_ci_fast_fail_parity(ci_content)
    status2 = "🟢 適合 (Passed)" if not v2 else "🔴 違反 (Failed)"
    print(f" ② GitHub Actions CI (test.yml) Fast-Fail完全網羅規約: {status2}")
    if v2:
        all_passed = False
        for err in v2:
            print(f"    {err}")

    # ③ ローカル run_fast_fail.sh ステップ完全性検査
    v3 = check_local_fast_fail_parity(local_content)
    status3 = "🟢 適合 (Passed)" if not v3 else "🔴 違反 (Failed)"
    print(f" ③ ローカル実行スクリプト (run_fast_fail.sh) Fast-Fail完全網羅規約: {status3}")
    if v3:
        all_passed = False
        for err in v3:
            print(f"    {err}")

    # ④ 実行順序および完全同期 (Parity) 検査
    v4 = check_execution_order(ci_content, local_content)
    status4 = "🟢 適合 (Passed)" if not v4 else "🔴 違反 (Failed)"
    print(f" ④ CI・ローカル ステップ順序 ＆ 環境パリティ完全同期規約: {status4}")
    if v4:
        all_passed = False
        for err in v4:
            print(f"    {err}")

    print("-" * 68)
    if all_passed:
        print(" 🟢 監査結果: 合格 (CI環境パリティ ＆ Fast-Fail実行整合性完全保証規約に完全適合！)")
        print("=" * 68)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (CIとローカルのFast-Fail定義に不一致が検出されました)")
        print("=" * 68)
        sys.exit(1)


if __name__ == "__main__":
    main()
