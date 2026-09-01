#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ==============================================================================
# 🥋 kendo OS - 【ガバナンス監査 7/10】🏰 UIレイアウト 5段構造永続保持 監査スクリプト
# ==============================================================================
import subprocess
import sys

def run_layout_governance():
    cmd = [
        "flutter", "test",
        "test/widget/five_tier_layout_preservation_test.dart",
        "test/widget/team_status_card_5tier_layout_test.dart",
        "test/widget/individual_player_card_5tier_layout_test.dart",
        "test/widget/league_matchup_header_unification_test.dart",
        "--reporter=expanded"
    ]
    result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    output = result.stdout + result.stderr
    passed_all = (result.returncode == 0)

    rules = [
        ("1. 大会ホーム親アコーディオン 5段構造レイアウト永続保持", "大会ホーム＆チーム試合状況 5段構造レイアウト"),
        ("2. チーム試合状況カード 1段目〜5段目・LIVEバッジ保持", "チーム試合状況カード5段構造テスト"),
        ("3. 個人戦カード 5段構造レイアウト ＆ 統一バッジ保持", "個人戦カード 5段構造レイアウト"),
        ("4. リーグ戦ヘッダー 統一バッジ ＆ 26pxボタンスタイル保持", "リーグ戦ヘッダー 統一バッジ ＆ 26pxボタン"),
    ]

    print("=" * 60)
    print(" 📊 【ガバナンス監査 7/10】🏰 UIレイアウト 5段構造永続保持 監査レポート")
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
        print(" 🟢 監査結果: 合格 (UIレイアウト5段構造が完全に維持されています！)")
        print("=" * 60)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (UIレイアウト5段構造に崩れが検出されました)")
        print("=" * 60)
        from test_failure_formatter import parse_and_format_failures
        print(parse_and_format_failures(output))
        sys.exit(1)

if __name__ == "__main__":
    run_layout_governance()
