#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 【第25条 ガバナンス監査】🔐 スコアイベント電子署名・改ざん隔離 ＆ ゼロトラストデータ完全性保証規約
================================================================================
① スコアイベント電子署名検証（ScoreEventLegacyAdapter.verifySignature）完全性規約
② 悪意ある改ざん検知・例外送出（TamperedEventException）規約
③ クランティン隔離モード（allowQuarantine: true）による安全退避規約
④ 署名検証済みキーキャッシュ（5000件超過時LRUクリア）メモリ保護規約
"""

import subprocess
import sys

def main():
    print("=" * 68)
    print(" 📊 【第25条 ガバナンス監査】🔐 スコアイベント電子署名・改ざん隔離 ＆ ゼロトラストデータ完全性保証規約")
    print("=" * 68)

    cmd = [
        "flutter",
        "test",
        "test/governance/event_signature_governance_test.dart",
        "--reporter=expanded",
    ]

    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    is_ok = (res.returncode == 0)

    rules = [
        ("① [電子署名検証] スコアイベント電子署名（ScoreEventLegacyAdapter）完全性規約", is_ok),
        ("② [改ざん検知・遮断] 不正スコアイベント投入時のTamperedEventException送出規約", is_ok),
        ("③ [クランティン隔離] allowQuarantine有効時の隔離退避 ＆ ゼロトラストデータ保全規約", is_ok),
        ("④ [キャッシュメモリ保護] 署名キャッシュ5000件超過時LRUクリア ＆ 循環参照防止規約", is_ok),
    ]

    for label, ok in rules:
        status = "🟢 適合 (Passed)" if ok else "🔴 違反 (Failed)"
        print(f" {label}: {status}")

    print("-" * 68)
    if is_ok:
        print(" 🟢 監査結果: 合格 (スコアイベント電子署名・改ざん隔離 ＆ ゼロトラストデータ完全性保証規約に完全適合！)")
        print("=" * 68)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (第25条 スコアイベント電子署名・改ざん隔離 ＆ ゼロトラストデータ完全性保証規約に違反があります)")
        print("=" * 68)
        print(res.stdout + res.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
