#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 【第15条 ガバナンス監査】💾 データI/Oバッチ集約・Isar最適化 ＆ 履歴チャンク分割規約
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
    print(" 📊 【第15条 ガバナンス監査】💾 データI/Oバッチ集約・Isar最適化 ＆ 履歴チャンク分割規約")
    print("=" * 68)

    cmd = [
        "flutter",
        "test",
        "test/governance/io_batch_and_history_governance_test.dart",
        "--reporter=expanded",
    ]

    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    is_ok = (res.returncode == 0)

    rules = [
        ("① [マイクロバッチング] saveMatchBatched / flushMicroBatch 規約", is_ok),
        ("② [単一writeTxnアトミック化] saveMatchWithPendingCommand ＆ savePendingCommandsBulk 規約", is_ok),
        ("③ [同期バッチ化] Future.wait 並列取得 ＆ saveMatchesBulk 一括保存規約", is_ok),
        ("④ [Isar DB最適化] 128MB MMAP、3世代バックアップ、空Txn根絶規約", is_ok),
        ("⑤ [自律パージ＆滞留防止] 毒薬コマンド自律パージ ＆ deletePendingCommandsForMatches 規約", is_ok),
        ("⑥ [履歴チャンク分割] MatchEventCloudCodec チャンク分割・復元・孤立防止規約", is_ok),
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
        print(" 🔴 監査結果: 違反 (第15条 データI/Oバッチ集約・Isar最適化 ＆ 履歴チャンク分割規約に違反があります)")
        print("=" * 68)
        print(res.stdout + res.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
