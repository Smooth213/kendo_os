#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ==============================================================================
# 🥋 kendo OS - 【ガバナンス監査 19/19】📱 iOS PWA WebKitタッチ座標同期＆ロール選択画面 監査スクリプト
# ==============================================================================
import subprocess
import sys

def run_ios_pwa_touch_sync_governance():
    test_files = [
        "test/unit/web_pwa_touch_sync_governance_test.dart",
        "test/widget/role_select_screen_regression_test.dart",
    ]

    # 🛡️ 1. Flutter テストの実行
    cmd = ["flutter", "test"] + test_files + ["--reporter=expanded"]
    result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    flutter_passed = (result.returncode == 0)

    # 🛡️ 2. Node.js による TouchSync v4.0 実機誤加算バグ動的シミュレーションテストの実行
    node_cmd = ["node", "test/unit/test_ios_pwa_touch_sync_simulation.js"]
    node_result = subprocess.run(node_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    node_passed = (node_result.returncode == 0)

    passed_all = flutter_passed and node_passed

    rules = [
        ("1. iOS PWA エッジ・トゥ・エッジ全画面モード (black-translucent / viewport-fit=cover) 規約", flutter_passed),
        ("2. WebKit 起動直後タッチ座標ズレ防止 TouchSync v4.0 Perfect Snap 物理スナップ規約", flutter_passed),
        ("3. WebKit 誤加算バグ(+54px) 動的注入＆物理スナップ実証シミュレーション規約", node_passed),
        ("4. ロール選択画面 全4権限ボタン常時活性化 (Anti-Disable) 規約", flutter_passed),
        ("5. スワイプバック・Pop画面復帰時 操作性即時維持規約", flutter_passed),
        ("6. タップ領域 56px確保＆Bounding Box 重複完全排除規約", flutter_passed),
        ("7. 600ms デバウンス連打防止＆時間経過後受付規約", flutter_passed),
    ]

    print("=" * 60)
    print(" 📊 【ガバナンス監査 19/19】📱 iOS PWA WebKitタッチ座標同期＆ロール選択画面 監査レポート")
    print("=" * 60)

    for label, is_ok in rules:
        status = "🟢 適合 (Passed)" if is_ok else "🔴 違反 (Failed)"
        print(f" {label}: {status}")

    print("-" * 60)
    if passed_all:
        print(" 🟢 監査結果: 合格 (iOS PWA TouchSync座標同期・ロール選択画面不具合防止に完全適合！)")
        print("=" * 60)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (PWA TouchSyncまたはロール選択画面に違反があります)")
        print("=" * 60)
        print("\n🚨 テスト実行エラー:")
        try:
            from test_failure_formatter import parse_and_format_failures
            print(parse_and_format_failures(result.stdout + result.stderr))
        except Exception:
            print(result.stdout + result.stderr)
        sys.exit(1)

if __name__ == "__main__":
    run_ios_pwa_touch_sync_governance()
