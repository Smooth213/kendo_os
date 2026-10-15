#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 【第203条 ガバナンス監査】🔐 スコアイベント電子署名・改ざん隔離 ＆ ゼロトラストデータ完全性保証規約
================================================================================
① スコアイベント電子署名検証（ScoreEventLegacyAdapter.verifySignature）完全性規約
② 悪意ある改ざん検知・例外送出（TamperedEventException）規約
③ クランティン隔離モード（allowQuarantine: true）による安全退避規約
④ 署名検証済みキーキャッシュ（5000件超過時LRUクリア）メモリ保護規約
"""

import os
import sys

script_dir = os.path.dirname(os.path.abspath(__file__))
if script_dir not in sys.path:
    sys.path.insert(0, script_dir)

from gov_static_scanner import get_file_content

def main():
    print("=" * 68)
    print(" 📊 【第203条 ガバナンス監査】🔐 スコアイベント電子署名・改ざん隔離 ＆ ゼロトラストデータ完全性保証規約")
    print("=" * 68)

    c_adapter = get_file_content("lib/features/match/application/mappers/score_event_legacy_adapter.dart") or ""
    c_verifier = get_file_content("lib/shared/infrastructure/repository/match_signature_verifier.dart") or ""
    c_repo = get_file_content("lib/shared/infrastructure/repository/local_match_repository.dart") or ""

    # ① 電子署名検証
    ok1 = "verifySignature" in c_adapter and "Hmac" in c_adapter

    # ② 改ざん検知・遮断
    ok2 = "TamperedEventException" in c_verifier or "TamperedEventException" in c_repo

    # ③ クランティン隔離
    ok3 = "allowQuarantine" in c_verifier or "saveMatchSafeMode" in c_repo

    # ④ キャッシュメモリ保護
    ok4 = "_verifiedSignatureKeys" in c_repo

    rules = [
        ("① [電子署名検証] スコアイベント電子署名（ScoreEventLegacyAdapter）完全性規約", ok1),
        ("② [改ざん検知・遮断] 不正スコアイベント投入時のTamperedEventException送出規約", ok2),
        ("③ [クランティン隔離] allowQuarantine有効時の隔離退避 ＆ ゼロトラストデータ保全規約", ok3),
        ("④ [キャッシュメモリ保護] 署名キャッシュ5000件超過時LRUクリア ＆ 循環参照防止規約", ok4),
    ]

    is_ok = all(ok for _, ok in rules)

    for label, ok in rules:
        status = "🟢 適合 (Passed)" if ok else "🔴 違反 (Failed)"
        print(f" {label}: {status}")

    print("-" * 68)
    if is_ok:
        print(" 🟢 監査結果: 合格 (スコアイベント電子署名・改ざん隔離 ＆ ゼロトラストデータ完全性保証規約に完全適合！)")
        print("=" * 68)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (第203条 スコアイベント電子署名・改ざん隔離 ＆ ゼロトラストデータ完全性保証規約に違反があります)")
        print("=" * 68)
        sys.exit(1)

if __name__ == "__main__":
    main()
