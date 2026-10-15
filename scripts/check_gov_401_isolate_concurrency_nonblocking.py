#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 【第401条 ガバナンス監査】🧵 Isolate完全分離・非同期バックオフ ＆ 非ブロッキング処理規約
================================================================================
① CRDT 非同期マージ（SyncCrdtMerger.mergeAndRebuildAsync & compute）
② PDF 生成の compute オフロード＆UIフリーズ撲滅
③ 生フォントバイトキャッシュ（pdf_font_loader.dart）
④ sync_engine.dart のスレッドロック禁止＆非同期バックオフ（_nextAttemptAt）
⑤ アセット事前暖機（AppStartup.prewarmAppAssets）ノンブロッキング
⑥ ブートストラップ層（main.dart）の最適化パイプライン結合
"""

import subprocess
import sys

def main():
    print("=" * 68)
    print(" 📊 【第401条 ガバナンス監査】🧵 Isolate完全分離・非同期バックオフ ＆ 非ブロッキング処理規約")
    print("=" * 68)

    import os
    import sys

    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(script_dir)

    def read_file(rel):
        full = os.path.join(project_root, rel)
        if not os.path.isfile(full):
            return ""
        with open(full, "r", encoding="utf-8") as f:
            return f.read()

    c_crdt = read_file("lib/features/tournament/presentation/operate/providers/sync_crdt_merger.dart")
    c_pdf = read_file("lib/features/pdf/pdf_service.dart")
    c_font = read_file("lib/features/pdf/services/pdf_font_loader.dart")
    c_sync = read_file("lib/shared/infrastructure/repository/sync_engine.dart")
    c_startup = read_file("lib/bootstrap/app_startup.dart")
    c_main = read_file("lib/main.dart")

    r1 = ("Future<MatchModel> mergeAndRebuildAsync(" in c_crdt and 
          "compute(_crdtMergeWorker, params)" in c_crdt and 
          "Future<MatchModel> _crdtMergeWorker(" in c_crdt)

    r2 = ("compute(_generatePdfBytesInWorker" in c_pdf and 
          "Future<Uint8List> _generatePdfBytesInWorker" in c_pdf)

    r3 = ("loadFontBytes()" in c_font and "_cachedRawBytes" in c_font)

    r4 = ("await Future.delayed" not in c_sync and 
          "_nextAttemptAt" in c_sync and 
          "void resetBackoffAndProcess()" in c_sync)

    r5 = ("static Future<void> prewarmAppAssets()" in c_startup and 
          "unawaited(prewarmAppAssets());" in c_startup and 
          "assets/kendo_icon.png" in c_startup and 
          "GoogleFonts.pendingFonts" in c_startup)

    r6 = ("WebPlatformOptimizer.applyOptimizations()" in c_main and 
          "AppStartup.configureImageCache()" in c_main and 
          "AppStartup.configureFontOptimization()" in c_main and 
          ("soundServiceProvider" in c_main and ".prewarm()" in c_main) and 
          ("userDataCloudSyncManagerProvider" in c_main and ".initialize()" in c_main) and 
          "AppStartup.prewarmAppAssets()" in c_main)

    r7 = ("AppLifecycleListener(" in c_sync and 
          "onPause: _handleBackground" in c_sync and 
          "_stopSyncLoop()" in c_sync and 
          "_lifecycleListener?.dispose()" in c_sync and 
          "_debounceSyncTimer?.cancel()" in c_sync)

    rules = [
        ("① [CRDT非同期マージ] sync_crdt_merger.dart の mergeAndRebuildAsync ＆ compute規約", r1),
        ("② [PDF非同期オフロード] pdf_service.dart の compute 経由オフロード規約", r2),
        ("③ [生フォントバイト] pdf_font_loader.dart の loadFontBytes ＆ バイトキャッシュ規約", r3),
        ("④ [非同期バックオフ] sync_engine.dart のスレッドロック禁止 ＆ _nextAttemptAt 規約", r4),
        ("⑤ [アセット暖機] app_startup.dart の prewarmAppAssets ノンブロッキング規約", r5),
        ("⑥ [ブートストラップ層] main.dart の 5大最適化パイプライン結合規約", r6),
        ("⑦ [SyncEngineライフサイクル] AppLifecycleListener コールドスリープ ＆ dispose時破棄規約", r7),
    ]

    all_passed = True
    for label, ok in rules:
        status = "🟢 適合 (Passed)" if ok else "🔴 違反 (Failed)"
        print(f" {label}: {status}")
        if not ok:
            all_passed = False

    print("-" * 68)
    if all_passed:
        print(" 🟢 監査結果: 合格 (Isolate完全分離・非同期バックオフ ＆ 非ブロッキング処理規約に完全適合！)")
        print("=" * 68)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (第401条 Isolate完全分離・非同期バックオフ ＆ 非ブロッキング処理規約に違反があります)")
        print("=" * 68)
        sys.exit(1)

if __name__ == "__main__":
    main()
