#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 【第206条 ガバナンス監査】💾 データI/Oバッチ集約・Isar最適化 ＆ 履歴チャンク分割規約
================================================================================
① ローカルリポジトリのマイクロバッチング（saveMatchBatched / flushMicroBatch）
② 単一 writeTxn アトミック保存（saveMatchWithPendingCommand）
③ クラウド同期バッチ化（Future.wait 並列取得＆saveMatchesBulk）
④ Isar データベース最適化（128MB MMAP、3世代緊急バックアップ）
⑤ 毒薬コマンド自律パージ（Poison Pill 自動排除＆滞留防止）
⑥ 長期イベント履歴チャンク分割・全件完全復元・孤立チャンク防止
"""

import subprocess
import sys

def main():
    print("=" * 68)
    print(" 📊 【第206条 ガバナンス監査】💾 データI/Oバッチ集約・Isar最適化 ＆ 履歴チャンク分割規約")
    print("=" * 68)

    cmd1 = [
        "flutter",
        "test",
        "test/governance/io_batch_and_history_governance_test.dart",
        "--reporter=expanded",
    ]
    cmd2 = [
        "flutter",
        "test",
        "test/governance/event_store_logical_clock_governance_test.dart",
        "--reporter=expanded",
    ]
    cmd3 = [
        "flutter",
        "test",
        "test/governance/match_aggregate_repository_governance_test.dart",
        "--reporter=expanded",
    ]

    res1 = subprocess.run(cmd1, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    res2 = subprocess.run(cmd2, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    res3 = subprocess.run(cmd3, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    is_ok = (res1.returncode == 0) and (res2.returncode == 0) and (res3.returncode == 0)

    rules = [
        ("① [マイクロバッチング] saveMatchBatched / flushMicroBatch 規約", res1.returncode == 0),
        ("② [単一writeTxnアトミック化] saveMatchWithPendingCommand ＆ savePendingCommandsBulk 規約", res1.returncode == 0),
        ("③ [同期バッチ化] Future.wait 並列取得 ＆ saveMatchesBulk 一括保存規約", res1.returncode == 0),
        ("④ [Isar DB最適化] 128MB MMAP、3世代バックアップ、空Txn根絶規約", res1.returncode == 0),
        ("⑤ [自律パージ＆滞留防止] 毒薬コマンド自律パージ ＆ deletePendingCommandsForMatches 規約", res1.returncode == 0),
        ("⑥ [履歴チャンク分割] MatchEventCloudCodec チャンク分割・復元・孤立防止規約", res1.returncode == 0),
        ("⑦ [イベントソーシング] InMemoryEventStore 論理時計採番 ＆ 楽観的ロック整合性規約", res2.returncode == 0),
        ("⑧ [イベントソーシング] MatchAggregateRepository 50件スナップショット ＆ 3回競合オートリペア規約", res3.returncode == 0),
    ]

    for label, ok in rules:
        status = "🟢 適合 (Passed)" if ok else "🔴 違反 (Failed)"
        print(f" {label}: {status}")

    print("-" * 68)
    if is_ok:
        print(" 🟢 監査結果: 合格 (データI/Oバッチ集約・Isar最適化 ＆ 履歴チャンク分割規約に完全適合！)")
        print("=" * 68)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (第206条 データI/Oバッチ集約・Isar最適化 ＆ 履歴チャンク分割規約に違反があります)")
        print("=" * 68)
        print(res1.stdout + res1.stderr + res2.stdout + res2.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
