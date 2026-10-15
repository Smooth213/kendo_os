#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 【第503条 ガバナンス監査】🛡️ ツインエンジン自己修復・現場障害耐性 ＆ 完全耐障害性規約
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

import os
import sys

script_dir = os.path.dirname(os.path.abspath(__file__))
if script_dir not in sys.path:
    sys.path.insert(0, script_dir)

from gov_static_scanner import get_file_content

def main():
    print("=" * 68)
    print(" 📊 【第503条 ガバナンス監査】🛡️ ツインエンジン自己修復・現場障害耐性 ＆ 完全耐障害性規約")
    print("=" * 68)

    c_twin = get_file_content("lib/shared/infrastructure/persistence/twin_match_persistence_helper.dart") or ""
    c_local_repo = get_file_content("lib/shared/infrastructure/repository/local_match_repository.dart") or ""
    c_snap_helper = get_file_content("lib/features/match/application/services/match_snapshot_helper.dart") or ""
    c_snap_service = get_file_content("lib/features/tournament/presentation/operate/providers/match_snapshot_service.dart") or ""
    c_preserver = get_file_content("lib/shared/errors/emergency_crash_preserver.dart") or ""
    c_handler = get_file_content("lib/shared/errors/global_error_handler.dart") or ""
    c_queue = get_file_content("lib/features/tournament/presentation/operate/providers/match_command_queue.dart") or ""
    c_screen = get_file_content("lib/features/tournament/presentation/operate/match_screen.dart") or ""
    c_startup = get_file_content("lib/bootstrap/app_startup.dart") or ""

    # ① 現場障害耐性
    ok1 = "class LocalMatchRepository" in c_local_repo

    # ② ツイン永続化＆自己修復
    ok2 = (
        "TwinMatchPersistenceHelper" in c_local_repo
        and "Self-Healing" in c_local_repo
        and "listSync(" not in c_twin
        and "deleteSync(" not in c_twin
    )

    # ③ スナップショット軽量化
    ok3 = "this.maxSnapshots = 1" in c_snap_helper and "newSnapshots.length > 1" in c_snap_service

    # ④ Fatal Crash Trap
    ok4 = "preserveOnCrash" in c_preserver and "loadRecoverableCrashDump" in c_preserver

    # ⑤ データ消失ゼロ
    ok5 = (
        "saveMatchSafeMode" in c_local_repo
        and "saveMatchesBulkSafeMode" in c_local_repo
        and "[QUARANTINE_TAMPERED]" in c_local_repo
    )

    # ⑥ 署名検証キャッシュ
    ok6 = "_verifiedSignatureKeys" in c_local_repo and "_verifyMatchSignatures(" in c_local_repo

    # ⑦ 完全べき等キュー
    ok7 = "_processedCommandIds" in c_queue and "Idempotent" in c_queue and "backoffMs" in c_queue

    # ⑧ 物理的誤操作ガード
    ok8 = "PopScope" in c_screen

    # ⑨ フォントオフライン耐性
    ok9 = "enforceOfflineFontFallback" in c_startup

    # ⑩ クラッシュ隔離
    ok10 = "runZonedGuarded" in c_handler and "WidgetsFlutterBinding.ensureInitialized()" in c_handler

    # ⑪ GlobalErrorHandler 全3系統退避
    ok11 = (
        "FlutterError.onError" in c_handler
        and "PlatformDispatcher.instance.onError" in c_handler
        and c_handler.count("EmergencyCrashPreserver.preserveOnCrash") >= 3
    )

    rules = [
        ("① [現場障害耐性] オフライン・耐久・リトライ規約", ok1),
        ("② [ツイン永続化＆自己修復] TwinMatchPersistenceHelper 統合 ＆ 非同期I/O規約", ok2),
        ("③ [スナップショット軽量化] ドキュメント内スナップショット保持上限(1件)規約", ok3),
        ("④ [Fatal Crash Trap] EmergencyCrashPreserver 直前状態緊急退避規約", ok4),
        ("⑤ [データ消失ゼロ] saveMatchSafeMode 不正署名隔離退避規約", ok5),
        ("⑥ [署名検証キャッシュ] LocalMatchRepository _verifiedSignatureKeys 規約", ok6),
        ("⑦ [完全べき等キュー] match_command_queue 重複UUIDコマンド排除規約", ok7),
        ("⑧ [物理的誤操作ガード] match_screen.dart PopScope 離脱ガード規約", ok8),
        ("⑨ [フォントオフライン耐性] app_startup.dart enforceOfflineFontFallback 規約", ok9),
        ("⑩ [Fatal Crash Trap] 非同期例外完全捕捉＆クラッシュ隔離（Async Error Boundary）規約", ok10),
        ("⑪ [Fatal Crash Trap] GlobalErrorHandler 全3系統緊急退避規約", ok11),
    ]

    is_all_ok = all(ok for _, ok in rules)

    for label, ok in rules:
        status = "🟢 適合 (Passed)" if ok else "🔴 違反 (Failed)"
        print(f" {label}: {status}")

    print("-" * 68)
    if is_all_ok:
        print(" 🟢 監査結果: 合格 (ツインエンジン自己修復・現場障害耐性 ＆ 完全耐障害性規約に完全適合！)")
        print("=" * 68)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (第503条 ツインエンジン自己修復・現場障害耐性 ＆ 完全耐障害性規約に違反があります)")
        print("=" * 68)
        sys.exit(1)

if __name__ == "__main__":
    main()
