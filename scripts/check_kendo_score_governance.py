#!/usr/bin/env python3
# ==============================================================================
# 🥋 kendo OS - 剣道スコア表示・PDFガバナンス監査スクリプト
# ==============================================================================
import os
import subprocess
import sys

def run_score_governance_check():
    print("🥋 kendo OS 剣道スコア表示・PDFガバナンス自動監査を実行中...")
    
    cmd = ["flutter", "test", "test/governance/kendo_score_display_governance_test.dart", "--reporter=expanded"]
    result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    
    output = result.stdout + result.stderr
    
    rules = [
        ("1. Table斜め配置（1本目左上 / 2本目右下）", "1. 【Tableバリアント】"),
        ("2. 先取打突 丸囲み（◯）付与規約", "2. 【先取丸囲み規約】"),
        ("3. 特殊打突（反・◯・×）丸囲み除外規約", "反則(反)・不戦勝(◯)・引き分け(×)は丸囲みされない"),
        ("4. 勝者打突枠 勝者丸（◯）描画規約", "勝者丸が描画されること"),
        ("5. Inline形式（チーム試合状況・タイムライン）", "3. 【Inlineバリアント】"),
        ("6. Scoreboard特大視認性モード規約", "4. 【Scoreboardバリアント】"),
        ("7. PDF勝者円（25px）境界はみ出しゼロ保証", "5. 【PDF描画規約】"),
    ]
    
    passed_all = (result.returncode == 0)
    
    print("==================================================")
    print(" 📊 kendo OS 剣道スコア表示・PDF 監査レポート")
    print("==================================================")
    
    for label, pattern in rules:
        if passed_all:
            status = "🟢 適合 (Passed)"
        else:
            if pattern in output and "[E]" in output:
                status = "🔴 違反 (Failed)"
            else:
                status = "🟢 適合 (Passed)"
        print(f" {label}: {status}")
        
    print("--------------------------------------------------")
    if passed_all:
        print(" 🟢 監査結果: すべての剣道スコア規約に完全合格！")
        print("==================================================")
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 剣道スコア表示・PDF規約に違反が検出されました！")
        print("==================================================")
        print(output)
        sys.exit(1)

if __name__ == "__main__":
    run_score_governance_check()
