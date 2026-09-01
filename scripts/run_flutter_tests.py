#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ==============================================================================
# 🥋 Kendo OS - 全テスト実行 ＆ 失敗ピンポイント表示ランナー
# ==============================================================================
import subprocess
import sys
from test_failure_formatter import parse_and_format_failures

def run_all_tests():
    print("🧪 Flutter 全テストスイート完全実行中...")
    
    # リアルタイムで出力を流しつつ全体をキャプチャ
    process = subprocess.Popen(
        ["flutter", "test"],
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1
    )
    
    captured_output = []
    for line in iter(process.stdout.readline, ''):
        print(line, end='', flush=True)
        captured_output.append(line)
        
    process.stdout.close()
    return_code = process.wait()
    
    if return_code != 0:
        full_output = "".join(captured_output)
        print("\n")
        print(parse_and_format_failures(full_output))
        print("\n🚨 【プッシュ拒否】テストエラーが検出されたため、プッシュを中断しました。")
        sys.exit(1)
    else:
        print("\n================================================================")
        print(" 🎉 祝！全テストスイート (100% ALL PASS) を完全クリアしました！")
        print("    安全にリモートへのプッシュを実行します。")
        print("================================================================\n")
        sys.exit(0)

if __name__ == "__main__":
    run_all_tests()
