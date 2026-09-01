#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ==============================================================================
# 🥋 kendo OS - 【ガバナンス監査 8/10】🌓 テーマ視認性・白飛び黒潰れゼロ 監査スクリプト
# ==============================================================================
import subprocess
import sys

def run_contrast_governance():
    cmd = [
        "flutter", "test",
        "test/widget/timer_widget_theme_contrast_test.dart",
        "test/widget/match_status_badge_theme_test.dart",
        "test/widget/large_viewer_scoreboard_visibility_test.dart",
        "test/widget/create_tournament_visibility_test.dart",
        "--reporter=expanded"
    ]
    result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    output = result.stdout + result.stderr
    passed_all = (result.returncode == 0)

    rules = [
        ("1. タイマー ライト＆ダークモード視認性コントラスト完全保証", "TimerWidget ライト＆ダークモード視認性"),
        ("2. 試合状態バッジ（LIVE/待機中/終了）ハイライト視認性", "MatchStatusBadge Visual Distinction"),
        ("3. 観客席ビュアー・スコアボード 暗色背景同化防止", "観客席ビュアー 視認性・コントラスト保証"),
        ("4. 大会作成画面 テキスト色・入力欄背景色衝突ゼロ保証", "大会作成画面 視認性ガードテスト"),
    ]

    print("=" * 60)
    print(" 📊 【ガバナンス監査 8/10】🌓 テーマ視認性・白飛び黒潰れゼロ 監査レポート")
    print("=" * 60)

    for label, pattern in rules:
        if passed_all:
            status = "🟢 適合 (Passed)"
        else:
            if pattern in output and "[E]" in output:
                status = "🔴 違反 (Failed)"
            else:
                status = "🟢 適合 (Passed)"
        print(f" {label}: {status}")

    print("-" * 60)
    if passed_all:
        print(" 🟢 監査結果: 合格 (白飛び・黒潰れゼロの完全コントラストを保証！)")
        print("=" * 60)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (テーマ視認性・コントラストに違反が検出されました)")
        print("=" * 60)
        from test_failure_formatter import parse_and_format_failures
        print(parse_and_format_failures(output))
        sys.exit(1)

if __name__ == "__main__":
    run_contrast_governance()
