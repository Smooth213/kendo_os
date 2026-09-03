#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ==============================================================================
# 🥋 kendo OS - 【ガバナンス監査 13/14】🌐 Web/PWA プラットフォーム境界＆二重デコード安全 監査スクリプト
# ==============================================================================
import subprocess
import sys

def run_web_platform_safety_governance():
    test_files = [
        "test/widget/web_reload_state_restoration_test.dart",
        "test/unit/infrastructure/web_platform_safety_test.dart",
    ]

    cmd = ["flutter", "test"] + test_files + ["--reporter=expanded"]
    result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    output = result.stdout + result.stderr

    passed_all = (result.returncode == 0)

    rules = [
        ("1. PwaStorage 永続化＆ブラウザリロード（F5）大会ID・道場ID完全復元規約", passed_all),
        ("2. URLクエリ・日本語グループ名 二重デコードクラッシュゼロ保証規約", passed_all),
        ("3. 試合進行中タブ非アクティブ化＆復帰時タイマー・スコア保全規約", passed_all),
        ("4. ServiceWorker キャッシュ競合時 論理時計順イベント収束規約", passed_all),
    ]

    print("=" * 60)
    print(" 📊 【ガバナンス監査 13/14】🌐 Web/PWA プラットフォーム境界＆二重デコード安全 監査レポート")
    print("=" * 60)

    for label, is_ok in rules:
        status = "🟢 適合 (Passed)" if is_ok else "🔴 違反 (Failed)"
        print(f" {label}: {status}")

    print("-" * 60)
    if passed_all:
        print(" 🟢 監査結果: 合格 (Web/PWA プラットフォーム境界・二重デコード安全規約に完全適合！)")
        print("=" * 60)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (Web/PWA 安全規約違反またはテスト失敗が検出されました)")
        print("=" * 60)
        from test_failure_formatter import parse_and_format_failures
        print(parse_and_format_failures(output))
        sys.exit(1)

if __name__ == "__main__":
    run_web_platform_safety_governance()
