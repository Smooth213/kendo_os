#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ==============================================================================
# 🥋 kendo OS - 【ガバナンス監査 12/14】📄 PDF組版・長文字列あふれ・改ページ安全 監査スクリプト
# ==============================================================================
import subprocess
import sys

def run_pdf_layout_safety_governance():
    test_files = [
        "test/widget/pdf_long_name_overflow_test.dart",
        "test/widget/pdf_page_layout_helper_test.dart",
    ]

    cmd = ["flutter", "test"] + test_files + ["--reporter=expanded"]
    result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    output = result.stdout + result.stderr

    passed_all = (result.returncode == 0)

    rules = [
        ("1. 極長道場名（50文字超）動的フォントスケール＆省略記号（…）適用規約", passed_all),
        ("2. 極長選手名（30文字超）縦書き最大8文字ガード規約", passed_all),
        ("3. 100試合超大量データ 自動改ページ＆TooManyPagesExceptionゼロ保証規約", passed_all),
        ("4. 対戦表ブロック pw.Container 改ページ寸断防止規約", passed_all),
    ]

    print("=" * 60)
    print(" 📊 【ガバナンス監査 12/14】📄 PDF組版・長文字列あふれ・改ページ安全 監査レポート")
    print("=" * 60)

    for label, is_ok in rules:
        status = "🟢 適合 (Passed)" if is_ok else "🔴 違反 (Failed)"
        print(f" {label}: {status}")

    print("-" * 60)
    if passed_all:
        print(" 🟢 監査結果: 合格 (PDF組版・長文字列あふれ・改ページ安全規約に完全適合！)")
        print("=" * 60)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (PDF組版・改ページ安全規約違反またはテスト失敗が検出されました)")
        print("=" * 60)
        from test_failure_formatter import parse_and_format_failures
        print(parse_and_format_failures(output))
        sys.exit(1)

if __name__ == "__main__":
    run_pdf_layout_safety_governance()
