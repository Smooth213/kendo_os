#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ==============================================================================
# 🥋 kendo OS - 【ガバナンス監査 24/24】⚡ UIレスポンス高速化・局所再描画・非同期バックオフ 永続保証規約 監査スクリプト
# ==============================================================================
import subprocess
import sys

def run_ui_performance_governance():
    test_files = [
        "test/governance/plan1_ui_performance_governance_test.dart",
    ]

    cmd = ["flutter", "test"] + test_files + ["--reporter=expanded"]
    result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    passed_all = (result.returncode == 0)

    rules = [
        ("1. [ブロッキング禁止] sync_engine.dart の Future.delayed スレッドロック再混入完全禁止規約", passed_all),
        ("2. [非同期バックオフ] _nextAttemptAt タイムスタンプ管理および resetBackoffAndProcess 配備規約", passed_all),
        ("3. [Isolateオフロード] pdf_service.dart の compute 経由PDF生成＆UIフリーズ完全撲滅規約", passed_all),
        ("4. [生フォントバイト] pdf_font_loader.dart の loadFontBytes ＆ バイトキャッシュ配備規約", passed_all),
        ("5. [O(1)パス直結] scoreboard.dart の階層パス直接監視優先＆collectionGroup回避規約", passed_all),
        ("6. [画像ダウンサンプリング] プログラムサムネイル＆ビューアの cacheWidth/cacheHeight 規約", passed_all),
        ("7. [局所再描画] match_screen.dart の singleMatchProvider ＆ RepaintBoundary 配備規約", passed_all),
    ]

    print("=" * 60)
    print(" 📊 【ガバナンス監査 24/24】⚡ UIレスポンス高速化・局所再描画・非同期バックオフ 永続保証 監査レポート")
    print("=" * 60)

    for label, is_ok in rules:
        status = "🟢 適合 (Passed)" if is_ok else "🔴 違反 (Failed)"
        print(f" {label}: {status}")

    print("-" * 60)
    if passed_all:
        print(" 🟢 監査結果: 合格 (UIレスポンス向上・局所再描画・非同期バックオフ規約に完全適合！)")
        print("=" * 60)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (UIパフォーマンス・サクサク化ガバナンスに規約違反があります)")
        print("=" * 60)
        print("\n🚨 テスト実行エラー:")
        try:
            from test_failure_formatter import parse_and_format_failures
            print(parse_and_format_failures(result.stdout + result.stderr))
        except Exception:
            print(result.stdout + result.stderr)
        sys.exit(1)

if __name__ == "__main__":
    run_ui_performance_governance()
