#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 全18大ガバナンス監査 統合ランナー (Unified Governance Runner)
========================================================================
kendo OS の全18大ガバナンス監査を一括実行し、品質・アーキテクチャ・堅牢性を完全検証します。
"""

import argparse
import os
import subprocess
import sys
import time

AUDIT_DEFINITIONS = [
    {
        "id": 1,
        "name": "📏 コード行数・アーキテクチャ (Max 500 lines)",
        "cmd": ["python3", "scripts/check_file_lines.py"],
    },
    {
        "id": 2,
        "name": "🎨 デザインシステム トークン規約",
        "cmd": ["python3", "scripts/check_design_tokens.py", "--strict"],
    },
    {
        "id": 3,
        "name": "🥋 剣道公式スコア表示＆PDF描画規約",
        "cmd": ["python3", "scripts/check_kendo_score_governance.py"],
    },
    {
        "id": 4,
        "name": "📛 剣道メタデータ（シーン・選手名・結果タグ）規約",
        "cmd": ["python3", "scripts/check_kendo_metadata_governance.py"],
    },
    {
        "id": 5,
        "name": "⚔️ 試合シーン（本戦・錬成・申合せ）表記＆配色規約",
        "cmd": ["python3", "scripts/check_kendo_scene_governance.py"],
    },
    {
        "id": 6,
        "name": "🔒 セキュリティ＆ロール露出規制規約",
        "cmd": ["python3", "scripts/check_security_governance.py"],
    },
    {
        "id": 7,
        "name": "🏰 UIレイアウト 5段構造永続保持規約",
        "cmd": ["python3", "scripts/check_layout_5tier_governance.py"],
    },
    {
        "id": 8,
        "name": "🌓 テーマ視認性・白飛び黒潰れゼロ規約",
        "cmd": ["python3", "scripts/check_theme_contrast_governance.py"],
    },
    {
        "id": 9,
        "name": "🏗️ アーキテクチャ境界＆疎結合規約",
        "cmd": ["python3", "scripts/check_architecture_boundary_governance.py"],
    },
    {
        "id": 10,
        "name": "🌪️ 現場障害耐性・オフライン・耐久規約",
        "cmd": ["python3", "scripts/check_offline_resilience_governance.py"],
    },
    {
        "id": 11,
        "name": "🧪 新設ファイル・テストペア対生成規約",
        "cmd": ["python3", "scripts/check_test_pair_governance.py"],
    },
    {
        "id": 12,
        "name": "📄 PDF組版・長文字列あふれ・改ページ安全規約",
        "cmd": ["python3", "scripts/check_pdf_layout_safety_governance.py"],
    },
    {
        "id": 13,
        "name": "🌐 Web/PWA プラットフォーム境界＆安全規約",
        "cmd": ["python3", "scripts/check_web_platform_safety.py"],
    },
    {
        "id": 14,
        "name": "🏢 マルチテナント道場・大会空間 隔離規約",
        "cmd": ["python3", "scripts/check_tenant_isolation_governance.py"],
    },
    {
        "id": 15,
        "name": "🛡️ 全ページ UIゼロレンダリングエラー保証規約",
        "cmd": ["python3", "scripts/check_rendering_safety_governance.py"],
    },
    {
        "id": 16,
        "name": "📚 アプリ内マニュアル＆取説整合性規約",
        "cmd": ["python3", "scripts/check_manual_governance.py"],
    },
    {
        "id": 17,
        "name": "🗂️ 独立カテゴリ・ルール設定フォールバック安全規約",
        "cmd": ["python3", "scripts/check_category_rules_governance.py"],
    },
    {
        "id": 18,
        "name": "📌 ドック常設ミニパネル・オーバーレイ解放規約",
        "cmd": ["python3", "scripts/check_dock_lifecycle_governance.py"],
    },
]

def main():
    parser = argparse.ArgumentParser(description="Kendo OS 全18大ガバナンス監査 統合ランナー")
    parser.add_argument("--only", type=int, help="指定した監査番号（1〜18）のみを実行")
    parser.add_argument("--verbose", action="store_true", help="各監査の詳細ログを逐次出力")
    args = parser.parse_args()

    target_audits = AUDIT_DEFINITIONS
    if args.only:
        target_audits = [a for a in AUDIT_DEFINITIONS if a["id"] == args.only]
        if not target_audits:
            print(f"❌ 監査番号 {args.only} は存在しません。(1〜{len(AUDIT_DEFINITIONS)})")
            sys.exit(1)

    print("=" * 72)
    print(" 🥋 Kendo OS - 全18大ガバナンス監査 統合ランナー (Unified Governance Runner)")
    print("=" * 72)
    print(f" 実行対象: {len(target_audits)} 項目")
    print("-" * 72)

    results = []
    total_start = time.time()

    for audit in target_audits:
        audit_id = audit["id"]
        audit_name = audit["name"]
        cmd = audit["cmd"]

        print(f" [{audit_id:2d}/18] {audit_name} ... ", end="", flush=True)
        t_start = time.time()

        proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        duration = time.time() - t_start
        passed = (proc.returncode == 0)

        status_str = "🟢 PASS" if passed else "🔴 FAIL"
        print(f"{status_str} ({duration:.1f}s)")

        if args.verbose or not passed:
            output = (proc.stdout + proc.stderr).strip()
            if output:
                for line in output.splitlines():
                    print(f"      {line}")

        results.append({
            "id": audit_id,
            "name": audit_name,
            "passed": passed,
            "duration": duration,
            "output": proc.stdout + proc.stderr,
        })

    total_duration = time.time() - total_start
    all_passed = all(r["passed"] for r in results)

    print("-" * 72)
    print(" 📊 【全18大ガバナンス監査 総合サマリーレポート】")
    print("-" * 72)
    for r in results:
        badge = "🟢 PASS" if r["passed"] else "🔴 FAIL"
        print(f"  {badge} | 第{r['id']:2d}条 | {r['duration']:4.1f}s | {r['name']}")

    print("=" * 72)
    if all_passed:
        print(f" 🎉 祝！全{len(results)}項目 ガバナンス監査 100% 完全合格！ (総所要時間: {total_duration:.1f}s)")
        print("=" * 72)
        sys.exit(0)
    else:
        failed_count = sum(1 for r in results if not r["passed"])
        print(f" 🚨 警告: {failed_count} 件のガバナンス違反が検出されました。 (総所要時間: {total_duration:.1f}s)")
        print("=" * 72)
        sys.exit(1)

if __name__ == "__main__":
    main()
