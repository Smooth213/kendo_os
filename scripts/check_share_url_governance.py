#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ==============================================================================
# 🥋 kendo OS - 【ガバナンス監査 20/20】🔗 観客用共有URL・ルーティング・パラメータ整合性 監査スクリプト
# ==============================================================================
import subprocess
import sys

def run_share_url_governance():
    test_files = [
        "test/governance/share_url_governance_test.dart",
    ]

    cmd = ["flutter", "test"] + test_files + ["--reporter=expanded"]
    result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    passed_all = (result.returncode == 0)

    rules = [
        ("1. 公式Webビュアーホスト(kendo-os-beta.web.app)完全準拠規約", passed_all),
        ("2. AppRouter 正規ルート実在保証 (viewer/viewer-team/viewer-kachinuki/viewer-home/bunaiksen) 規約", passed_all),
        ("3. 必須クエリパラメータ (role=viewer, dojoId, tournamentId) 完全保持規約", passed_all),
        ("4. 団体戦・個人戦・勝ち抜き戦 ルーティング厳格分離規約", passed_all),
        ("5. 部内戦専用ビュアーホーム (bunaiksen-viewer-home) 完全自動分岐規約", passed_all),
        ("6. 野良URL・パラメータ欠落URL排除 lib/ コードスキャン規約", passed_all),
        ("7. 全共有ダイアログ・サービス (BAND/Share/P2P) 総合結合URL生成保証規約", passed_all),
    ]

    print("=" * 60)
    print(" 📊 【ガバナンス監査 20/20】🔗 観客用共有URL・ルーティング・パラメータ整合性 監査レポート")
    print("=" * 60)

    for label, is_ok in rules:
        status = "🟢 適合 (Passed)" if is_ok else "🔴 違反 (Failed)"
        print(f" {label}: {status}")

    print("-" * 60)
    if passed_all:
        print(" 🟢 監査結果: 合格 (観客用共有URL・ルーティング・パラメータ整合性に完全適合！)")
        print("=" * 60)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (共有URL生成・ルーティングに規約違反があります)")
        print("=" * 60)
        print("\n🚨 テスト実行エラー:")
        try:
            from test_failure_formatter import parse_and_format_failures
            print(parse_and_format_failures(result.stdout + result.stderr))
        except Exception:
            print(result.stdout + result.stderr)
        sys.exit(1)

if __name__ == "__main__":
    run_share_url_governance()
