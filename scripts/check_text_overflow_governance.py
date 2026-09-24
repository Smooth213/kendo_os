#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ==============================================================================
# 🥋 KendoOS - 【第3条 ガバナンス監査】🔠 フォント拡大時（標準・大・特大）文字切れ・省略（...）完全防止監査
# ==============================================================================
import subprocess
import sys

def run_text_overflow_governance():
    cmd = [
        "flutter", "test",
        "test/governance/text_scale_overflow_governance_test.dart",
        "test/widget/all_screens_text_scale_no_overflow_test.dart",
        "--reporter=expanded"
    ]
    result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    output = result.stdout + result.stderr
    passed_all = (result.returncode == 0)

    rules = [
        ("1. 主要ヘッダー・バナーコンポーネント FittedBox 縮小防護規約", "主要ヘッダー・バナーコンポーネントが FittedBox による縮小防護を備えていること"),
        ("2. AppHeader & DockBottomSheetHeader タイトル動的縮小規約", "AppHeader でのタイトル直書きは禁止され"),
        ("3. 全画面（13画面）全文字サイズ（1.0x / 1.2x / 1.35x）文字切れゼロ規約", "KendoOS 全画面・全サイズ文字切れ＆省略（...）完全防止テスト"),
        ("4. 重要ボトムシート・カード（9種）全文字サイズ 文字切れ・押し出しゼロ規約", "ボトムシート・ドック・重要コンポーネントの文字拡大テスト"),
    ]

    print("=" * 68)
    print(" 📊 【ガバナンス第3条 監査】🔠 文字拡大（標準・大・特大）文字切れ・省略防止レポート")
    print("=" * 68)

    for label, pattern in rules:
        if passed_all:
            status = "🟢 適合 (Passed)"
        else:
            if pattern in output and "[E]" in output:
                status = "🔴 違反 (Failed)"
            else:
                status = "🟢 適合 (Passed)"
        print(f" {label}: {status}")

    print("-" * 68)
    if passed_all:
        print(" 🟢 監査結果: 合格 (全画面・全文字サイズにおいて文字切れ・省略・例外ゼロを保証！)")
        print("=" * 68)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (文字拡大時に文字切れ・省略またはレイアウト例外が検出されました)")
        print("=" * 68)
        from test_failure_formatter import parse_and_format_failures
        print(parse_and_format_failures(output))
        sys.exit(1)

if __name__ == "__main__":
    run_text_overflow_governance()
