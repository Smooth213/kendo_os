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
    "lib/features/tournament/presentation/operate/components/timeline/timeline_league_matchup_tile.dart",
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


def audit_accordion_hierarchy(repo_root: Path) -> list:
    """全試合形式（通常団体戦・団体リーグ戦・個人戦・個人リーグ戦・勝ち抜き戦・形判定）のアコーディオン階層構造を静的検査"""
    errors = []

    # 1. TimelineGroupChildrenBuilder の階層分岐検査
    children_builder_path = (
        repo_root
        / "lib/features/tournament/presentation/operate/components/timeline/timeline_group_children_builder.dart"
    )
    if not children_builder_path.exists():
        return [f"TimelineGroupChildrenBuilder が見つかりません: {children_builder_path}"]

    builder_content = children_builder_path.read_text(encoding="utf-8")

    # (a) 団体リーグ戦（3階層：親 ➔ TimelineLeagueMatchupTile ➔ 各オーダー）の存在確認
    if "TimelineLeagueMatchupTile" not in builder_content:
        errors.append(
            "timeline_group_children_builder.dart: 団体リーグ戦用の対戦カード（TimelineLeagueMatchupTile）へのグルーピングが実装されていません"
        )

    # (b) 個人戦・個人リーグ戦の直接展開分岐の確認
    if "label.contains('個人戦')" not in builder_content:
        errors.append(
            "timeline_group_children_builder.dart: 個人戦・リーグ個人戦の直接展開判定（label.contains('個人戦')）が欠落しています"
        )

    # (c) 通常団体戦・勝ち抜き戦・形判定の直下展開の確認
    if "MatchListTileCard" not in builder_content:
        errors.append(
            "timeline_group_children_builder.dart: 通常団体戦・勝ち抜き戦・形判定の個別試合カード（MatchListTileCard）展開が欠落しています"
        )

    # 2. 親カードのスワイプ排他制御検査
    group_card_path = (
        repo_root
        / "lib/features/tournament/presentation/operate/components/timeline/timeline_match_group_card.dart"
    )
    if group_card_path.exists():
        group_content = group_card_path.read_text(encoding="utf-8")
        if "label.contains('リーグ戦')" not in group_content and "isLeague" not in group_content:
            errors.append(
                "timeline_match_group_card.dart: リーグ戦時の全試合巻き込み防止（親カードのスワイプ排他制御）が実装されていません"
            )

    # 3. 4段目サマリー帯ボックス（TimelineLeagueStatusSection）の組み込み確認
    header_path = (
        repo_root
        / "lib/features/tournament/presentation/operate/components/timeline/timeline_group_header.dart"
    )
    if header_path.exists():
        header_content = header_path.read_text(encoding="utf-8")
        if "TimelineLeagueStatusSection" not in header_content:
            errors.append(
                "timeline_group_header.dart: リーグ戦親アコーディオンの4段目進行サマリー帯ボックス（TimelineLeagueStatusSection）が組み込まれていません"
            )

    return errors


def main():
    repo_root = Path(__file__).resolve().parent.parent
    all_errors = []

    # 1. 全カードのスワイプ3要素検査
    for rel_path in TARGET_FILES:
        target = repo_root / rel_path
        file_errors = audit_file(target)
        if file_errors:
            all_errors.extend(file_errors)

    # 2. 全試合形式アコーディオン階層構造検査
    hierarchy_errors = audit_accordion_hierarchy(repo_root)
    if hierarchy_errors:
        all_errors.extend(hierarchy_errors)

    if all_errors:
        print("🔴 【規約違反】タイムラインスワイプアクション ＆ アコーディオン階層の整合性エラーを検出:")
        for err in all_errors:
            print(f"  ❌ {err}")
        sys.exit(1)
    else:
        print("🟢 【適合】全試合形式のアコーディオン階層整合性 ＆ スワイプ3要素（次戦追加・編集・削除）が完全保証されています！")
        sys.exit(0)


if __name__ == "__main__":
    main()
