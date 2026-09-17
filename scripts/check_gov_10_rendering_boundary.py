#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 【第10条 ガバナンス監査】🎨 レンダリング負荷隔離 ＆ RepaintBoundary最適化規約
================================================================================
① 打突ボタンの RepaintBoundary ＆ 先行触覚ゼロ遅延
② スコア操作パネルの RepaintBoundary
③ タイムラインチームカードの描画隔離
④ 観戦画面の RepaintBoundary ＆ ViewerTeamGroupingHelper
⑤ 試合画面 LiquidBackground 静止モード（毎フレーム再描画ゼロ）
⑥ カード/リストアイテムの Viewport 描画隔離
"""

import subprocess
import sys

def main():
    print("=" * 68)
    print(" 📊 【第10条 ガバナンス監査】🎨 レンダリング負荷隔離 ＆ RepaintBoundary最適化規約")
    print("=" * 68)

    cmd = [
        "flutter",
        "test",
        "test/governance/rendering_boundary_governance_test.dart",
        "--reporter=expanded",
    ]

    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    is_ok = (res.returncode == 0)

    rules = [
        ("① [打突ボタン隔離] action_buttons.dart の RepaintBoundary 配置＆先行触覚ゼロ遅延規約", is_ok),
        ("② [操作パネル隔離] match_score_action_section.dart ＆ match_screen.dart の RepaintBoundary 規約", is_ok),
        ("③ [タイムライン隔離] match_timeline_list.dart のチームカード RepaintBoundary 規約", is_ok),
        ("④ [観戦画面隔離] viewer_category_section_list.dart の RepaintBoundary ＆ ヘルパー分離規約", is_ok),
        ("⑤ [背景静止モード] match_screen.dart の LiquidBackground 静止描画（isAnimated: false）規約", is_ok),
        ("⑥ [ビューポート隔離] トーナメント表・スコアテーブル・ドックシート RepaintBoundary 規約", is_ok),
    ]

    for label, ok in rules:
        status = "🟢 適合 (Passed)" if ok else "🔴 違反 (Failed)"
        print(f" {label}: {status}")

    print("-" * 68)
    if is_ok:
        print(" 🟢 監査結果: 合格 (レンダリング負荷隔離 ＆ RepaintBoundary最適化規約に完全適合！)")
        print("=" * 68)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (第10条 レンダリング負荷隔離 ＆ RepaintBoundary最適化規約に違反があります)")
        print("=" * 68)
        print(res.stdout + res.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
