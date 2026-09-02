#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ==============================================================================
# 🥋 Kendo OS - 全テスト実行 ＆ 失敗ピンポイント表示ランナー (TTY カラー保持)
# ==============================================================================
import os
import pty
import sys
from test_failure_formatter import parse_and_format_failures

def run_all_tests():
    print("🧪 Flutter 全テストスイート完全実行中...\n")
    
    master, slave = pty.openpty()
    
    import subprocess
    process = subprocess.Popen(
        ["flutter", "test"],
        stdin=slave,
        stdout=slave,
        stderr=slave,
        close_fds=True
    )
    os.close(slave)
    
    captured_bytes = bytearray()
    while True:
        try:
            data = os.read(master, 1024)
            if not data:
                break
            os.write(sys.stdout.fileno(), data)
            sys.stdout.flush()
            captured_bytes.extend(data)
        except OSError:
            break
            
    os.close(master)
    return_code = process.wait()
    
    if return_code != 0:
        full_output = captured_bytes.decode('utf-8', errors='ignore')
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
