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

import os
import re
import sys

script_dir = os.path.dirname(os.path.abspath(__file__))
if script_dir not in sys.path:
    sys.path.insert(0, script_dir)

from gov_static_scanner import get_file_content

def main():
    print("=" * 68)
    print(" 📊 【第206条 ガバナンス監査】💾 データI/Oバッチ集約・Isar最適化 ＆ 履歴チャンク分割規約")
    print("=" * 68)

    c_local_repo = get_file_content("lib/shared/infrastructure/repository/local_match_repository.dart") or ""
    c_persist_helper = get_file_content("lib/features/match/application/services/match_persistence_helper.dart") or ""
    c_cmd_store = get_file_content("lib/shared/infrastructure/repository/local_match_command_store.dart") or ""
    c_sync_provider = get_file_content("lib/features/tournament/presentation/operate/providers/sync_provider.dart") or ""
    c_startup = get_file_content("lib/bootstrap/app_startup.dart") or ""
    c_boot_helper = get_file_content("lib/shared/bootstrap/app_bootstrap_helper.dart") or ""
    c_archive_helper = get_file_content("lib/shared/infrastructure/repository/local_match_archive_helper.dart") or ""
    c_sync_engine = get_file_content("lib/shared/infrastructure/repository/sync_engine.dart") or ""
    c_match_repo = get_file_content("lib/shared/infrastructure/repository/match_repository.dart") or ""
    c_rules = get_file_content("firestore.rules") or ""
    c_event_store = get_file_content("lib/shared/infrastructure/repository/in_memory_event_store.dart") or ""
    c_agg_repo = get_file_content("lib/shared/infrastructure/repository/match_aggregate_repository.dart") or ""
    c_group_card = get_file_content("lib/features/tournament/presentation/operate/components/timeline/timeline_match_group_card.dart") or ""

    # ① マイクロバッチング
    ok1 = "saveMatchBatched" in c_local_repo and "flushMicroBatch" in c_local_repo

    # ② 単一 writeTxn アトミック化
    ok2 = (
        "Future<void> saveMatchWithPendingCommand(" in c_local_repo
        and "saveMatchWithPendingCommand(" in c_persist_helper
        and "savePendingCommandsBulk" in c_cmd_store
        and "matchCommandEntitys.putAll" in c_cmd_store
    )

    # ③ クラウド同期バッチ化
    ok3 = (
        "await Future.wait(" in c_sync_provider
        and bool(re.search(r"await localRepo\.saveMatchesBulk\(\s*syncedMatchesToSave", c_sync_provider))
    )

    # ④ Isar DB最適化
    ok4 = (
        "maxSizeMiB = 128" in c_startup
        and "maxSizeMiB: 128" in c_boot_helper
        and "_saveEmergencyBackupWithRotation" in c_local_repo
        and "backupFiles.length > 3" in c_local_repo
        and "findFirst()" in c_archive_helper
    )

    # ⑤ 自律パージ＆滞留防止
    ok5 = (
        "ConflictException" in c_sync_engine
        and "remoteMatch.version >= match.version" in c_sync_engine
        and "Staleコマンドを自律パージします" in c_sync_engine
        and "_retryCount >= 10" in c_sync_engine
        and "deletePendingCommandsForMatches" in c_local_repo
        and "deletePendingCommandsForMatches" in c_sync_provider
    )

    # ⑥ 履歴チャンク分割
    ok6 = (
        "collection('events')" in c_match_repo
        and "batch.delete(chunk.reference)" in c_match_repo
        and "match /events/{eventChunkId}" in c_rules
    )

    # ⑦ イベントソーシング論理時計
    ok7 = (
        "class ConcurrencyException" in c_event_store
        and "logicalClock" in c_event_store
        and "expectedVersion" in c_event_store
    )

    # ⑧ イベントソーシング集約
    ok8 = (
        "newEvents.length % 50 == 0" in c_agg_repo
        and "snapshotStore.save" in c_agg_repo
        and "attempts < 3" in c_agg_repo
        and "on ConcurrencyException" in c_agg_repo
    )

    # ⑨ 複数試合一括削除
    ok9 = (
        "Future<void> deleteMatchesBulk(" in c_local_repo
        and "Future<void> deleteMatchesBulk(" in c_match_repo
        and "deleteMatchesBulk(" in c_group_card
        and not bool(re.search(r"for\s*\([^)]+\)\s*\{[^}]*deleteMatch\(", c_group_card))
    )

    rules = [
        ("① [マイクロバッチング] saveMatchBatched / flushMicroBatch 規約", ok1),
        ("② [単一writeTxnアトミック化] saveMatchWithPendingCommand ＆ savePendingCommandsBulk 規約", ok2),
        ("③ [同期バッチ化] Future.wait 並列取得 ＆ saveMatchesBulk 一括保存規約", ok3),
        ("④ [Isar DB最適化] 128MB MMAP、3世代バックアップ、空Txn根絶規約", ok4),
        ("⑤ [自律パージ＆滞留防止] 毒薬コマンド自律パージ ＆ deletePendingCommandsForMatches 規約", ok5),
        ("⑥ [履歴チャンク分割] MatchEventCloudCodec チャンク分割・復元・孤立防止規約", ok6),
        ("⑦ [イベントソーシング] InMemoryEventStore 論理時計採番 ＆ 楽観的ロック整合性規約", ok7),
        ("⑧ [イベントソーシング] MatchAggregateRepository 50件スナップショット ＆ 3回競合オートリペア規約", ok8),
        ("⑨ [複数試合一括削除] deleteMatchesBulk アトミック一括削除 ＆ 逐次削除ループ排除規約", ok9),
    ]

    is_ok = all(ok for _, ok in rules)

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
