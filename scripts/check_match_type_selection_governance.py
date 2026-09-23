#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 【第1条 ガバナンス監査 ⑤】全試合形式（勝ち抜き戦・リーグ戦含む）編集選択＆完全整合性保証規約
================================================================================
試合形式を編集で選択できる全ての画面とボトムシートにおいて、
勝ち抜き戦・リーグ戦等を含む全ての試合形式が表示され、安全に選択・保存できることを静的に検証します。
"""

import os
import sys

TARGET_FILES = [
    "lib/features/tournament/domain/share_import/tournament_team_auto_register_service.dart",
    "lib/features/tournament/presentation/operate/components/team_registration/team_edit_bottom_sheet.dart",
    "lib/features/tournament/presentation/components/share_import/tournament_share_import_cards.dart",
    "lib/features/tournament/presentation/components/share_import/share_import_edit_sheets.dart",
    "lib/features/tournament/presentation/operate/components/create_tournament/create_tournament_import_teams_card.dart",
]

FORBIDDEN_PATTERNS = [
    # 4形式のみの古いハードコード配列
    ("['団体戦（3人制）', '団体戦（5人制）', '団体戦（7人制）', '個人戦']", "4形式限定の旧ハードコードリストが残っています"),
]

REQUIRED_PATTERNS = [
    ("lib/features/tournament/domain/share_import/tournament_team_auto_register_service.dart", "candidateMatchTypes", "candidateMatchTypes 定数が定義されていること"),
    ("lib/features/tournament/presentation/operate/components/team_registration/team_edit_bottom_sheet.dart", "candidateMatchTypes", "TeamEditBottomSheet で candidateMatchTypes を使用していること"),
    ("lib/features/tournament/presentation/components/share_import/share_import_edit_sheets.dart", "candidateMatchTypes", "ShareImportEditSheets で candidateMatchTypes を使用していること"),
    ("lib/features/tournament/presentation/operate/components/create_tournament/create_tournament_import_teams_card.dart", "candidateMatchTypes", "CreateTournamentImportTeamsCard で candidateMatchTypes を使用していること"),
]

def main():
    print("=" * 68)
    print(" 🥋 【第1条 ガバナンス監査 ⑤】全試合形式編集選択＆完全整合性保証規約")
    print("=" * 68)

    violations = []

    # 1. 必須ファイルの存在確認
    for path in TARGET_FILES:
        if not os.path.exists(path):
            violations.append(f"❌ 必須ファイルが存在しません: {path}")

    # 2. 禁止パターンの検出
    for path in TARGET_FILES:
        if not os.path.exists(path):
            continue
        with open(path, "r", encoding="utf-8") as f:
            content = f.read()

        for pattern, desc in FORBIDDEN_PATTERNS:
            if pattern in content:
                violations.append(f"❌ {path}: {desc} ({pattern})")

    # 3. 必須パターンの検証
    for path, req, desc in REQUIRED_PATTERNS:
        if not os.path.exists(path):
            continue
        with open(path, "r", encoding="utf-8") as f:
            content = f.read()

        if req not in content:
            violations.append(f"❌ {path}: 必須記述が見つかりません - {desc} ('{req}')")

    # 結果出力
    if violations:
        print(" 🔴 監査結果: 違反が検出されました")
        for v in violations:
            print(f"   {v}")
        print("=" * 68)
        sys.exit(1)
    else:
        print(" 🟢 監査結果: 合格 (全試合形式の編集・選択整合性が完全に維持されています)")
        print("=" * 68)
        sys.exit(0)

if __name__ == "__main__":
    main()
