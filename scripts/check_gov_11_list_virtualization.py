#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 【第11条 ガバナンス監査】📜 リスト仮想化 ＆ ビューポート描画最適化（一括生成禁止）規約
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
    print(" 📊 【第11条 ガバナンス監査】📜 リスト仮想化 ＆ ビューポート描画最適化（一括生成禁止）規約")
    print("=" * 68)

    cmd = [
        "flutter",
        "test",
        "test/governance/list_virtualization_governance_test.dart",
        "--reporter=expanded",
    ]

    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    is_ok = (res.returncode == 0)

    rules = [
        ("① [選手候補入力仮想化] smart_player_input.dart の ListView.builder 仮想化規約", is_ok),
        ("② [選手一括選択仮想化] multi_player_select_input.dart の ListView.builder 仮想化規約", is_ok),
        ("③ [チーム選手選択仮想化] team_registration_player_select の CustomScrollView + SliverList 規約", is_ok),
        ("④ [オーダー選手選択仮想化] order_setup_player_select の ListView.builder 仮想化規約", is_ok),
    ]

    for label, ok in rules:
        status = "🟢 適合 (Passed)" if ok else "🔴 違反 (Failed)"
        print(f" {label}: {status}")

    print("-" * 68)
    if is_ok:
        print(" 🟢 監査結果: 合格 (リスト仮想化 ＆ ビューポート描画最適化規約に完全適合！)")
        print("=" * 68)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (第11条 リスト仮想化 ＆ ビューポート描画最適化規約に違反があります)")
        print("=" * 68)
        print(res.stdout + res.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
