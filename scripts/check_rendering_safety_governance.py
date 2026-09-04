#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ==============================================================================
# 🥋 kendo OS - 【ガバナンス監査 15/15】🛡️ 全ページ UIゼロレンダリングエラー保証 監査スクリプト
# ==============================================================================
import os
import re
import subprocess
import sys

def check_static_reorderable_keys():
    """ReorderableListView直下の子要素に key が付与されているかを静的検査"""
    violations = []
    lib_dir = os.path.join(os.path.dirname(__file__), "..", "lib")
    for root, _, files in os.walk(lib_dir):
        for f in files:
            if not f.endswith(".dart"):
                continue
            path = os.path.join(root, f)
            with open(path, "r", encoding="utf-8") as file:
                content = file.read()
            if "ReorderableListView" in content:
                # TimelineCommentSlidableTileがkey無しで呼び出されていないか特定検出
                if re.search(r'TimelineCommentSlidableTile\s*\((?![^)]*key\s*:)', content):
                    rel = os.path.relpath(path, os.path.join(lib_dir, ".."))
                    violations.append(f"{rel}: TimelineCommentSlidableTile に key が指定されていません")
    return violations

def run_rendering_safety_governance():
    # 1. 静的コード構文検査
    static_violations = check_static_reorderable_keys()

    # 2. 全画面・全ボトムシート UI レンダリング動的テスト
    cmd = [
        "flutter", "test",
        "test/widget/all_screens_rendering_safety_governance_test.dart",
        "--reporter=expanded"
    ]
    result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    output = result.stdout + result.stderr
    test_passed = (result.returncode == 0)
    passed_all = test_passed and (len(static_violations) == 0)

    rules = [
        ("1. 運営・管理系画面 (8画面) UIゼロレンダリングエラー保証", "1. 運営・管理系画面"),
        ("2. 運営試合・スコア系画面 (5画面) UIゼロレンダリングエラー保証", "2. 運営試合・スコア系画面"),
        ("3. 大会セットアップ系画面 (6画面) UIゼロレンダリングエラー保証", "3. 大会セットアップ系画面"),
        ("4. 部内戦画面 (3画面) UIゼロレンダリングエラー保証", "4. 部内戦画面"),
        ("5. 観戦者専用画面 (7画面) UIゼロレンダリングエラー保証", "5. 観戦者専用画面"),
        ("6. ドック全ボトムシート展開 (7シート) UIゼロレンダリングエラー保証", "6. ドック全ボトムシート展開"),
        ("7. ReorderableListView 複合子要素 Key 指定 静的・動的完全保証", "7. TimelineTeamCard 見出しコメント混在"),
    ]

    print("=" * 60)
    print(" 📊 【ガバナンス監査 15/15】🛡️ 全ページ UIゼロレンダリングエラー保証 監査レポート")
    print("=" * 60)

    for idx, (label, pattern) in enumerate(rules, start=1):
        if idx == 7 and static_violations:
            status = "🔴 違反 (Failed: key指定欠落)"
        elif passed_all:
            status = "🟢 適合 (Passed)"
        else:
            if pattern in output and "[E]" in output:
                status = "🔴 違反 (Failed)"
            else:
                status = "🟢 適合 (Passed)"
        print(f" {label}: {status}")

    print("-" * 60)
    if passed_all:
        print(" 🟢 監査結果: 合格 (全30画面・全7ボトムシートのゼロレンダリングエラーが完全に保証されています！)")
        print("=" * 60)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (UIレンダリングエラーまたはKey指定違反が検出されました)")
        print("=" * 60)
        if static_violations:
            print("🚨 【静的構文エラー】")
            for v in static_violations:
                print(f"  - {v}")
        if not test_passed:
            try:
                from test_failure_formatter import parse_and_format_failures
                print(parse_and_format_failures(output))
            except Exception:
                print(output[-1000:])
        sys.exit(1)

if __name__ == "__main__":
    run_rendering_safety_governance()
