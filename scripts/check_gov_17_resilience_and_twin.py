#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 【第17条 ガバナンス監査】🛡️ ツインエンジン自己修復・現場障害耐性 ＆ 完全耐障害性規約
================================================================================
① 現場障害耐性・オフライン・耐久規約
② ツイン・エンジン永続化＆Isar破損時スナップショット自己修復
③ スナップショット1件保持・ドキュメント軽量化
④ Fatal Crash Trap（未捕捉例外発生時の直前状態緊急退避）
⑤ データ消失ゼロ暗号フォールバック（saveMatchSafeMode 不正署名隔離退避）
⑥ 署名検証 O(1) キャッシュ（HMAC検証高速化＆改ざん拒絶）
⑦ 完全べき等キューイング（重複UUIDコマンド排除）
⑧ 物理的誤操作ガード（PopScope 離脱防止）
⑨ フォントオフライン耐性（enforceOfflineFontFallback 配備）
"""

import subprocess
import sys

def main():
    print("=" * 68)
    print(" 📊 【第17条 ガバナンス監査】🛡️ ツインエンジン自己修復・現場障害耐性 ＆ 完全耐障害性規約")
    print("=" * 68)

    # 1. 現場障害耐性（旧 check_offline_resilience_governance.py）
    res_offline = subprocess.run(
        ["python3", "scripts/check_offline_resilience_governance.py"],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    is_offline_ok = (res_offline.returncode == 0)

    # 2. 完全耐障害性・自己修復テスト
    cmd = [
        "flutter",
        "test",
        "test/governance/resilience_and_twin_governance_test.dart",
        "--reporter=expanded",
    ]
    res_main = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    is_main_ok = (res_main.returncode == 0)

    is_all_ok = is_offline_ok and is_main_ok

    rules = [
        ("① [現場障害耐性] オフライン・耐久・リトライ規約", is_offline_ok),
        ("② [ツイン永続化＆自己修復] TwinMatchPersistenceHelper 統合 ＆ 非同期I/O規約", is_main_ok),
        ("③ [スナップショット軽量化] ドキュメント内スナップショット保持上限(1件)規約", is_main_ok),
        ("④ [Fatal Crash Trap] EmergencyCrashPreserver 直前状態緊急退避規約", is_main_ok),
        ("⑤ [データ消失ゼロ] saveMatchSafeMode 不正署名隔離退避規約", is_main_ok),
        ("⑥ [署名検証キャッシュ] LocalMatchRepository _verifiedSignatureKeys 規約", is_main_ok),
        ("⑦ [完全べき等キュー] match_command_queue 重複UUIDコマンド排除規約", is_main_ok),
        ("⑧ [物理的誤操作ガード] match_screen.dart PopScope 離脱ガード規約", is_main_ok),
        ("⑨ [フォントオフライン耐性] app_startup.dart enforceOfflineFontFallback 規約", is_main_ok),
    ]

    for label, ok in rules:
        status = "🟢 適合 (Passed)" if ok else "🔴 違反 (Failed)"
        print(f" {label}: {status}")

    print("-" * 68)
    if is_all_ok:
        print(" 🟢 監査結果: 合格 (ツインエンジン自己修復・現場障害耐性 ＆ 完全耐障害性規約に完全適合！)")
        print("=" * 68)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (第17条 ツインエンジン自己修復・現場障害耐性 ＆ 完全耐障害性規約に違反があります)")
        print("=" * 68)
        if not is_offline_ok:
            print(res_offline.stdout + res_offline.stderr)
        if not is_main_ok:
            print(res_main.stdout + res_main.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
