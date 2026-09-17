#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 【第12条 ガバナンス監査】🧵 Isolate完全分離・非同期バックオフ ＆ 非ブロッキング処理規約
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
    print(" 📊 【第12条 ガバナンス監査】🧵 Isolate完全分離・非同期バックオフ ＆ 非ブロッキング処理規約")
    print("=" * 68)

    cmd = [
        "flutter",
        "test",
        "test/governance/isolate_and_concurrency_governance_test.dart",
        "--reporter=expanded",
    ]

    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    is_ok = (res.returncode == 0)

    rules = [
        ("① [CRDT非同期マージ] sync_crdt_merger.dart の mergeAndRebuildAsync ＆ compute規約", is_ok),
        ("② [PDF非同期オフロード] pdf_service.dart の compute 経由オフロード規約", is_ok),
        ("③ [生フォントバイト] pdf_font_loader.dart の loadFontBytes ＆ バイトキャッシュ規約", is_ok),
        ("④ [非同期バックオフ] sync_engine.dart のスレッドロック禁止 ＆ _nextAttemptAt 規約", is_ok),
        ("⑤ [アセット暖機] app_startup.dart の prewarmAppAssets ノンブロッキング規約", is_ok),
        ("⑥ [ブートストラップ層] main.dart の 5大最適化パイプライン結合規約", is_ok),
        ("⑦ [SyncEngineライフサイクル] AppLifecycleListener コールドスリープ ＆ dispose時破棄規約", is_ok),
    ]

    for label, ok in rules:
        status = "🟢 適合 (Passed)" if ok else "🔴 違反 (Failed)"
        print(f" {label}: {status}")

    print("-" * 68)
    if is_ok:
        print(" 🟢 監査結果: 合格 (Isolate完全分離・非同期バックオフ ＆ 非ブロッキング処理規約に完全適合！)")
        print("=" * 68)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (第12条 Isolate完全分離・非同期バックオフ ＆ 非ブロッキング処理規約に違反があります)")
        print("=" * 68)
        print(res.stdout + res.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
