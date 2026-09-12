#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ==============================================================================
# 🥋 kendo OS - 【ガバナンス監査 21/21】🛡️ BAND LIVE配信連携・外部直行遷移 ＆ 白紙ブラウザ残留ゼロ 監査スクリプト
# ==============================================================================
import subprocess
import sys

def run_band_governance():
    test_files = [
        "test/governance/band_live_integration_governance_test.dart",
    ]

    cmd = ["flutter", "test"] + test_files + ["--reporter=expanded"]
    result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    passed_all = (result.returncode == 0)

    rules = [
        ("1. [静的スキャン] BAND起動・URL変換の責務集約規約（野良起動の完全排除）", passed_all),
        ("2. [静的スキャン] BAND未対応スキーム（bandapp://n/, bandapp://@）生成の完全排除規約", passed_all),
        ("3. [静的スキャン] LIVE配信不可共有API（bandapp://create/post）への強制リダイレクト排除規約", passed_all),
        ("4. [動的規約] ネイティブ環境アプリ内ブラウザ（SFSafariViewController）完全排除規約", passed_all),
        ("5. [動的規約] Web環境（iOS PWA）同一コンテキスト直接キック最優先規約", passed_all),
        ("6. [動的規約] BAND URL正規化＆LIVE配信画面ルート整合性規約", passed_all),
    ]

    print("=" * 60)
    print(" 📊 【ガバナンス監査 21/21】🛡️ BAND LIVE配信連携・外部直行遷移 ＆ 白紙ブラウザ残留ゼロ 監査レポート")
    print("=" * 60)

    for label, is_ok in rules:
        status = "🟢 適合 (Passed)" if is_ok else "🔴 違反 (Failed)"
        print(f" {label}: {status}")

    print("-" * 60)
    if passed_all:
        print(" 🟢 監査結果: 合格 (BAND LIVE配信連携・外部直行遷移・白紙ブラウザ残留ゼロに完全適合！)")
        print("=" * 60)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (BAND連携・ブラウザ遷移に規約違反があります)")
        print("=" * 60)
        print("\n🚨 テスト実行エラー:")
        try:
            from test_failure_formatter import parse_and_format_failures
            print(parse_and_format_failures(result.stdout + result.stderr))
        except Exception:
            print(result.stdout + result.stderr)
        sys.exit(1)

if __name__ == "__main__":
    run_band_governance()
