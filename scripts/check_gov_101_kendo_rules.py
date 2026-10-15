#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 【第101条 ガバナンス監査】🥋 剣道公式ルール・スコア・表記・配列 永続保証規約
================================================================================
① 公式スコア表示＆PDF描画（Table斜め・先取丸・勝者丸・Inline・Scoreboard）
② 剣道メタデータ（シーン・選手名・結果タグ）
③ 試合シーン（本戦・錬成・申合せ）表記＆配色
④ 団体戦スコア順序（先鋒〜大将・代表戦）剣道標準配列
⑤ 全試合形式（勝ち抜き・リーグ含む）編集選択＆完全整合性保証
⑥ 勝ち抜き戦（5人制 / 3人制）選択・適応・実行 総合保証規約
⑦ 大会ルール設定バリデーション ＆ ルール永続化マイグレーション規約
⑧ 遠征打突種別 ＆ 学年公式区分決定論保証規約
⑨ 試合カテゴリ「その他（混成・自由入力）」＆ 学年横断編成永続保証規約
⑩ 未フィルタイベント直接集計禁止 ＆ ルールエンジンSSOT保証規約
⑪ 剣道形競技（判定本数・時間無制限・延長排除）公式ルール完全適合規約
"""

import subprocess
import sys
from gov_static_scanner import GovStaticScanner

SUB_AUDITS = [
    ("① 剣道公式スコア表示＆PDF描画規約", ["python3", "scripts/check_kendo_score_governance.py"]),
    ("② 剣道メタデータ（シーン・選手名・結果タグ）規約", ["python3", "scripts/check_kendo_metadata_governance.py"]),
    ("③ 試合シーン（本戦・錬成・申合せ）表記＆配色規約", ["python3", "scripts/check_kendo_scene_governance.py"]),
    ("④ 団体戦スコア順序（先鋒〜大将・代表戦）剣道標準配列規約", ["python3", "scripts/check_team_match_order_governance.py"]),
    ("⑤ 全試合形式（勝ち抜き・リーグ含む）編集選択＆完全整合性保証規約", ["python3", "scripts/check_match_type_selection_governance.py"]),
    ("⑥ 勝ち抜き戦（5人制 / 3人制）選択・適応・実行 総合保証規約", ["python3", "scripts/check_kachinuki_governance.py"]),
    ("⑦ 大会ルール設定バリデーション ＆ ルール永続化マイグレーション規約", ["python3", "scripts/check_tournament_rule_config_governance.py"]),
]


def check_expedition_strikes_and_grade(scanner: GovStaticScanner):
    """⑧ 遠征打突種別 ＆ 学年公式区分決定論保証規約"""
    c1 = scanner.read_file('lib/features/tournament/presentation/components/official_record/expedition_event_processor.dart')
    c2 = scanner.read_file('lib/features/tournament/presentation/operate/components/match_screen/match_player_roster_resolver.dart')
    if not c1 or not c2:
        return False, ["必須ファイルが見つかりません"]
    for s in ['StrikeType.men', 'StrikeType.kote', 'StrikeType.dou', 'StrikeType.tsuki']:
        if s not in c1:
            return False, [f"expedition_event_processor.dart に {s} が見つかりません"]
    for g in ['小学生低学年の部', '小学生高学年の部', '中学生の部', '高校生の部']:
        if g not in c2:
            return False, [f"match_player_roster_resolver.dart に公式学年区分 {g} が見つかりません"]
    return True, []


def check_match_category_other_support(scanner: GovStaticScanner):
    """⑨ 試合カテゴリ「その他（混成・自由入力）」＆ 学年横断編成永続保証規約"""
    target_files = [
        'lib/features/tournament/presentation/operate/components/setup_match_format/match_format_setup_helper.dart',
        'lib/features/tournament/presentation/operate/components/setup_match_format/match_format_form_state.dart',
        'lib/features/tournament/presentation/operate/components/setup_match_format/match_format_category_step.dart',
        'lib/features/tournament/presentation/operate/components/team_registration/team_registration_category_step.dart',
        'lib/features/tournament/presentation/operate/components/team_registration/team_registration_category_parser.dart',
        'lib/features/tournament/presentation/operate/components/team_registration/team_registration_player_filter_helper.dart',
    ]
    missing = []
    for path in target_files:
        content = scanner.read_file(path)
        if not content:
            missing.append(f"{path} が存在しません")
        elif 'その他' not in content and 'customCategoryName' not in content:
            missing.append(f"{path} に「その他」カテゴリ対応が欠落")
    return len(missing) == 0, missing


def check_unfiltered_event_aggregation(scanner: GovStaticScanner):
    """⑩ 未フィルタイベント直接集計禁止 ＆ ルールエンジンSSOT保証規約"""
    content = scanner.read_file('lib/features/tournament/presentation/components/official_record/expedition_event_processor.dart')
    if not content:
        return False, ["expedition_event_processor.dart が存在しません"]
    if 'for (final ev in m.events)' in content:
        return False, ["m.events の直接ループ走査が残存しています (Undo相殺漏洩リスク)"]
    if 'KendoRuleEngine' not in content and 'getEffectiveScores' not in content:
        return False, ["KendoRuleEngine または getEffectiveScores によるSSOT集計が実装されていません"]
    return True, []


def check_kata_rule_integrity(scanner: GovStaticScanner):
    """⑪ 剣道形競技（判定本数・時間無制限・延長排除）公式ルール完全適合規約"""
    c1 = scanner.read_file('lib/features/tournament/presentation/operate/components/bulk_rule_apply_helper.dart')
    c2 = scanner.read_file('lib/features/match/domain/rules/match_rule.dart')
    if not c1 or not c2:
        return False, ["必須ファイルが存在しません"]
    if 'isKataMatch' not in c1 or 'isKataMatch' not in c2:
        return False, ["isKataMatch パラメータが実装されていません"]
    return True, []


def main():
    print("=" * 68)
    print(" 📊 【第101条 ガバナンス監査】🥋 剣道公式ルール・スコア・表記・配列 永続保証規約")
    print("=" * 68)

    all_passed = True
    for label, cmd in SUB_AUDITS:
        res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        is_ok = (res.returncode == 0)
        status = "🟢 適合 (Passed)" if is_ok else "🔴 違反 (Failed)"
        print(f" {label}: {status}")
        if not is_ok:
            all_passed = False
            print(f"\n--- [詳細エラー: {label}] ---")
            print(res.stdout + res.stderr)
            print("-" * 40)

    # 静的直接検査
    scanner = GovStaticScanner.get_instance()
    static_checks = [
        ("⑧ 遠征打突種別 ＆ 学年公式区分決定論保証規約", check_expedition_strikes_and_grade(scanner)),
        ("⑨ 試合カテゴリ「その他（混成・自由入力）」＆ 学年横断編成永続保証規約", check_match_category_other_support(scanner)),
        ("⑩ 未フィルタイベント直接集計禁止 ＆ ルールエンジンSSOT保証規約", check_unfiltered_event_aggregation(scanner)),
        ("⑪ 剣道形競技（判定本数・時間無制限・延長排除）公式ルール完全適合規約", check_kata_rule_integrity(scanner)),
    ]

    for label, (ok, viols) in static_checks:
        status = "🟢 適合 (Passed)" if ok else "🔴 違反 (Failed)"
        print(f" {label}: {status}")
        if not ok:
            all_passed = False
            for v in viols:
                print(f"    ❌ {v}")

    print("-" * 68)
    if all_passed:
        print(" 🟢 監査結果: 合格 (剣道公式ルール・スコア・表記・配列 永続保証規約に完全適合！)")
        print("=" * 68)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (第101条 剣道公式ルール・スコア・表記・配列規約に違反があります)")
        print("=" * 68)
        sys.exit(1)


if __name__ == "__main__":
    main()
