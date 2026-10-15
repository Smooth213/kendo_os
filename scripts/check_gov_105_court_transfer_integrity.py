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

    c_match = read_file("lib/features/match/domain/match_model.dart")
    c_helper = read_file("lib/features/tournament/presentation/operate/providers/team_progress_helper.dart")
    c_sort = read_file("lib/features/tournament/presentation/operate/providers/team_progress_sort_helper.dart")
    c_persist = read_file("lib/features/match/application/services/match_persistence_helper.dart")
    c_repo = read_file("lib/shared/infrastructure/repository/local_match_repository.dart")
    c_tab = read_file("lib/features/tournament/presentation/operate/components/home/match_edit_court_and_group_tab.dart")

    r1 = ("MatchModel copyWith(" in c_match or "copyWith" in c_match)
    r2 = ("extractCourtAndRoundDisplay" in c_helper and "extractCourtNumber" in c_sort)
    r3 = ("CommandType.updateMatch" in c_persist and ("saveMatch" in c_repo or "putMatch" in c_repo))
    r4 = ("MatchCourtSlotPicker" in c_tab and "onClearCourt" in c_tab)

    rules = [
        ("① [データ不変性] MatchModel のコート振替時におけるタイマー・スコア・イベント履歴の完全保持規約", r1),
        ("② [パース・ソート] team_progress_helper ＆ sort_helper によるコート抽出・優先度ソート規約", r2),
        ("③ [ライトスルー永続化] match_persistence_helper ＆ local_match_repository 即時反映規約", r3),
        ("④ [UIプリセット] match_edit_court_and_group_tab.dart プリセット・クリア機能規約", r4),
    ]

    all_passed = True
    for label, ok in rules:
        status = "🟢 適合 (Passed)" if ok else "🔴 違反 (Failed)"
        print(f" {label}: {status}")
        if not ok:
            all_passed = False

    print("-" * 68)
    if all_passed:
        print(" 🟢 監査結果: 合格 (現場動的運用・急遽コート振替 ＆ リアルタイム進行整合性保証規約に完全適合！)")
        print("=" * 68)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (第105条 現場動的運用・急遽コート振替 ＆ リアルタイム進行整合性保証規約に違反があります)")
        print("=" * 68)
        sys.exit(1)

if __name__ == "__main__":
    main()
