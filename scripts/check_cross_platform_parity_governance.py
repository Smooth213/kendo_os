#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ==============================================================================
# 🥋 Kendo OS - 【ガバナンス監査 1/29】🌐 Web/Native クロスプラットフォーム完全同一動作保証規約 監査スクリプト
# ==============================================================================
import subprocess
import sys

def run_cross_platform_parity_governance():
    test_files = [
        "test/governance/cross_platform_parity_governance_test.dart",
    ]

    cmd = ["flutter", "test"] + test_files + ["--reporter=expanded"]
    result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    passed_all = (result.returncode == 0)

    rules = [
        ("1. [プラットフォーム安全ガード] dart:io 利用箇所の Web (kIsWeb) 安全分岐・フォールバック規約", passed_all),
        ("2. [データ圧縮・復元同一性] Web/Native Gzip 圧縮・伸張データ 100% 可逆復元規約", passed_all),
        ("3. [オフラインストレージ・PWA整合性] Web/Native 同期コンテキスト・ストレージキー統一規約", passed_all),
        ("4. [レスポンシブ・UIレイアウト安全規約] デスクトップ(Web)とモバイル(Native)サイズ破綻ゼロ規約", passed_all),
        ("5. [ファイル境界・Webビルド安全規約] lib/配下 Web非互換 Platform 直呼び出し排除規約", passed_all),
    ]

    print("=" * 60)
    print(" 📊 【ガバナンス監査 1/29】🌐 Web/Native クロスプラットフォーム完全同一動作保証 監査レポート")
    print("=" * 60)

    for label, is_ok in rules:
        status = "🟢 適合 (Passed)" if is_ok else "🔴 違反 (Failed)"
        print(f" {label}: {status}")

    print("-" * 60)
    if passed_all:
        print(" 🟢 監査結果: 合格 (Web/Native クロスプラットフォーム完全同一動作保証規約に完全適合！)")
        print("=" * 60)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (クロスプラットフォーム同一動作保証ガバナンスに規約違反があります)")
        print("=" * 60)
        print("\n🚨 テスト実行エラー:")
        try:
            from test_failure_formatter import parse_and_format_failures
            print(parse_and_format_failures(result.stdout + result.stderr))
        except Exception:
            print(result.stdout + result.stderr)
        sys.exit(1)

if __name__ == "__main__":
    run_cross_platform_parity_governance()
