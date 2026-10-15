#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 【第207条 ガバナンス監査】🗄️ 永続化モデル・スキーママイグレーション＆フォールバック安全性規約
================================================================================
本規約は、MatchModel, MatchRule などの主要ドメインモデルにおいて、
① 新フィールド追加時や旧スキーマJSON読み込み時における未定義キー・欠落キーのフォールバック安全性
② Isar / キャッシュ復元時のゼロクラッシュ
③ Dartガバナンステストによるスキーママイグレーション検証
を静的ソース検査およびテスト実行により保証します。
"""

import os
import subprocess
import sys

TARGET_FILES = [
    "lib/features/match/domain/match_model.dart",
    "lib/features/match/domain/rules/match_rule.dart",
]


def check_source_patterns():
    for fpath in TARGET_FILES:
        if not os.path.exists(fpath):
            print(f"🔴 ファイルが存在しません: {fpath}")
            return False
        with open(fpath, "r", encoding="utf-8") as f:
            content = f.read()
            if "fromJson" not in content:
                print(f"🔴 fromJson が未実装です: {fpath}")
                return False
    return True


def main():
    print("=" * 72)
    print(" 📊 【第207条 ガバナンス監査】🗄️ 永続化モデル・スキーママイグレーション規約")
    print("=" * 72)

    # 1. 静的パターン検査
    if not check_source_patterns():
        sys.exit(1)
    print(" 🟢 静的検査: MatchModel, MatchRule の fromJson 契約適合")

    # 2. ガバナンステスト実行
    cmd = [
        "python3",
        "scripts/gov_test_helper.py",
        "test/governance/schema_fallback_safety_governance_test.dart",
    ]
    res = subprocess.run(
        cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
    )
    is_ok = res.returncode == 0

    if is_ok:
        print(" 🟢 適合 (Passed): スキーマフォールバック安全性テストに合格しました。")
        print("=" * 72)
        print(" 🟢 監査結果: 合格 (第207条 スキーママイグレーション規約に完全適合！)")
        print("=" * 72)
        sys.exit(0)
    else:
        print(" 🔴 違反 (Failed): スキーマフォールバックテストでエラーが発生しました。")
        print(res.stdout + res.stderr)
        print("=" * 72)
        print(" 🔴 監査結果: 違反 (第207条 スキーママイグレーション規約に違反があります)")
        print("=" * 72)
        sys.exit(1)


if __name__ == "__main__":
    main()
