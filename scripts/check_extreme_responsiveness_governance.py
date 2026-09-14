#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ==============================================================================
# 🥋 Kendo OS - 【ガバナンス監査 27/27】⚡ UI極限軽快化・動的ProviderScope排除＆I/Oバッチ集約 永続保証規約 監査スクリプト
# ==============================================================================
import subprocess
import sys

def run_extreme_responsiveness_governance():
    test_files = [
        "test/governance/plan1_extreme_responsiveness_governance_test.dart",
    ]

    cmd = ["flutter", "test"] + test_files + ["--reporter=expanded"]
    result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    passed_all = (result.returncode == 0)

    rules = [
        ("1. [Rebuild Storm根絶] ListEqualityWrapper による同一内容リスト再通知遮断規約", passed_all),
        ("2. [動的ProviderScope排除] match_screen.dart の動的ProviderScope撤廃＆Element再利用規約", passed_all),
        ("3. [単一writeTxnアトミック化] saveMatchWithPendingCommand による保存I/O集約規約", passed_all),
        ("4. [署名検証O(1)キャッシュ] _verifiedSignatureKeys によるHMAC検証高速化＆改ざん拒絶規約", passed_all),
        ("5. [クラウド同期バッチ化] sync_provider.dart の Future.wait 並列取得＆saveMatchesBulk規約", passed_all),
    ]

    print("=" * 60)
    print(" 📊 【ガバナンス監査 27/27】⚡ UI極限軽快化・動的ProviderScope排除＆I/Oバッチ集約 永続保証 監査レポート")
    print("=" * 60)

    for label, is_ok in rules:
        status = "🟢 適合 (Passed)" if is_ok else "🔴 違反 (Failed)"
        print(f" {label}: {status}")

    print("-" * 60)
    if passed_all:
        print(" 🟢 監査結果: 合格 (UI極限軽快化・動的ProviderScope排除＆I/Oバッチ集約規約に完全適合！)")
        print("=" * 60)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (UI軽快化・Element再利用・I/O集約ガバナンスに規約違反があります)")
        print("=" * 60)
        print("\n🚨 テスト実行エラー:")
        try:
            from test_failure_formatter import parse_and_format_failures
            print(parse_and_format_failures(result.stdout + result.stderr))
        except Exception:
            print(result.stdout + result.stderr)
        sys.exit(1)

if __name__ == "__main__":
    run_extreme_responsiveness_governance()
