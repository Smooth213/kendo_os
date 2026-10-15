#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 【第202条 ガバナンス監査】🔐 ディープリンク・未認証URLルーティング完全性規約
================================================================================
① 静的整合性規約: ルーティング防壁ファイル群の完全配備
② 未認証・一般観客防御規約: RouteGuard による特権URL直打ち遮断
③ ゼロトラスト・内部遮断規約: InternalRouteGuard による内部監査・管理画面の強制遮断
④ 公開ビュアー安全注入規約: RoleInjector による権限偽装防止＆安全フォールバック
⑤ 404/未知ルートフォールバック規約: 不明なURLアクセス時のScaffold安全描画＆赤画面根絶
"""

import os
import sys

script_dir = os.path.dirname(os.path.abspath(__file__))
if script_dir not in sys.path:
    sys.path.insert(0, script_dir)

from gov_static_scanner import get_file_content

def main():
    print("=" * 68)
    print(" 📊 【第202条 ガバナンス監査】🔐 ディープリンク・未認証URLルーティング完全性規約")
    print("=" * 68)

    c_router = get_file_content("lib/shared/routing/app_router.dart") or ""
    c_guards = get_file_content("lib/shared/routing/route_guards.dart") or ""
    c_guard = get_file_content("lib/security/route_guard.dart") or ""
    c_internal = get_file_content("lib/security/internal_route_guard.dart") or ""

    # ① 静的整合性
    ok1 = (
        "errorBuilder:" in c_router
        and "initialLocation:" in c_router
        and len(c_guards) > 0
        and len(c_guard) > 0
        and len(c_internal) > 0
    )

    # ② 未認証・一般観客防御
    ok2 = "return '/role-select'" in c_guard or "role-select" in c_guards

    # ③ ゼロトラスト・内部遮断
    ok3 = "InternalRouteGuard" in c_internal or "internal" in c_guards.lower()

    # ④ 公開ビュアー安全注入
    ok4 = "RoleInjector" in c_router or "viewer" in c_guard

    # ⑤ 404/未知ルートフォールバック
    ok5 = "errorBuilder:" in c_router

    # ⑥ 未定義ルート Access Denied
    ok6 = "AccessDenied" in c_router or "errorBuilder" in c_router

    rules = [
        ("① 静的整合性規約 (ルーティング防壁ファイル群完全配備)", ok1),
        ("② 未認証・一般観客防御規約 (特権URL直打ち遮断)", ok2),
        ("③ ゼロトラスト・内部遮断規約 (内部管理・監査画面アクセス強制遮断)", ok3),
        ("④ 公開ビュアー安全注入規約 (RoleInjector 権限偽装防止)", ok4),
        ("⑤ 404/未知ルートフォールバック規約 (赤画面根絶・安全Scaffold描画)", ok5),
        ("⑥ 未定義ルート Access Denied 安全フォールバック保証規約", ok6),
    ]

    is_ok = all(ok for _, ok in rules)

    for label, ok in rules:
        status = "🟢 適合 (Passed)" if ok else "🔴 違反 (Failed)"
        print(f" {label}: {status}")

    print("-" * 68)
    if is_ok:
        print(" 🟢 監査結果: 合格 (ディープリンク・未認証URLルーティング完全性規約に完全適合！)")
        print("=" * 68)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (第202条 ディープリンク・未認証URLルーティング完全性規約に違反があります)")
        print("=" * 68)
        sys.exit(1)

if __name__ == "__main__":
    main()
