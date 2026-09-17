#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 【第14条 ガバナンス監査】🧹 メモリ保護・LRU上限 ＆ リソース明示解放（リーク根絶）規約
================================================================================
① LRUキャッシュ上限＆解放（PDFビューア 8ページ上限＆clearUrl）
② ビューア画面＆PDFサービスの明示的メモリ解放
③ コントローラー明示解放（timeline_rename_team_sheet, critical_action_guard）
④ グローバルアナウンス購読解除（cancelGlobalAnnouncements）
⑤ プロバイダ autoDispose & keepAlive 適正管理
"""

import subprocess
import sys

def main():
    print("=" * 68)
    print(" 📊 【第14条 ガバナンス監査】🧹 メモリ保護・LRU上限 ＆ リソース明示解放（リーク根絶）規約")
    print("=" * 68)

    cmd = [
        "flutter",
        "test",
        "test/governance/memory_and_lifecycle_governance_test.dart",
        "--reporter=expanded",
    ]

    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    is_ok = (res.returncode == 0)

    rules = [
        ("① [LRU上限＆解放] program_viewer_pdf_page_cache の LRU 上限 ＆ clearUrl 規約", is_ok),
        ("② [明示的メモリ解放] ビューア画面 ＆ PDFサービスの明示的画像キャッシュ解放規約", is_ok),
        ("③ [コントローラー解放] 各種画面・ダイアログの TextEditingController 明示破棄規約", is_ok),
        ("④ [アナウンス購読解除] cancelGlobalAnnouncements ＆ 既読ID上限トリム規約", is_ok),
        ("⑤ [プロバイダ管理] matchList / viewer / sound プロバイダの autoDispose ＆ keepAlive 規約", is_ok),
    ]

    for label, ok in rules:
        status = "🟢 適合 (Passed)" if ok else "🔴 違反 (Failed)"
        print(f" {label}: {status}")

    print("-" * 68)
    if is_ok:
        print(" 🟢 監査結果: 合格 (メモリ保護・LRU上限 ＆ リソース明示解放規約に完全適合！)")
        print("=" * 68)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (第14条 メモリ保護・LRU上限 ＆ リソース明示解放規約に違反があります)")
        print("=" * 68)
        print(res.stdout + res.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
