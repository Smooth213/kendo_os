#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 【第502条 ガバナンス監査】🌐 分散同期整合性・Clock Skew補正 ＆ CRDT調停規約
================================================================================
① Clock Skew 時刻補正（server_clock_offset_service.dart 連携）
② CRDT 3者マージ＆LWWタイマー調停（sync_crdt_merger.dart）
③ CRDT ステータス不可逆ガード（resolveMonotonicStatus による巻き戻り防止）
④ 同期ビジー再帰ループ根絶（指数バックオフ＆サーキットブレーカー）
⑤ ライフサイクル同期一元化（main.dart 重複排除、sync_provider.dart 一元化）
⑥ Firestoreリスナー一元化＆O(1)パス直接監視優先（collectionGroup 回避）
⑦ Webステート保護＆FSM状態遷移＆コネクティビティ判定統一
⑧ 差分デルタ伝送（broadcastMatchDelta）
"""

import subprocess
import sys

def main():
    print("=" * 68)
    print(" 📊 【第502条 ガバナンス監査】🌐 分散同期整合性・Clock Skew補正 ＆ CRDT調停規約")
    print("=" * 68)

    cmd1 = [
        "flutter",
        "test",
        "test/governance/sync_and_crdt_governance_test.dart",
        "--reporter=expanded",
    ]
    res1 = subprocess.run(cmd1, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    is_ok1 = (res1.returncode == 0)

    cmd2 = [
        "flutter",
        "test",
        "test/governance/projection_hash_and_sync_queue_governance_test.dart",
        "--reporter=expanded",
    ]
    res2 = subprocess.run(cmd2, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    is_ok2 = (res2.returncode == 0)

    cmd3 = [
        "flutter",
        "test",
        "test/governance/sync_downstream_dirty_protection_governance_test.dart",
        "--reporter=expanded",
    ]
    res3 = subprocess.run(cmd3, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    is_ok3 = (res3.returncode == 0)

    is_ok = is_ok1 and is_ok2 and is_ok3

    rules = [
        ("① [Clock Skew補正] server_clock_offset_service ＆ system_time_source 連携規約", is_ok1),
        ("② [CRDT 3者マージ] リモート確定・ローカル確定・未送信マージ ＆ LWWタイマー調停規約", is_ok1),
        ("③ [ステータス不可逆] resolveMonotonicStatus 巻き戻り防止ガード規約", is_ok1),
        ("④ [ループ根絶] 指数バックオフ ＆ サーキットブレーカー安全機構規約", is_ok1),
        ("⑤ [ライフサイクル一元化] main.dart 重複排除 ＆ sync_provider 一元化規約", is_ok1),
        ("⑥ [O(1)パス直結] scoreboard.dart 階層直接監視優先 ＆ 重複リスナー排除規約", is_ok1),
        ("⑦ [ステート保護＆FSM] 大会切替リセット、FSM状態遷移、接続性判定統一規約", is_ok1),
        ("⑧ [差分デルタ伝送] broadcastMatchDelta デルタ伝送規約", is_ok1),
        ("⑨ [CQRS DI一貫性] ProjectionStore の firestoreProvider 経由規約", is_ok1),
        ("⑩ [分散プロジェクション＆FIFO] TimelineProjection決定論的ハッシュ ＆ PendingSyncQueue不変性規約", is_ok2),
        ("⑪ [オフラインダーティ保護] SyncDownstreamHelper isDirty未送信変更上書き防止規約", is_ok3),
    ]

    for label, ok in rules:
        status = "🟢 適合 (Passed)" if ok else "🔴 違反 (Failed)"
        print(f" {label}: {status}")

    print("-" * 68)
    if is_ok:
        print(" 🟢 監査結果: 合格 (分散同期整合性・Clock Skew補正 ＆ CRDT調停規約に完全適合！)")
        print("=" * 68)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (第502条 分散同期整合性・Clock Skew補正 ＆ CRDT調停規約に違反があります)")
        print("=" * 68)
        if not is_ok1:
            print(res1.stdout + res1.stderr)
        if not is_ok2:
            print(res2.stdout + res2.stderr)
        if not is_ok3:
            print(res3.stdout + res3.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
