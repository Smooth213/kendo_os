#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 【第5条 ガバナンス監査】🌐 Web/PWA・クロスプラットフォーム同一動作 ＆ 入力同期規約
================================================================================
① Web/Native クロスプラットフォーム完全同一動作保証
② Web/PWA プラットフォーム境界＆安全（Web固有API隔離）
③ iOS PWA タッチ座標同期＆ロール選択画面規約
"""

import subprocess
import sys

SUB_AUDITS = [
    ("① Web/Native クロスプラットフォーム完全同一動作保証規約", ["python3", "scripts/check_cross_platform_parity_governance.py"]),
    ("② Web/PWA プラットフォーム境界＆安全規約", ["python3", "scripts/check_web_platform_safety.py"]),
    ("③ iOS PWA タッチ座標同期＆ロール選択画面規約", ["python3", "scripts/check_ios_pwa_touch_sync_governance.py"]),
    ("④ 入力フォーカス時ビューポート安定性・跳ね上がり防止保証規約", ["python3", "scripts/check_input_viewport_stability_governance.py"]),
    ("⑤ Web境界・ネイティブ直接import遮断規約", ["python3", "scripts/check_web_native_import_isolation_governance.py"]),
]

def main():
    print("=" * 68)
    print(" 📊 【第5条 ガバナンス監査】🌐 Web/PWA・クロスプラットフォーム同一動作 ＆ 入力同期規約")
    print("=" * 68)

    all_passed = True
    for label, cmd in SUB_AUDITS:
        res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        is_ok = (res.returncode == 0)
        status = "🟢 適合 (Passed)" if is_ok else "🔴 違反 (Failed)"
        print(f" {label}: {status}")
        if not is_ok:
            all_passed = False
            print(f"\n--- [詳細エラー: {label}] ---")
            print(res.stdout + res.stderr)
            print("-" * 40)

    print("-" * 68)
    if all_passed:
        print(" 🟢 監査結果: 合格 (Web/PWA・クロスプラットフォーム同一動作 ＆ 入力同期規約に完全適合！)")
        print("=" * 68)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (第5条 Web/PWA・クロスプラットフォーム同一動作 ＆ 入力同期規約に違反があります)")
        print("=" * 68)
        sys.exit(1)

if __name__ == "__main__":
    main()
