#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 【第204条 ガバナンス監査】🛡️ データ入力サニタイズ・CSV/JSONインジェクション防護 ＆ 制御文字排除規約
================================================================================
本監査は、選手名・道場名・チーム名・試合メモ入力における改行コード・制御文字のサニタイズ、
CSVエクスポートにおけるダブルクォート（"）エスケープおよびカンマ分離保護、
HTML/スクリプトインジェクションの無害化を静的整合性およびテスト実行により保証します。
"""

import os
import subprocess
import sys

TARGET_FILES = [
    "lib/shared/application/services/timeline_export_service.dart",
    "test/governance/input_sanitization_governance_test.dart",
]

REQUIRED_PATTERNS = [
    (
        "lib/shared/application/services/timeline_export_service.dart",
        "\\uFEFF",
        "TimelineExportService でUTF-8 BOMの注入が行われていること",
    ),
    (
        "lib/shared/application/services/timeline_export_service.dart",
        "replaceAll('\"', '\"\"')",
        "TimelineExportService でダブルクォートのエスケープが行われていること",
    ),
]

def main():
    print("=" * 68)
    print(" 🛡️ 【第204条 ガバナンス監査】データ入力サニタイズ・CSV/JSONインジェクション防護 ＆ 制御文字排除規約")
    print("=" * 68)

    violations = []

    # 1. 必須ファイルの存在確認
    for path in TARGET_FILES:
        if not os.path.exists(path):
            violations.append(f"❌ 必須ファイルが存在しません: {path}")

    # 2. 必須パターンの検証
    for path, req, desc in REQUIRED_PATTERNS:
        if not os.path.exists(path):
            continue
        with open(path, "r", encoding="utf-8") as f:
            content = f.read()
        if req not in content:
            violations.append(f"❌ {path}: {desc} ('{req}' が見つかりません)")

    # 3. ガバナンステストの実行検証
    test_path = "test/governance/input_sanitization_governance_test.dart"
    if os.path.exists(test_path):
        res = subprocess.run(
            ["flutter", "test", test_path],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
        if res.returncode != 0:
            violations.append(f"❌ {test_path} の実行に失敗しました:\n{res.stdout}\n{res.stderr}")

    if violations:
        print("🔴 違反が検出されました:")
        for v in violations:
            print(f"  {v}")
        print("=" * 68)
        sys.exit(1)
    else:
        print("🟢 監査合格: データ入力サニタイズ・CSV/JSONインジェクション防護 ＆ 制御文字排除規約に完全適合！")
        print("=" * 68)
        sys.exit(0)

if __name__ == "__main__":
    main()
