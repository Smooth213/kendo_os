#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 【第105条 ガバナンス監査】🔀 現場動的運用・急遽コート振替 ＆ リアルタイム進行整合性保証規約
================================================================================
① コート変更データ不変性（タイマー・スコア・イベント履歴の完全保持規約）
② 現場オペレータ即時反映（コート抽出・パース・優先度ソート整合性規約）
③ ライトスルー永続化（MatchPersistenceHelper & LocalMatchRepository 即時反映規約）
④ 試合編集タブ・UIプリセット（match_edit_court_and_group_tab.dart 規約）
"""

import subprocess
import sys

def main():
    print("=" * 68)
    print(" 📊 【第105条 ガバナンス監査】🔀 現場動的運用・急遽コート振替 ＆ リアルタイム進行整合性保証規約")
    print("=" * 68)

    cmd = [
        "flutter",
        "test",
        "test/governance/court_reassignment_governance_test.dart",
        "--reporter=expanded",
    ]

    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    is_ok = (res.returncode == 0)

    rules = [
        ("① [データ不変性] MatchModel のコート振替時におけるタイマー・スコア・イベント履歴の完全保持規約", is_ok),
        ("② [パース・ソート] team_progress_helper ＆ sort_helper によるコート抽出・優先度ソート規約", is_ok),
        ("③ [ライトスルー永続化] match_persistence_helper ＆ local_match_repository 即時反映規約", is_ok),
        ("④ [UIプリセット] match_edit_court_and_group_tab.dart プリセット・クリア機能規約", is_ok),
    ]

    for label, ok in rules:
        status = "🟢 適合 (Passed)" if ok else "🔴 違反 (Failed)"
        print(f" {label}: {status}")

    print("-" * 68)
    if is_ok:
        print(" 🟢 監査結果: 合格 (現場動的運用・急遽コート振替 ＆ リアルタイム進行整合性保証規約に完全適合！)")
        print("=" * 68)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (第105条 現場動的運用・急遽コート振替 ＆ リアルタイム進行整合性保証規約に違反があります)")
        print("=" * 68)
        print(res.stdout + res.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
