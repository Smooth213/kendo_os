#!/usr/bin/env python3
# ==============================================================================
# 🥋 kendo OS - 【ガバナンス監査 3/4】剣道公式スコア表示＆PDF描画 監査スクリプト
# ==============================================================================
import os
import subprocess
import sys
from gov_static_scanner import GovStaticScanner


def run_score_governance_check():
    scanner = GovStaticScanner()
    static_errors = []

    # 1. 静的検査: 丸囲み除外条件に「反」が誤混入していないこと
    score_box_src = scanner.read_file("lib/shared/presentation/widgets/kendo_score_box.dart")
    pdf_team_src = scanner.read_file("lib/features/pdf/widgets/pdf_team_table_cell_renderer.dart")
    pdf_league_src = scanner.read_file("lib/features/pdf/widgets/pdf_league_table.dart")

    if score_box_src and "mark == '反'" in score_box_src:
        static_errors.append("kendo_score_box.dart: isSpecialNonCircle に '反' が含まれています（先取丸囲み禁止違反）")
    if pdf_team_src and "p.mark == '反'" in pdf_team_src:
        static_errors.append("pdf_team_table_cell_renderer.dart: isSpecialFusenOrDraw に '反' が含まれています")
    if pdf_league_src and "displayTech != '反'" in pdf_league_src:
        static_errors.append("pdf_league_table.dart: displayTech != '反' による先取丸囲み除外が存在します")

    # 2. 静的検査: 不戦勝が「◎」に誤変換されていないこと
    bunaiksen_marks_src = scanner.read_file("lib/features/tournament/presentation/components/bunaiksen/bunaiksen_score_marks.dart")
    viewer_bunaiksen_src = scanner.read_file("lib/features/viewer/components/viewer_bunaiksen_match_card.dart")

    if bunaiksen_marks_src and "'◎'" in bunaiksen_marks_src:
        static_errors.append("bunaiksen_score_marks.dart: 不戦勝で '◎' への変換が検出されました（不戦勝は◯が正本）")
    if viewer_bunaiksen_src and "'◎'" in viewer_bunaiksen_src:
        static_errors.append("viewer_bunaiksen_match_card.dart: 不戦勝で '◎' への変換が検出されました")

    # 3. テスト実行
    cmd = ["python3", "scripts/gov_test_helper.py", "test/governance/kendo_score_display_governance_test.dart", "--reporter=expanded"]
    result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

    output = result.stdout + result.stderr

    rules = [
        ("1. Table斜め配置（1本目左上 / 2本目右下）", "1. 【Tableバリアント】"),
        ("2. 先取打突 丸囲み（◯）付与規約", "2. 【先取丸囲み規約】"),
        ("3. 特殊記号（◯・×・△）丸囲み除外 ＆ 反則(反)先取丸囲み完全保証規約", "先取丸囲み規約において"),
        ("4. 勝者打突枠 勝者丸（◯）描画規約", "勝者丸が描画されること"),
        ("5. Inline形式（チーム試合状況・タイムライン）", "3. 【Inlineバリアント】"),
        ("6. Scoreboard特大視認性モード規約", "4. 【Scoreboardバリアント】"),
        ("7. PDF勝者円（25px）境界はみ出しゼロ保証", "5. 【PDF描画規約】"),
        ("8. 不戦勝純粋◯（◎二重丸変換完全禁止）規約", "不戦勝規約において"),
    ]

    passed_all = (result.returncode == 0) and (len(static_errors) == 0)

    print("=" * 60)
    print(" 📊 【ガバナンス監査 3/10】🥋 剣道公式スコア表示＆PDF描画 監査レポート")
    print("=" * 60)

    for label, pattern in rules:
        if passed_all:
            status = "🟢 適合 (Passed)"
        else:
            if (pattern in output and "[E]" in output) or any(pattern in e for e in static_errors):
                status = "🔴 違反 (Failed)"
            else:
                status = "🟢 適合 (Passed)"
        print(f" {label}: {status}")

    print("-" * 60)
    if passed_all:
        print(" 🟢 監査結果: 合格 (すべての剣道公式スコア表示＆PDF規約に完全適合！)")
        print("=" * 60)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (剣道公式スコア表示・PDF描画に違反が検出されました)")
        print("=" * 60)
        if static_errors:
            print("【静的検査違反】:")
            for err in static_errors:
                print(f"  ❌ {err}")
        if result.returncode != 0:
            from test_failure_formatter import parse_and_format_failures
            print(parse_and_format_failures(output))
        sys.exit(1)


if __name__ == "__main__":
    run_score_governance_check()
