#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 【第5条 第6項 ガバナンス監査】
全ボトムシート キーボード追従・自動全開・入力視認性保証規約
================================================================================
ソフトウェアキーボード表示時に、ボトムシート内の入力欄やツールバーが背面に
隠れてしまう操作破綻を根絶するため、以下の3大規約を静的コード解析により厳密に検証します：

1. 【基盤ボトムシート規約】
   AppBottomSheetContent が MediaQuery.viewInsets.bottom を下部パディングとして
   必ず内包し、showAppBottomSheet のデフォルトが isScrollControlled: true であること。
2. 【ドック式ボトムシート規約】
   DockDraggableSheet がキーボード出現時に自動的に全開（maxChildSize: 0.95）へ
   アニメーション展開すること。
3. 【全ボトムシートページ網羅規約】
   アプリ内に存在するすべてのボトムシート（ドック型・モーダル型・マスタ編集型）が
   キーボード追従構造を持ち、showModalBottomSheet 直接呼び出しがゼロであること。
"""

import os
import sys

ALL_BOTTOM_SHEET_FILES = [
    # ドック型シート
    "lib/features/tournament/presentation/components/program_management/quick_memo_bottom_sheet.dart",
    "lib/features/tournament/presentation/components/program_management/program_bottom_sheet.dart",
    "lib/features/tournament/presentation/components/program_management/manual_bottom_sheet.dart",
    "lib/features/tournament/presentation/components/program_management/dock_timer_bottom_sheet.dart",
    "lib/features/tournament/presentation/components/program_management/dock_items_reorder_bottom_sheet.dart",
    "lib/features/tournament/presentation/components/program_management/viewer_qr_bottom_sheet.dart",
    "lib/features/tournament/presentation/components/bunaiksen/bunaiksen_dock_standings_sheet.dart",
    "lib/features/tournament/presentation/components/bunaiksen/bunaiksen_dock_calendar_sheet.dart",
    "lib/features/tournament/presentation/components/bunaiksen/bunaiksen_dock_matches_sheet.dart",
    "lib/features/tournament/presentation/components/bunaiksen/calculator/bunaiksen_dock_calculator_sheet.dart",
    "lib/features/match/presentation/components/announce_history_bottom_sheet.dart",

    # マスタ編集・登録系シート
    "lib/admin/presentation/components/master_menu_bottom_sheet.dart",
    "lib/admin/presentation/components/master_player_edit_bottom_sheet.dart",
    "lib/admin/presentation/components/master_register_organization_bottom_sheet.dart",
    "lib/admin/presentation/components/master_edit_organization_bottom_sheet.dart",
    "lib/admin/presentation/components/master_team_name_management_sheet.dart",

    # タイムライン・アナウンス・コメント系シート
    "lib/features/tournament/presentation/operate/components/timeline/timeline_unified_announce_dialog.dart",
    "lib/features/tournament/presentation/operate/components/timeline/timeline_edit_comment_dialog.dart",
    "lib/features/tournament/presentation/operate/components/timeline/timeline_rename_team_sheet.dart",

    # チーム登録・選手編集・試合設定系シート
    "lib/features/tournament/presentation/operate/components/team_registration/team_edit_bottom_sheet.dart",
    "lib/features/tournament/presentation/operate/components/team_registration/team_registration_player_select_bottom_sheet.dart",
    "lib/features/tournament/presentation/operate/components/match_screen/match_player_name_edit_bottom_sheet.dart",
    "lib/features/tournament/presentation/operate/components/match_screen/match_share_options_bottom_sheet.dart",
    "lib/features/tournament/presentation/operate/components/match_screen/renseikai_add_next_match_bottom_sheet.dart",
    "lib/features/tournament/presentation/operate/components/bulk_rule_edit_sheet.dart",
    "lib/features/tournament/presentation/operate/components/home/tournament_edit_bottom_sheet.dart",

    # 共有・インポート・設定系シート
    "lib/features/tournament/presentation/components/share_import/tournament_share_import_sheet.dart",
    "lib/features/tournament/presentation/components/share_import/share_import_edit_sheets.dart",
    "lib/features/viewer/presentation/components/viewer_settings_bottom_sheet.dart",
    "lib/shared/widgets/room_join_qr_dialog.dart",
]

def check_base_bottom_sheet():
    target = "lib/shared/widgets/app_bottom_sheet.dart"
    if not os.path.exists(target):
        return False, f"❌ {target} が存在しません"

    with open(target, "r", encoding="utf-8") as f:
        content = f.read()

    if "bool isScrollControlled = true" not in content:
        return False, "❌ showAppBottomSheet のデフォルト isScrollControlled が true に設定されていません"

    if "MediaQuery.of(context).viewInsets.bottom" not in content:
        return False, "❌ AppBottomSheetContent に viewInsets.bottom のパディング追従が設定されていません"

    return True, "🟢 基盤 showAppBottomSheet & AppBottomSheetContent のキーボード追従構造を確認"

def check_dock_draggable_sheet():
    target = "lib/features/tournament/presentation/components/program_management/dock_draggable_sheet.dart"
    if not os.path.exists(target):
        return False, f"❌ {target} が存在しません"

    with open(target, "r", encoding="utf-8") as f:
        content = f.read()

    if "MediaQuery.of(context).viewInsets.bottom > 0" not in content or "_expand()" not in content:
        return False, "❌ DockDraggableSheet にキーボード出現時の自動全開アニメーションが設定されていません"

    return True, "🟢 DockDraggableSheet のキーボード出現時自動全開（maxChildSize）構造を確認"

def check_all_bottom_sheets():
    errors = []
    for path in ALL_BOTTOM_SHEET_FILES:
        if not os.path.exists(path):
            errors.append(f"❌ {path} が存在しません")
            continue

        with open(path, "r", encoding="utf-8") as f:
            content = f.read()

        if "showModalBottomSheet(" in content:
            errors.append(f"❌ {path} で showModalBottomSheet が直接呼び出されています")

        is_dock = "DockDraggableSheet(" in content
        uses_sheet = "showAppBottomSheet(" in content or "AppBottomSheetContent(" in content
        if not (is_dock or uses_sheet):
            errors.append(f"❌ {path} で DockDraggableSheet または showAppBottomSheet が採用されていません")

    if errors:
        return False, "\n".join(errors)
    return True, f"🟢 アプリ内全 {len(ALL_BOTTOM_SHEET_FILES)} 件のボトムシートが規約に完全適合"

def main():
    print("=" * 72)
    print(" 🥋 【第5条 第6項 ガバナンス監査】全ボトムシート キーボード追従・自動全開規約")
    print("=" * 72)

    checks = [
        ("基盤ボトムシート規約", check_base_bottom_sheet),
        ("ドック式ボトムシート自動全開規約", check_dock_draggable_sheet),
        ("全ボトムシートページ網羅規約", check_all_bottom_sheets),
    ]

    all_passed = True
    for name, check_fn in checks:
        passed, msg = check_fn()
        status = "🟢 適合" if passed else "🔴 違反"
        print(f" [{status}] {name}")
        print(f"   {msg}")
        if not passed:
            all_passed = False

    print("=" * 72)
    if all_passed:
        print(" 🎉 第5条 第6項 ガバナンス監査: ALL PASS (完全適合)")
        sys.exit(0)
    else:
        print(" ❌ 第5条 第6項 ガバナンス監査: FAIL (違反があります)")
        sys.exit(1)

if __name__ == "__main__":
    main()
