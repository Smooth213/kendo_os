#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 【第305条 ガバナンス監査】📜 リスト仮想化 ＆ ビューポート描画最適化（一括生成禁止）規約
================================================================================
① 選手候補入力（smart_player_input.dart）の ListView.builder 仮想化
② 選手一括選択入力（multi_player_select_input.dart）の ListView.builder 仮想化
③ チーム選手選択の CustomScrollView + SliverList.builder
④ オーダー選手選択の ListView.builder
※非仮想化 ListView(children: [...]) の完全撤廃
"""

import subprocess
import sys

def main():
    print("=" * 68)
    print(" 📊 【第305条 ガバナンス監査】📜 リスト仮想化 ＆ ビューポート描画最適化（一括生成禁止）規約")
    print("=" * 68)

    import os
    import re
    import sys

    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(script_dir)

    def read_file(rel):
        full = os.path.join(project_root, rel)
        if not os.path.isfile(full):
            return ""
        with open(full, "r", encoding="utf-8") as f:
            return f.read()

    c1 = read_file("lib/shared/widgets/smart_player_input.dart")
    c2 = read_file("lib/shared/widgets/multi_player_select_input.dart")
    c3 = read_file("lib/features/tournament/presentation/operate/components/team_registration/team_registration_player_select_bottom_sheet.dart")
    c4 = read_file("lib/features/tournament/presentation/operate/components/order_setup/order_setup_player_select_bottom_sheet.dart")
    c5 = read_file("lib/features/tournament/presentation/operate/official_record_screen.dart")
    c6 = read_file("lib/features/viewer/screens/viewer_official_record_screen.dart")

    unvirtual_regex = re.compile(r"child:\s*ListView\(\s*children:\s*\[")

    r1 = ("ListView.builder(" in c1 and not unvirtual_regex.search(c1))
    r2 = ("ListView.builder(" in c2 and not unvirtual_regex.search(c2))
    r3 = ("CustomScrollView(" in c3 and "SliverList.builder(" in c3 and not unvirtual_regex.search(c3))
    r4 = ("ListView.builder(" in c4 and not unvirtual_regex.search(c4))
    r5 = ("shrinkWrap: true" not in c5 and "shrinkWrap: true" not in c6)

    rules = [
        ("① [選手候補入力仮想化] smart_player_input.dart の ListView.builder 仮想化規約", r1),
        ("② [選手一括選択仮想化] multi_player_select_input.dart の ListView.builder 仮想化規約", r2),
        ("③ [チーム選手選択仮想化] team_registration_player_select の CustomScrollView + SliverList 規約", r3),
        ("④ [オーダー選手選択仮想化] order_setup_player_select の ListView.builder 仮想化規約", r4),
        ("⑤ [公式記録仮想化保護] official_record_screen ＆ viewer 画面の shrinkWrap: true 排除規約", r5),
    ]

    all_passed = True
    for label, ok in rules:
        status = "🟢 適合 (Passed)" if ok else "🔴 違反 (Failed)"
        print(f" {label}: {status}")
        if not ok:
            all_passed = False

    print("-" * 68)
    if all_passed:
        print(" 🟢 監査結果: 合格 (リスト仮想化 ＆ ビューポート描画最適化規約に完全適合！)")
        print("=" * 68)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (第305条 リスト仮想化 ＆ ビューポート描画最適化規約に違反があります)")
        print("=" * 68)
        sys.exit(1)

if __name__ == "__main__":
    main()
