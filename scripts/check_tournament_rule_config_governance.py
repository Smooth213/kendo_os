#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 【第1条 ガバナンス監査 ⑦】大会ルール設定バリデーション ＆ ルール永続化マイグレーション規約
================================================================================
1. RuleConfigValidator による試合時間・延長時間・勝ち抜き設定の矛盾排除
2. RuleSerializer による新旧スキーマバージョン互換性と破損JSONフォールバック
3. RuleResolver による動的ルールDI生成
の静的整合性およびテスト実行により保証します。
"""

import os
import subprocess
import sys

TARGET_FILES = [
    "lib/features/match/domain/rules/rule_config_validator.dart",
    "lib/features/match/domain/rules/rule_serializer.dart",
    "lib/features/match/domain/rules/rule_factory.dart",
    "test/governance/tournament_rule_config_governance_test.dart",
]

REQUIRED_PATTERNS = [
    (
        "lib/features/match/domain/rules/rule_config_validator.dart",
        "matchTimeMinutes <= 0",
        "RuleConfigValidator で試合時間0分以下の検証が行われていること",
    ),
    (
        "lib/features/match/domain/rules/rule_config_validator.dart",
        "kachinukiUnlimitedType == '大将引き分け延長'",
        "RuleConfigValidator で大将引き分け延長時の整合性検証が行われていること",
    ),
    (
        "lib/features/match/domain/rules/rule_serializer.dart",
        "containsKey('schemaVersion')",
        "RuleSerializer で新旧スキーマのマイグレーション判定が行われていること",
    ),
    (
        "lib/features/match/domain/rules/rule_factory.dart",
        "class RuleResolver",
        "RuleResolver による動的DIが行われていること",
    ),
]

def main():
    print("=" * 68)
    print(" 🥋 【第1条 ガバナンス監査 ⑦】大会ルール設定バリデーション ＆ ルール永続化マイグレーション規約")
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
    test_path = "test/governance/tournament_rule_config_governance_test.dart"
    if os.path.exists(test_path):
        res = subprocess.run(
            ["python3", "scripts/gov_test_helper.py", test_path],
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
        print("🟢 監査合格: 大会ルール設定バリデーション ＆ ルール永続化マイグレーション規約に完全適合！")
        print("=" * 68)
        sys.exit(0)

if __name__ == "__main__":
    main()
