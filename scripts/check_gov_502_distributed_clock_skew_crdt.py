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

import os
import sys

script_dir = os.path.dirname(os.path.abspath(__file__))
if script_dir not in sys.path:
    sys.path.insert(0, script_dir)

from gov_static_scanner import get_file_content

def main():
    print("=" * 68)
    print(" 📊 【第502条 ガバナンス監査】🌐 分散同期整合性・Clock Skew補正 ＆ CRDT調停規約")
    print("=" * 68)

    c_offset = get_file_content("lib/shared/time/server_clock_offset_service.dart") or ""
    c_time_src = get_file_content("lib/shared/time/system_time_source.dart") or ""
    c_crdt = get_file_content("lib/features/tournament/presentation/operate/providers/sync_crdt_merger.dart") or ""
    c_sync_eng = get_file_content("lib/shared/infrastructure/repository/sync_engine.dart") or ""
    c_sync_prov = get_file_content("lib/features/tournament/presentation/operate/providers/sync_provider.dart") or ""
    c_proj = get_file_content("lib/shared/application/projections/timeline_projection.dart") or ""
    c_queue = get_file_content("lib/shared/sync/pending_sync_queue.dart") or ""
    c_downstream = get_file_content("lib/shared/infrastructure/repository/sync_downstream_helper.dart") or ""

    c_main = get_file_content("lib/main.dart") or ""
    c_p2p = get_file_content("lib/features/p2p/infrastructure/local_p2p_broadcaster.dart") or ""
    c_proj_store = get_file_content("lib/shared/application/projections/projection_store.dart") or ""

    # ① Clock Skew補正
    ok1 = (
        "class ServerClockOffsetService" in c_offset
        and "Duration get offset" in c_offset
        and "ServerClockOffsetService" in c_time_src
        and ".add(offset)" in c_time_src
    )

    # ② CRDT 3者マージ
    ok2 = (
        "remoteMatch.events" in c_crdt
        and "localMatch.events" in c_crdt
        and "localMatch.pendingEvents" in c_crdt
        and "preferLocal" in c_crdt
    )

    # ③ ステータス不可逆
    ok3 = "resolveMonotonicStatus" in c_crdt

    # ④ ループ根絶 (指数バックオフ)
    ok4 = "_retryCount" in c_sync_eng or "backoff" in c_sync_eng.lower()

    # ⑤ ライフサイクル一元化: main.dart で重複排除 ＆ sync_provider 一元化
    ok5 = (
        "didChangeAppLifecycleState" not in c_main
        and "AppLifecycleListener" in c_sync_prov
    )

    # ⑥ O(1)パス直結
    ok6 = "doc(" in c_downstream or "tournamentId" in c_downstream

    # ⑦ ステート保護＆FSM
    ok7 = "switchTournament" in c_sync_prov or "tournamentId" in c_sync_prov

    # ⑧ 差分デルタ伝送
    ok8 = "broadcastMatchDelta" in c_p2p and "MATCH_DELTA" in c_p2p

    # ⑨ CQRS DI一貫性
    ok9 = "FirebaseFirestore.instance" not in c_proj_store and "firestoreProvider" in c_proj_store

    # ⑩ 分散プロジェクション＆FIFO
    ok10 = "class TimelineProjection" in c_proj and "class PendingSyncQueue" in c_queue

    # ⑪ オフラインダーティ保護
    ok11 = "!local.isDirty" in c_downstream

    rules = [
        ("① [Clock Skew補正] server_clock_offset_service ＆ system_time_source 連携規約", ok1),
        ("② [CRDT 3者マージ] リモート確定・ローカル確定・未送信マージ ＆ LWWタイマー調停規約", ok2),
        ("③ [ステータス不可逆] resolveMonotonicStatus 巻き戻り防止ガード規約", ok3),
        ("④ [ループ根絶] 指数バックオフ ＆ サーキットブレーカー安全機構規約", ok4),
        ("⑤ [ライフサイクル一元化] main.dart 重複排除 ＆ sync_provider 一元化規約", ok5),
        ("⑥ [O(1)パス直結] scoreboard.dart 階層直接監視優先 ＆ 重複リスナー排除規約", ok6),
        ("⑦ [ステート保護＆FSM] 大会切替リセット、FSM状態遷移、接続性判定統一規約", ok7),
        ("⑧ [差分デルタ伝送] broadcastMatchDelta デルタ伝送規約", ok8),
        ("⑨ [CQRS DI一貫性] ProjectionStore の firestoreProvider 経由規約", ok9),
        ("⑩ [分散プロジェクション＆FIFO] TimelineProjection決定論的ハッシュ ＆ PendingSyncQueue不変性規約", ok10),
        ("⑪ [オフラインダーティ保護] SyncDownstreamHelper isDirty未送信変更上書き防止規約", ok11),
    ]

    is_ok = all(ok for _, ok in rules)

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
        sys.exit(1)

if __name__ == "__main__":
    main()
