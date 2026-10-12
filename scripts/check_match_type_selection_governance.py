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
    "lib/features/tournament/presentation/operate/components/team_registration/team_edit_basic_fields.dart",
    "lib/features/tournament/presentation/components/share_import/tournament_share_import_cards.dart",
    "lib/features/tournament/presentation/components/share_import/share_import_edit_sheets.dart",
    "lib/features/tournament/presentation/components/share_import/category_selection_bottom_sheet.dart",
    "lib/features/tournament/presentation/components/share_import/match_format_selection_bottom_sheet.dart",
    "lib/features/tournament/presentation/operate/components/create_tournament/create_tournament_import_teams_card.dart",
    "lib/features/tournament/presentation/operate/components/team_registration/team_registration_category_step.dart",
    "lib/features/tournament/presentation/operate/components/category_rules/category_rule_editor_header_card.dart",
]

FORBIDDEN_PATTERNS = [
    # 4形式のみの古いハードコード配列
    ("['団体戦（3人制）', '団体戦（5人制）', '団体戦（7人制）', '個人戦']", "4形式限定の旧ハードコードリストが残っています"),
    # 旧「勝ち抜き戦」単体のハードコード選択肢
    ("value: '勝ち抜き戦'", "旧「勝ち抜き戦」単独のDropdownMenuItemが残っています（5人制または3人制に統一してください）"),
    ("'勝ち抜き戦',\n    'リーグ団体戦'", "TeamRegistrationCategoryStep に旧「勝ち抜き戦」単独の選択肢が残っています"),
]

REQUIRED_PATTERNS = [
    ("lib/features/tournament/domain/share_import/tournament_team_auto_register_service.dart", "candidateMatchTypes", "candidateMatchTypes 定数が定義されていること"),
    ("lib/features/tournament/presentation/components/share_import/share_import_edit_sheets.dart", "MatchFormatSelectionBottomSheet", "ShareImportEditSheets で MatchFormatSelectionBottomSheet を使用していること"),
    ("lib/features/tournament/presentation/components/share_import/share_import_edit_sheets.dart", "CategorySelectionBottomSheet", "ShareImportEditSheets で CategorySelectionBottomSheet を使用していること"),
    ("lib/features/tournament/presentation/operate/components/create_tournament/create_tournament_import_teams_card.dart", "MatchFormatSelectionBottomSheet", "CreateTournamentImportTeamsCard で MatchFormatSelectionBottomSheet を使用していること"),
    ("lib/features/tournament/presentation/operate/components/team_registration/team_edit_basic_fields.dart", "MatchFormatSelectorView", "TeamEditBasicFields で MatchFormatSelectorView を使用していること"),
    ("lib/features/tournament/presentation/operate/components/team_registration/team_edit_basic_fields.dart", "CategoryCascadeSelectorView", "TeamEditBasicFields で CategoryCascadeSelectorView を使用していること"),
    ("lib/features/tournament/presentation/components/share_import/match_format_selection_bottom_sheet.dart", "MatchFormatSelectorView", "MatchFormatSelectionBottomSheet で MatchFormatSelectorView を使用していること"),
    ("lib/features/tournament/presentation/components/share_import/category_selection_bottom_sheet.dart", "CategoryCascadeSelectorView", "CategorySelectionBottomSheet で CategoryCascadeSelectorView を使用していること"),
]

def scan_entire_app():
    """アプリ全体（lib/配下の全.dartファイル）から旧式フラットチップ展開を検知・根絶する"""
    violations = []
    
    # 共通セレクタやSSOT定数定義の正規ファイルは除外
    whitelist_files = {
        "lib/features/tournament/presentation/operate/components/common/category_cascade_selector_view.dart",
        "lib/features/tournament/presentation/operate/components/common/match_format_selector_view.dart",
        "lib/features/tournament/domain/share_import/tournament_team_auto_register_service.dart",
    }

    # アプリ全体で禁止される旧式パターン
    global_forbidden_patterns = [
        ("candidateCategories.map(", "旧式フラットなカテゴリチップ展開が残っています（CategoryCascadeSelectorView を使用してください）"),
        ("candidateMatchTypes.map(", "旧式フラットな試合形式チップ展開が残っています（MatchFormatSelectorView または MatchFormatSelectionBottomSheet を使用してください）"),
        ("'全カテゴリから選択...'", "旧式の「全カテゴリから選択...」チップが残っています"),
        ("['団体戦（3人制）', '団体戦（5人制）', '団体戦（7人制）', '個人戦']", "4形式限定の旧ハードコードリストが残っています"),
    ]

    for root, _, files in os.walk("lib"):
        for file in files:
            if not file.endswith(".dart"):
                continue
            path = os.path.join(root, file).replace("\\", "/")
            if path in whitelist_files:
                continue

            with open(path, "r", encoding="utf-8") as f:
                content = f.read()

            for pattern, desc in global_forbidden_patterns:
                if pattern in content:
                    violations.append(f"❌ [アプリ全体監査] {path}: {desc} (検出: {pattern})")

    return violations

def main():
    print("=" * 68)
    print(" 🥋 【第1条 ガバナンス監査 ⑤】全試合形式・カテゴリ共通セレクタ統一番 ＆ アプリ全体旧式フラットチップ根絶規約")
    print("=" * 68)

    violations = []

    # 1. 必須ファイルの存在確認
    for path in TARGET_FILES:
        if not os.path.exists(path):
            violations.append(f"❌ 必須ファイルが存在しません: {path}")

    # 2. 禁止パターンの検出 (TARGET_FILES)
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

    # 4. 【アプリ全体監査】lib/ 配下のすべての Dart ファイルをスキャン
    app_violations = scan_entire_app()
    violations.extend(app_violations)

    # 結果出力
    if violations:
        print(" 🔴 監査結果: 違反が検出されました")
        for v in violations:
            print(f"   {v}")
        print("=" * 68)
        sys.exit(1)
    else:
        print(" 🟢 監査結果: 合格 (アプリ全体において旧式フラットチップは完全ゼロであり、共通セレクタ規約に完全適合しています)")
        print("=" * 68)
        sys.exit(0)

if __name__ == "__main__":
    main()

