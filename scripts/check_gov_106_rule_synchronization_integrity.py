#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 【第106条 ガバナンス監査】🔄 全ルール設定画面間相互完全同期 ＆ 先祖返り・上書き防止規約
================================================================================
① 静的コード完全配線規約（全 StateHolder / Helper / Summary / Form に skipEmptyRoster 等の実装保証）
② 一括ルール設定完全同期規約（BulkRuleStateHolder ＆ buildNewRule での全プロパティ保持）
③ 個別試合編集差分更新規約（MatchEditStateHolder ＆ MatchEditSaveHelper での既存値保持）
④ 対戦フォーマット設定同期規約（MatchFormatFormState ＆ MatchFormatSaveHelper の完全マッピング）
⑤ 部門別ルール設定同期規約（CategoryRulesFormState ＆ CategoryRuleMatchHelper のシーン別整合性）
"""

import subprocess
import sys

def main():
    print("=" * 68)
    print(" 📊 【第106条 ガバナンス監査】🔄 全ルール設定画面間相互完全同期 ＆ 先祖返り・上書き防止規約")
    print("=" * 68)

    cmd = [
        "python3",
        "scripts/gov_test_helper.py",
        "test/governance/rule_cross_screen_synchronization_governance_test.dart",
        "--reporter=expanded",
    ]

    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    is_ok = (res.returncode == 0)

    rules = [
        ("① [静的コード完全網羅] 全ルール編集画面および全表示画面に同期項目が欠落なく配線されていること", is_ok),
        ("② [全画面循環同期保証] 全ルール編集画面間を循環同期しても全プロパティが欠落・先祖返りしないこと", is_ok),
        ("③ [試合情報表示同期] RuleInfoBottomSheet に編集された全ルールが同期されて表示されること", is_ok),
        ("④ [フォーマット表示同期] MatchFormatRuleSummaryCard に編集された全ルールが同期されて表示されること", is_ok),
        ("⑤ [試合一覧表示同期] MatchRuleSummaryCard に編集された全ルールが同期されて表示されること", is_ok),
        ("⑥ [部門別詳細表示同期] CategoryRuleSummaryCard に編集された全ルールが同期されて表示されること", is_ok),
    ]

    for label, ok in rules:
        status = "🟢 適合 (Passed)" if ok else "🔴 違反 (Failed)"
        print(f" {label}: {status}")

    print("-" * 68)
    if is_ok:
        print(" 🟢 監査結果: 合格 (全ルール設定画面間相互完全同期 ＆ 先祖返り・上書き防止規約に完全適合！)")
        print("=" * 68)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (第106条 全ルール設定画面間相互完全同期 ＆ 先祖返り・上書き防止規約に違反があります)")
        print("=" * 68)
        print(res.stdout + res.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
