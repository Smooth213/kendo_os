#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 【第9条 ガバナンス監査】⚡ UI再描画局所化 ＆ Jank防止規約
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
    print(" 📊 【第9条 ガバナンス監査】⚡ UI再描画局所化 ＆ Jank防止規約")
    print("=" * 68)

    cmd = [
        "flutter",
        "test",
        "test/governance/ui_rebuild_governance_test.dart",
        "--reporter=expanded",
    ]

    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    is_ok = (res.returncode == 0)

    rules = [
        ("① [ルート購読局所化] main.dart の settingsProvider.select((s) => s.themeMode) 局所購読規約", is_ok),
        ("② [動的ProviderScope排除] match_screen.dart の MatchScoreboard 直接注入＆Element再利用規約", is_ok),
        ("③ [singleMatchProvider配備] match_screen.dart の singleMatchProvider 局所購読規約", is_ok),
        ("④ [Rebuild Storm根絶] ListEqualityWrapper による等価性担保＆再通知抑止規約", is_ok),
        ("⑤ [スコアボード局所購読] matchListProvider.select シグネチャ監視規約", is_ok),
        ("⑥ [極小粒度select] match_score_action_section.dart の leftHanded 極小粒度 select規約", is_ok),
    ]

    for label, ok in rules:
        status = "🟢 適合 (Passed)" if ok else "🔴 違反 (Failed)"
        print(f" {label}: {status}")

    print("-" * 68)
    if is_ok:
        print(" 🟢 監査結果: 合格 (UI再描画局所化 ＆ Jank防止規約に完全適合！)")
        print("=" * 68)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (第9条 UI再描画局所化 ＆ Jank防止規約に違反があります)")
        print("=" * 68)
        print(res.stdout + res.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
