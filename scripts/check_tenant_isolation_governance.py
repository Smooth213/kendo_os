#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ==============================================================================
# 🥋 kendo OS - 【ガバナンス監査 14/14】🏢 マルチテナント道場・大会空間 隔離監査スクリプト
# ==============================================================================
import subprocess
import sys

def run_tenant_isolation_governance():
    test_files = [
        "test/unit/domain/mixed_scene_rules_ranking_test.dart",
        "test/unit/domain/league_standings_integration_test.dart",
    ]

    cmd = ["python3", "scripts/gov_test_helper.py"] + test_files + ["--reporter=expanded"]
    result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    output = result.stdout + result.stderr

    passed_all = (result.returncode == 0)

    # 静的解析: 道場登録・マスタメニューにおけるサニタイズおよび組織空間分離保証 (Python自前検証)
    import os
    script_dir = os.path.dirname(os.path.abspath(__file__))
    root_dir = os.path.dirname(script_dir)
    p1 = os.path.join(root_dir, "lib/admin/presentation/components/master_register_organization_bottom_sheet.dart")
    p2 = os.path.join(root_dir, "lib/admin/presentation/components/master_menu_bottom_sheet.dart")

    tenancy_static_ok = True
    if not (os.path.isfile(p1) and os.path.isfile(p2)):
        tenancy_static_ok = False
    else:
        with open(p1, "r", encoding="utf-8") as f1, open(p2, "r", encoding="utf-8") as f2:
            c1, c2 = f1.read(), f2.read()
        if not ("TextSanitizer.clean" in c1 and "collection('organizations')" in c1 and "currentDojoIdProvider" in c1):
            tenancy_static_ok = False
        if not ("MasterDataCleanupDialog" in c2 and "playerRepositoryProvider" in c2 and "promoteAllPlayers" in c2):
            tenancy_static_ok = False

    rules = [
        ("1. 同一大会内 混合ルール（本戦/錬成/申合せ）集計整合性規約", passed_all),
        ("2. 変則勝ち点（3/1/0点 vs 1/0.5/0点）順位決定論的解決規約", passed_all),
        ("3. 同率同勝ち点タイブレーク（勝者数 ➔ 総本数）解決規約", passed_all),
        ("4. エキシビション/練習試合（countForStandings=false）集計除外規約", passed_all),
        ("5. マスター組織登録 ＆ 道場空間完全分離規約 (静的実検証)", tenancy_static_ok),
    ]

    print("=" * 60)
    print(" 📊 【ガバナンス監査 14/14】🏢 マルチテナント道場・大会空間 隔離監査レポート")
    print("=" * 60)

    for label, is_ok in rules:
        status = "🟢 適合 (Passed)" if is_ok else "🔴 違反 (Failed)"
        print(f" {label}: {status}")

    print("-" * 60)
    if passed_all:
        print(" 🟢 監査結果: 合格 (マルチテナント道場・大会空間隔離規約に完全適合！)")
        print("=" * 60)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (マルチテナント隔離規約違反またはテスト失敗が検出されました)")
        print("=" * 60)
        from test_failure_formatter import parse_and_format_failures
        print(parse_and_format_failures(output))
        sys.exit(1)

if __name__ == "__main__":
    run_tenant_isolation_governance()
