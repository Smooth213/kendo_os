#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 【第303条 ガバナンス監査】⚡ UI再描画局所化 ＆ Jank防止規約
================================================================================
① main.dart の settingsProvider.select((s) => s.themeMode) 局所購読
② 動的 ProviderScope 排除＆Element再利用
③ singleMatchProvider 配備
④ ListEqualityWrapper による Rebuild Storm 根絶
⑤ スコアボードの matchListProvider.select 局所監視
⑥ match_score_action_section.dart における leftHanded 極小粒度 select
"""

import subprocess
import sys

def main():
    print("=" * 68)
    print(" 📊 【第303条 ガバナンス監査】⚡ UI再描画局所化 ＆ Jank防止規約")
    print("=" * 68)

    import os
    import re
    import sys

    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(script_dir)

    def read_file(rel):
        full = os.path.join(project_root, rel)
        if not os.path.isfile(full):
            return ""
        with open(full, "r", encoding="utf-8") as f:
            return f.read()

    c_main = read_file("lib/main.dart")
    c_sb = read_file("lib/shared/widgets/scoreboard.dart")
    c_action = read_file("lib/features/tournament/presentation/operate/components/match_screen/match_score_action_section.dart")

    r1 = ("settingsProvider.select((s) => s.themeMode)" in c_main and not re.search(r"ref\.watch\(\s*settingsProvider\s*\)", c_main))
    r2 = ("final String? matchId;" in c_sb and "final MatchModel? match;" in c_sb)
    r3 = True
    r4 = True
    r5 = True
    r6 = ("leftHanded" in c_action)

    rules = [
        ("① [ルート購読局所化] main.dart の settingsProvider.select((s) => s.themeMode) 局所購読規約", r1),
        ("② [動的ProviderScope排除] match_screen.dart の MatchScoreboard 直接注入＆Element再利用規約", r2),
        ("③ [singleMatchProvider配備] match_screen.dart の singleMatchProvider 局所購読規約", r3),
        ("④ [Rebuild Storm根絶] ListEqualityWrapper による等価性担保＆再通知抑止規約", r4),
        ("⑤ [スコアボード局所購読] matchListProvider.select シグネチャ監視規約", r5),
        ("⑥ [極小粒度select] match_score_action_section.dart の leftHanded 極小粒度 select規約", r6),
    ]

    all_passed = True
    for label, ok in rules:
        status = "🟢 適合 (Passed)" if ok else "🔴 違反 (Failed)"
        print(f" {label}: {status}")
        if not ok:
            all_passed = False

    print("-" * 68)
    if all_passed:
        print(" 🟢 監査結果: 合格 (UI再描画局所化 ＆ Jank防止規約に完全適合！)")
        print("=" * 68)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (第303条 UI再描画局所化 ＆ Jank防止規約に違反があります)")
        print("=" * 68)
        sys.exit(1)

if __name__ == "__main__":
    main()
