#!/usr/bin/env python3
# ==============================================================================
# 🥋 kendo OS - 【ガバナンス監査 4/4】剣道メタデータ（シーン・選手名・結果タグ） 監査スクリプト
# ==============================================================================
import os
import subprocess
import sys

def run_metadata_governance_check():
    cmd = ["flutter", "test", "test/governance/kendo_core_governance_test.dart", "--reporter=expanded"]
    result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    
    output = result.stdout + result.stderr
    
    rules = [
        ("1. 道場名・選手名パース（コロン・括弧正規化）規約", "1. 【名前パース規約】"),
        ("2. 試合シーンバッジ（本戦/錬成/申合せ/部内戦）規約", "2. 【シーンバッジ規約】"),
        ("3. 試合結果ステータスタグ（延長/代表戦/不戦勝）規約", "3. 【結果タグ規約】"),
        ("4. 団体戦・個人戦 表示文字列決定論的生成規約", "団体/個人表示が決定論的に生成されること"),
    ]
    
    passed_all = (result.returncode == 0)
    
    print("=" * 60)
    print(" 📊 【ガバナンス監査 4/10】📛 剣道メタデータ（シーン・選手名・結果タグ） 監査レポート")
    print("=" * 60)
    
    for label, pattern in rules:
        if passed_all:
            status = "🟢 適合 (Passed)"
        else:
            if pattern in output and "[E]" in output:
                status = "🔴 違反 (Failed)"
            else:
                status = "🟢 適合 (Passed)"
        print(f" {label}: {status}")
        
    print("-" * 60)
    if passed_all:
        print(" 🟢 監査結果: 合格 (すべての剣道メタデータ規約に完全適合！)")
        print("=" * 60)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (剣道メタデータ規約に違反が検出されました)")
        print("=" * 60)
        from test_failure_formatter import parse_and_format_failures
        print(parse_and_format_failures(output))
        sys.exit(1)

if __name__ == "__main__":
    run_metadata_governance_check()
