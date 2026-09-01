#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ==============================================================================
# 🥋 kendo OS - 【ガバナンス監査 9/10】🏗️ アーキテクチャ境界＆疎結合 監査スクリプト
# ==============================================================================
import subprocess
import sys

def run_architecture_governance():
    # 1. validate_architecture.dart (廃止ディレクトリ参照禁止)
    dart_cmd = ["dart", "run", "scripts/validate_architecture.dart"]
    dart_res = subprocess.run(dart_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    
    # 2. observability_crash_test.dart (モジュール疎結合保証)
    test_cmd = ["flutter", "test", "test/unit/observability_crash_test.dart", "--reporter=expanded"]
    test_res = subprocess.run(test_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    
    passed_all = (dart_res.returncode == 0 and test_res.returncode == 0)

    rules = [
        ("1. 廃止パス（package:kendo_os/core/ 等）混入ゼロ規約", dart_res.returncode == 0),
        ("2. 構造化ログ・例外検知時コンテキスト完全保持規約", test_res.returncode == 0),
        ("3. 8時間連続運用・大量データメモリリーク防止規約", test_res.returncode == 0),
        ("4. Core/Dojo/Expedition/Tournament モジュール疎結合境界規約", test_res.returncode == 0),
    ]

    print("=" * 60)
    print(" 📊 【ガバナンス監査 9/10】🏗️ アーキテクチャ境界＆疎結合 監査レポート")
    print("=" * 60)

    for label, is_ok in rules:
        status = "🟢 適合 (Passed)" if is_ok else "🔴 違反 (Failed)"
        print(f" {label}: {status}")

    print("-" * 60)
    if passed_all:
        print(" 🟢 監査結果: 合格 (アーキテクチャ境界・モジュール疎結合に完全適合！)")
        print("=" * 60)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (アーキテクチャ境界違反が検出されました)")
        print("=" * 60)
        if dart_res.returncode != 0:
            print(dart_res.stdout + dart_res.stderr)
        if test_res.returncode != 0:
            print(test_res.stdout + test_res.stderr)
        sys.exit(1)

if __name__ == "__main__":
    run_architecture_governance()
