#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ==============================================================================
# 🥋 Kendo OS - 【ガバナンス監査 25/25】🔋 端末低負荷・省電力・I/Oバッファリング＆LRUメモリ保護 永続保証規約 監査スクリプト
# ==============================================================================
import subprocess
import sys

def run_low_load_governance():
    test_files = [
        "test/governance/plan2_low_load_governance_test.dart",
    ]

    cmd = ["flutter", "test"] + test_files + ["--reporter=expanded"]
    result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    passed_all = (result.returncode == 0)

    rules = [
        ("1. [GPU/CPU保護] liquid_background.dart の StackTrace走査排除 ＆ RadialGradient描画規約", passed_all),
        ("2. [ディスクI/Oバッファ] match_timer_provider.dart の Timer.periodic 内メモリ集約規約", passed_all),
        ("3. [LRUメモリ保護] program_viewer_pdf_page_cache.dart の 8ページ上限 ＆ clearUrl規約", passed_all),
        ("4. [ドキュメント軽量化] match_snapshot_helper.dart のスナップショット1件保持規約", passed_all),
        ("5. [通信リーク根絶] match_list_provider.dart の autoDispose ＆ keepAliveキャッシュ規約", passed_all),
    ]

    print("=" * 60)
    print(" 📊 【ガバナンス監査 25/25】🔋 端末低負荷・省電力・I/Oバッファリング＆LRUメモリ保護 永続保証 監査レポート")
    print("=" * 60)

    for label, is_ok in rules:
        status = "🟢 適合 (Passed)" if is_ok else "🔴 違反 (Failed)"
        print(f" {label}: {status}")

    print("-" * 60)
    if passed_all:
        print(" 🟢 監査結果: 合格 (端末低負荷・省電力・I/Oバッファリング＆LRUメモリ保護規約に完全適合！)")
        print("=" * 60)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (端末負荷・省電力・メモリ保護ガバナンスに規約違反があります)")
        print("=" * 60)
        print("\n🚨 テスト実行エラー:")
        try:
            from test_failure_formatter import parse_and_format_failures
            print(parse_and_format_failures(result.stdout + result.stderr))
        except Exception:
            print(result.stdout + result.stderr)
        sys.exit(1)

if __name__ == "__main__":
    run_low_load_governance()
