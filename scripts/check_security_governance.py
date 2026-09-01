#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ==============================================================================
# 🥋 kendo OS - 【ガバナンス監査 6/10】🔒 セキュリティ＆ロール露出規制 監査スクリプト
# ==============================================================================
import subprocess
import sys

def run_security_governance():
    cmd = [
        "flutter", "test",
        "test/widget/role_visibility_test.dart",
        "test/widget/hidden_feature_access_test.dart",
        "test/widget/ai_feature_hidden_test.dart",
        "test/widget/internal_metrics_hidden_test.dart",
        "--reporter=expanded"
    ]
    result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    output = result.stdout + result.stderr
    passed_all = (result.returncode == 0)

    rules = [
        ("1. Viewer/Operator 権限制御・管理ボタン物理排除", "Viewerモード時、新規作成ボタンが画面上から物理排除"),
        ("2. Feature Flag & DeepLink URL直打ち直接アクセス遮断", "直接URLアクセス（DeepLink）が物理拒否"),
        ("3. AI機能（AiHelpService）完全封鎖・アクセス制限", "AI Runtime 完全封鎖検証テスト"),
        ("4. 内部デバッグメトリクス・安心日本語同期表現規約", "内部メトリクス隠蔽"),
    ]

    print("=" * 60)
    print(" 📊 【ガバナンス監査 6/10】🔒 セキュリティ＆ロール露出規制 監査レポート")
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
        print(" 🟢 監査結果: 合格 (セキュリティ＆ロール露出規制に完全適合！)")
        print("=" * 60)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (セキュリティ＆ロール露出規制に違反が検出されました)")
        print("=" * 60)
        from test_failure_formatter import parse_and_format_failures
        print(parse_and_format_failures(output))
        sys.exit(1)

if __name__ == "__main__":
    run_security_governance()
