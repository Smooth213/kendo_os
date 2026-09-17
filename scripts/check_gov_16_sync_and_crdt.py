#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 【第16条 ガバナンス監査】🌐 分散同期整合性・Clock Skew補正 ＆ CRDT調停規約
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
    print(" 📊 【第16条 ガバナンス監査】🌐 分散同期整合性・Clock Skew補正 ＆ CRDT調停規約")
    print("=" * 68)

    cmd = [
        "flutter",
        "test",
        "test/governance/sync_and_crdt_governance_test.dart",
        "--reporter=expanded",
    ]

    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    is_ok = (res.returncode == 0)

    rules = [
        ("① [Clock Skew補正] server_clock_offset_service ＆ system_time_source 連携規約", is_ok),
        ("② [CRDT 3者マージ] リモート確定・ローカル確定・未送信マージ ＆ LWWタイマー調停規約", is_ok),
        ("③ [ステータス不可逆] resolveMonotonicStatus 巻き戻り防止ガード規約", is_ok),
        ("④ [ループ根絶] 指数バックオフ ＆ サーキットブレーカー安全機構規約", is_ok),
        ("⑤ [ライフサイクル一元化] main.dart 重複排除 ＆ sync_provider 一元化規約", is_ok),
        ("⑥ [O(1)パス直結] scoreboard.dart 階層直接監視優先 ＆ 重複リスナー排除規約", is_ok),
        ("⑦ [ステート保護＆FSM] 大会切替リセット、FSM状態遷移、接続性判定統一規約", is_ok),
        ("⑧ [差分デルタ伝送] broadcastMatchDelta デルタ伝送規約", is_ok),
        ("⑨ [CQRS DI一貫性] ProjectionStore の firestoreProvider 経由規約", is_ok),
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
        print(" 🔴 監査結果: 違反 (第16条 分散同期整合性・Clock Skew補正 ＆ CRDT調停規約に違反があります)")
        print("=" * 68)
        print(res.stdout + res.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
