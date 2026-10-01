#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 【第20条 ガバナンス監査】🔐 ディープリンク・未認証URLルーティング完全性規約
================================================================================
① 静的整合性規約: ルーティング防壁ファイル群の完全配備
② 未認証・一般観客防御規約: RouteGuard による特権URL直打ち遮断
③ ゼロトラスト・内部遮断規約: InternalRouteGuard による内部監査・管理画面の強制遮断
④ 公開ビュアー安全注入規約: RoleInjector による権限偽装防止＆安全フォールバック
⑤ 404/未知ルートフォールバック規約: 不明なURLアクセス時のScaffold安全描画＆赤画面根絶
"""

import subprocess
import sys

def main():
    print("=" * 68)
    print(" 📊 【第20条 ガバナンス監査】🔐 ディープリンク・未認証URLルーティング完全性規約")
    print("=" * 68)

    cmd1 = [
        "flutter",
        "test",
        "test/governance/route_guard_integrity_governance_test.dart",
        "--reporter=expanded",
    ]
    cmd2 = [
        "flutter",
        "test",
        "test/governance/router_fallback_access_denied_governance_test.dart",
        "--reporter=expanded",
    ]
    res1 = subprocess.run(cmd1, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    res2 = subprocess.run(cmd2, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    is_ok = (res1.returncode == 0) and (res2.returncode == 0)

    rules = [
        ("① 静的整合性規約 (ルーティング防壁ファイル群完全配備)", res1.returncode == 0),
        ("② 未認証・一般観客防御規約 (特権URL直打ち遮断)", res1.returncode == 0),
        ("③ ゼロトラスト・内部遮断規約 (内部管理・監査画面アクセス強制遮断)", res1.returncode == 0),
        ("④ 公開ビュアー安全注入規約 (RoleInjector 権限偽装防止)", res1.returncode == 0),
        ("⑤ 404/未知ルートフォールバック規約 (赤画面根絶・安全Scaffold描画)", res1.returncode == 0),
        ("⑥ 未定義ルート Access Denied 安全フォールバック保証規約", res2.returncode == 0),
    ]

    for label, ok in rules:
        status = "🟢 適合 (Passed)" if ok else "🔴 違反 (Failed)"
        print(f" {label}: {status}")

    print("-" * 68)
    if is_ok:
        print(" 🟢 監査結果: 合格 (ディープリンク・未認証URLルーティング完全性規約に完全適合！)")
        print("=" * 68)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (第20条 ディープリンク・未認証URLルーティング完全性規約に違反があります)")
        print("=" * 68)
        print(res1.stdout + res1.stderr + res2.stdout + res2.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
