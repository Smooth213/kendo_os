#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ==============================================================================
# 🥋 Kendo OS - フェイルファスト・ガバナンス監査 ＆ テストランナー (TTY カラー保持)
# ==============================================================================
# 手動テスト実行時は事前にガバナンス監査（行数・トークン・静的解析）を即時検証。
# git push などの連携時は --skip-governance で2重実行を自動回避します。
# ==============================================================================
import datetime
import os
import pty
import re
import subprocess
import sys
from test_failure_formatter import parse_and_format_failures

def run_governance_pre_check():
    """テスト実行前のガバナンス監査（Fail-Fast Gate）"""
    print("=" * 64)
    print(" 🛡️  Kendo OS - テスト事前ガバナンス監査 (Fail-Fast Gate)")
    print("=" * 64)
    
    checks = [
        ("📏 コード行数監査 (500行上限)", ["python3", "scripts/check_file_lines.py"]),
        ("🎨 23大デザイントークン厳格監査", ["python3", "scripts/check_design_tokens.py", "--strict"]),
        ("🔍 Flutter 静的解析 (警告ゼロ確認)", ["flutter", "analyze"]),
    ]
    
    for name, cmd in checks:
        print(f"\n▶ 実行中: {name}...")
        result = subprocess.run(cmd)
        if result.returncode != 0:
            print(f"\n🚨 【テスト中断】{name} で違反または警告が検出されました！")
            print("   テストの実行を直ちに停止しました（テスト待機時間ゼロ）。")
            print("   指摘された箇所を修正した上で、再度実行してください。\n")
            sys.exit(1)
            
    print("\n" + "=" * 64)
    print(" 🟢 すべての事前ガバナンス監査をクリアしました！テストへ進みます。")
    print("=" * 64 + "\n")

def run_all_tests():
    raw_args = sys.argv[1:]
    skip_governance = False
    test_args = []
    
    for arg in raw_args:
        if arg == "--skip-governance":
            skip_governance = True
        else:
            test_args.append(arg)
            
    # pre-commit で既に監査済みの git push 時などはスキップし2重実行を防止
    if not skip_governance:
        run_governance_pre_check()
    else:
        print("💡 [Info] コミット時ガバナンス監査済みのため、重複実行をスキップしてテストを開始します。\n")
    
    cmd = ["flutter", "test", "-j", "6", "--no-pub"] + test_args
    print(f"🧪 Flutter テストスイート完全実行中... ({' '.join(cmd)})\n")
    
    master, slave = pty.openpty()
    process = subprocess.Popen(
        cmd,
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
    
    full_output = captured_bytes.decode('utf-8', errors='ignore')
    clean_output = re.sub(r'\x1b\[[0-9;]*[a-zA-Z]', '', full_output)
    log_file_path = "test_last_run.log"
    timestamp_str = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    failure_summary = ""
    if return_code != 0:
        failure_summary = parse_and_format_failures(full_output)

    try:
        with open(log_file_path, "w", encoding="utf-8") as f:
            f.write("=" * 64 + "\n")
            f.write(f"🥋 Kendo OS - Flutter テスト実行ログ ({timestamp_str})\n")
            f.write(f"コマンド: {' '.join(cmd)}\n")
            f.write(f"実行結果: {'🔴 失敗 (FAILED)' if return_code != 0 else '🟢 全件成功 (SUCCESS)'}\n")
            f.write("=" * 64 + "\n\n")
            f.write(clean_output)
            if failure_summary:
                f.write("\n\n" + failure_summary + "\n")
    except Exception as e:
        print(f"⚠️ ログファイルの保存に失敗しました: {e}")

    if return_code != 0:
        print("\n")
        print(failure_summary)
        print(f"\n📄 テスト実行ログ全体を '{log_file_path}' に上書き保存しました。")
        print("🚨 【処理中断】テストエラーが検出されたため、処理を中断しました。")
        sys.exit(1)
    else:
        print("\n================================================================")
        print(" 🎉 祝！ガバナンス監査 ＆ 全テストスイート (100% PASS) を完全クリア！")
        print(f" 📄 テスト実行ログ全体を '{log_file_path}' に上書き保存しました。")
        print("================================================================\n")
        sys.exit(0)

if __name__ == "__main__":
    run_all_tests()
