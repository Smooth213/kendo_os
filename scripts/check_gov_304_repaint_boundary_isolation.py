#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 【第304条 ガバナンス監査】🎨 レンダリング負荷隔離 ＆ RepaintBoundary最適化規約
================================================================================
① 打突ボタンの RepaintBoundary ＆ 先行触覚ゼロ遅延
② スコア操作パネルの RepaintBoundary
③ タイムラインチームカードの描画隔離
④ 観戦画面の RepaintBoundary ＆ ViewerTeamGroupingHelper
⑤ 試合画面 LiquidBackground 静止モード（毎フレーム再描画ゼロ）
⑥ カード/リストアイテムの Viewport 描画隔離
"""

import os
import sys

script_dir = os.path.dirname(os.path.abspath(__file__))
if script_dir not in sys.path:
    sys.path.insert(0, script_dir)

from gov_static_scanner import get_file_content

def main():
    print("=" * 68)
    print(" 📊 【第304条 ガバナンス監査】🎨 レンダリング負荷隔離 ＆ RepaintBoundary最適化規約")
    print("=" * 68)

    c_action_btn = get_file_content("lib/shared/widgets/action_buttons.dart") or ""
    c_action_panel = get_file_content("lib/features/tournament/presentation/operate/components/match_screen/match_score_action_section.dart") or ""
    c_match_screen = get_file_content("lib/features/tournament/presentation/operate/match_screen.dart") or ""
    c_body_content = get_file_content("lib/features/tournament/presentation/operate/components/match_screen/match_screen_body_content.dart") or ""
    c_timeline = get_file_content("lib/features/tournament/presentation/operate/components/home/match_timeline_list.dart") or ""
    c_viewer_sec = get_file_content("lib/features/viewer/presentation/components/viewer_category_section_list.dart") or ""
    c_tour_list = get_file_content("lib/features/tournament/presentation/operate/screens/tournament_list_screen.dart") or ""
    c_score_table = get_file_content("lib/shared/widgets/match_tables/score_table_card.dart") or ""
    c_indiv_card = get_file_content("lib/shared/widgets/match_tables/individual_list_card.dart") or ""
    c_league_card = get_file_content("lib/shared/widgets/match_tables/league_grid_card.dart") or ""
    c_dock_sheet = get_file_content("lib/features/tournament/presentation/components/program_management/dock_draggable_sheet.dart") or ""

    total_screen = c_match_screen + c_body_content

    # ① 打突ボタン隔離＆先行触覚
    ok1 = (
        "// ⚡ 【Plan 1-1】ボタン単位のRepaintBoundary隔離でGPU再ラスタライズコストを局所化" in c_action_btn
        and "KendoHaptics.scorePoint();" in c_action_btn
        and "KendoHaptics.foulHansoku();" in c_action_btn
    )

    # ② 操作パネル隔離
    ok2 = (
        "// ⚡ 【Plan 1-1】RepaintBoundaryによるアクションパネル全体の再描画境界隔離" in c_action_panel
        and "final timerPart = RepaintBoundary" in total_screen
        and "final scoreboardPart = RepaintBoundary" in total_screen
    )

    # ③ タイムライン隔離
    ok3 = "RepaintBoundary" in c_timeline and "TimelineTeamCard" in c_timeline

    # ④ 観戦画面隔離
    ok4 = (
        "RepaintBoundary(" in c_viewer_sec
        and "ViewerCategorySection" in c_viewer_sec
        and "ViewerTeamGroupingHelper" in c_viewer_sec
    )

    # ⑤ 背景静止モード
    ok5 = "isAnimated: false" in c_match_screen

    # ⑥ ビューポート隔離
    ok6 = (
        "RepaintBoundary" in c_tour_list
        and "RepaintBoundary" in c_score_table
        and "RepaintBoundary" in c_indiv_card
        and "RepaintBoundary" in c_league_card
        and "RepaintBoundary" in c_dock_sheet
    )

    rules = [
        ("① [打突ボタン隔離] action_buttons.dart の RepaintBoundary 配置＆先行触覚ゼロ遅延規約", ok1),
        ("② [操作パネル隔離] match_score_action_section.dart ＆ match_screen.dart の RepaintBoundary 規約", ok2),
        ("③ [タイムライン隔離] match_timeline_list.dart のチームカード RepaintBoundary 規約", ok3),
        ("④ [観戦画面隔離] viewer_category_section_list.dart の RepaintBoundary ＆ ヘルパー分離規約", ok4),
        ("⑤ [背景静止モード] match_screen.dart の LiquidBackground 静止描画（isAnimated: false）規約", ok5),
        ("⑥ [ビューポート隔離] トーナメント表・スコアテーブル・ドックシート RepaintBoundary 規約", ok6),
    ]

    is_ok = all(ok for _, ok in rules)

    for label, ok in rules:
        status = "🟢 適合 (Passed)" if ok else "🔴 違反 (Failed)"
        print(f" {label}: {status}")

    print("-" * 68)
    if is_ok:
        print(" 🟢 監査結果: 合格 (レンダリング負荷隔離 ＆ RepaintBoundary最適化規約に完全適合！)")
        print("=" * 68)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (第304条 レンダリング負荷隔離 ＆ RepaintBoundary最適化規約に違反があります)")
        print("=" * 68)
        print(res.stdout + res.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
