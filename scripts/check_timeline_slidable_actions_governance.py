#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - タイムラインスワイプアクション3要素（次戦追加・編集・削除）完全保証ガバナンス
================================================================================
タイムライン上の試合カード（団体戦グループカード・個人戦/形カード）において、
スワイプ操作（Slidable）で「次戦追加」「編集」「削除」の3アクションが
欠落なく実装され、extentRatio が適切に設定されていることを静的検証する。
"""

import sys
from pathlib import Path

TARGET_FILES = [
    "lib/features/tournament/presentation/operate/components/timeline/timeline_match_group_card.dart",
    "lib/features/tournament/presentation/operate/components/timeline/timeline_individual_player_card.dart",
]

REQUIRED_ACTIONS = [
    ("次戦追加", "QuickNextMatchWizardSheet"),
    ("編集", "MatchEditSheet"),
    ("削除", "deleteMatchesBulk"),
]


def audit_file(file_path: Path) -> list:
    errors = []
    if not file_path.exists():
        return [f"対象ファイルが存在しません: {file_path}"]

    content = file_path.read_text(encoding="utf-8")

    # 1. Slidable と ActionPane の存在確認
    if "Slidable(" not in content or "ActionPane(" not in content:
        return [f"{file_path.name}: Slidable または ActionPane が実装されていません"]

    # 2. 3要素の存在確認
    for label, identifier in REQUIRED_ACTIONS:
        has_label = f"'{label}'" in content or f'"{label}"' in content
        has_id = identifier in content
        if not (has_label and has_id):
            errors.append(
                f"{file_path.name}: スワイプ必須アクション「{label}」（識別子: {identifier}）が実装されていません"
            )

    # 3. 3アクション展開比率（0.68）の存在確認
    if "0.68" not in content:
        errors.append(
            f"{file_path.name}: 3アクション展開比率 (extentRatio: 0.68) が設定されていません"
        )

    return errors


def main():
    repo_root = Path(__file__).resolve().parent.parent
    all_errors = []

    for rel_path in TARGET_FILES:
        target = repo_root / rel_path
        file_errors = audit_file(target)
        if file_errors:
            all_errors.extend(file_errors)

    if all_errors:
        print("🔴 【規約違反】タイムラインスワイプアクションの整合性エラーを検出:")
        for err in all_errors:
            print(f"  ❌ {err}")
        sys.exit(1)
    else:
        print("🟢 【適合】全タイムラインカードのスワイプ3要素（次戦追加・編集・削除）が完全実装されています！")
        sys.exit(0)


if __name__ == "__main__":
    main()
