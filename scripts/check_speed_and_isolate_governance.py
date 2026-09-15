#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ==============================================================================
# 🥋 Kendo OS - 【ガバナンス監査 30/30】⚡ 極限高速化・UIスレッドIsolate完全分離＆ゼロ遅延即応 永続保証規約 監査スクリプト
# ==============================================================================
import subprocess
import sys

def run_speed_and_isolate_governance():
    test_files = [
        "test/governance/plan1_speed_and_isolate_governance_test.dart",
    ]

    cmd = ["flutter", "test"] + test_files + ["--reporter=expanded"]
    result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    passed_all = (result.returncode == 0)

    rules = [
        ("1. [CRDT Isolate分離] SyncCrdtMerger の mergeAndRebuildAsync & compute 配備規約", passed_all),
        ("2. [打突ボタン即応] action_buttons.dart の RepaintBoundary 配置＆先行触覚ゼロ遅延規約", passed_all),
        ("3. [操作パネル局所化] match_score_action_section.dart の RepaintBoundary＆極小select規約", passed_all),
        ("4. [アセット事前暖機] app_startup.dart の prewarmAppAssets 配備＆ノンブロッキング規約", passed_all),
        ("5. [Viewportカリング] リストアイテム/テーブルカードの RepaintBoundary 隔離規約", passed_all),
    ]

    print("=" * 60)
    print(" 📊 【ガバナンス監査 30/30】⚡ 極限高速化・UIスレッドIsolate完全分離＆ゼロ遅延即応 永続保証 監査レポート")
    print("=" * 60)

    for label, is_ok in rules:
        status = "🟢 適合 (Passed)" if is_ok else "🔴 違反 (Failed)"
        print(f" {label}: {status}")

    print("-" * 60)
    if passed_all:
        print(" 🟢 監査結果: 合格 (極限高速化・Isolate完全分離・ゼロ遅延即応規約に完全適合！)")
        print("=" * 60)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (極限高速化・Isolate分離・RepaintBoundary規約に違反があります)")
        print("=" * 60)
        print("\n🚨 テスト実行エラー:")
        try:
            from test_failure_formatter import parse_and_format_failures
            print(parse_and_format_failures(result.stdout + result.stderr))
        except Exception:
            print(result.stdout + result.stderr)
        sys.exit(1)

if __name__ == "__main__":
    run_speed_and_isolate_governance()
