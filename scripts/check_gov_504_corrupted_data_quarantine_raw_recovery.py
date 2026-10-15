#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 【第504条 ガバナンス監査】🚨 障害データ隔離（Quarantine）・フェイルセーフ二次破壊完全阻止 ＆ 生データ救済規約
================================================================================
① 破損状態における編集完全ロック（打突・タイマー・操作遮断）規約
② リアルタイムViewer継続閲覧（電波障害・現地パニック防止）規約
③ 生データ（イベントログ）救済エクスポート許可 ＆ 赤色警告バナー表示規約
"""

import os
import sys

script_dir = os.path.dirname(os.path.abspath(__file__))
if script_dir not in sys.path:
    sys.path.insert(0, script_dir)

from gov_static_scanner import get_file_content

def main():
    print("=" * 68)
    print(" 📊 【第504条 ガバナンス監査】🚨 障害データ隔離（Quarantine）・フェイルセーフ二次破壊完全阻止 ＆ 生データ救済規約")
    print("=" * 68)

    c_state = get_file_content("lib/shared/domain/entities/match_corrupted_state.dart") or ""
    c_ex = get_file_content("lib/shared/domain/entities/match_corruption_exception.dart") or ""
    c_banner = get_file_content("lib/shared/widgets/corrupted_match_banner.dart") or ""

    # ① 二次破壊完全阻止: isCorrupted, allowEdit=false
    ok1 = (
        "class MatchCorruptedState" in c_state
        and "bool get isCorrupted" in c_state
        and "bool get allowEdit => !isCorrupted;" in c_state
        and "class MatchCorruptionException" in c_ex
    )

    # ② 現地パニック防止: allowViewer 閲覧継続許可
    ok2 = "bool get allowViewer => true;" in c_state

    # ③ 生データ救済: allowExport ＆ 赤色警告バナー
    ok3 = (
        "bool get allowExport => isCorrupted;" in c_state
        and "class CorruptedMatchBanner" in c_banner
        and "Icons.error_outline_rounded" in c_banner
    )

    rules = [
        ("① [二次破壊完全阻止] 破損試合における編集・打突・タイマー完全ロック規約", ok1),
        ("② [現地パニック防止] 観戦用Viewer画面でのリアルタイム状況閲覧継続規約", ok2),
        ("③ [フェイルセーフ救済] 生データテキスト書き出し許可 ＆ 赤色警告バナー規約", ok3),
    ]

    is_ok = all(ok for _, ok in rules)

    for label, ok in rules:
        status = "🟢 適合 (Passed)" if ok else "🔴 違反 (Failed)"
        print(f" {label}: {status}")

    print("-" * 68)
    if is_ok:
        print(" 🟢 監査結果: 合格 (障害データ隔離・フェイルセーフ二次破壊完全阻止 ＆ 生データ救済規約に完全適合！)")
        print("=" * 68)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (第504条 障害データ隔離・フェイルセーフ二次破壊完全阻止 ＆ 生データ救済規約に違反があります)")
        print("=" * 68)
        sys.exit(1)

if __name__ == "__main__":
    main()
