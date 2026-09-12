#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ==============================================================================
# 🥋 kendo OS - 【ガバナンス監査 19/19】📱 iOS PWA ステータスバー独立＆ロール選択画面 監査スクリプト
# ==============================================================================
import subprocess
import sys

def run_ios_pwa_touch_sync_governance():
    test_files = [
        "test/unit/web_pwa_touch_sync_governance_test.dart",
        "test/widget/role_select_screen_regression_test.dart",
    ]

    cmd = ["flutter", "test"] + test_files + ["--reporter=expanded"]
    result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    passed_all = (result.returncode == 0)

    rules = [
        ("1. iOS PWAステータスバー独立モード (black / viewport-fit=cover) 保持規約", passed_all),
        ("2. black-translucent起因スクロールフリーズバグ完全排除規約", passed_all),
        ("3. ロール選択画面 全4権限ボタン常時活性化 (Anti-Disable) 規約", passed_all),
        ("4. スワイプバック・Pop画面復帰時 操作性即時維持規約", passed_all),
        ("5. タップ領域 56px確保＆Bounding Box 重複完全排除規約", passed_all),
        ("6. 600ms デバウンス連打防止＆時間経過後受付規約", passed_all),
    ]

    print("=" * 60)
    print(" 📊 【ガバナンス監査 19/19】📱 iOS PWA ステータスバー独立＆ロール選択画面 監査レポート")
    print("=" * 60)

    for label, is_ok in rules:
        status = "🟢 適合 (Passed)" if is_ok else "🔴 違反 (Failed)"
        print(f" {label}: {status}")

    print("-" * 60)
    if passed_all:
        print(" 🟢 監査結果: 合格 (iOS PWAステータスバー独立・ロール選択画面不具合防止に完全適合！)")
        print("=" * 60)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (PWAステータスバーまたはロール選択画面に違反があります)")
        print("=" * 60)
        print("\n🚨 テスト実行エラー:")
        try:
            from test_failure_formatter import parse_and_format_failures
            print(parse_and_format_failures(result.stdout + result.stderr))
        except Exception:
            print(result.stdout + result.stderr)
        sys.exit(1)

if __name__ == "__main__":
    run_ios_pwa_touch_sync_governance()
