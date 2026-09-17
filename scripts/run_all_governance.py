#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 全18大ガバナンス監査 統合ランナー (Unified Governance Runner)
========================================================================
kendo OS の全18大ガバナンス監査を一括実行し、品質・アーキテクチャ・堅牢性を完全検証します。
- 第1部：ドメイン・プロダクト品質規約（第1条〜第8条）
- 第2部：極限最適化・低負荷・絶対安定性規約（第9条〜第17条）
- 第3部：大会運営支援・シミュレーション規約（第18条）
"""

import argparse
import os
import subprocess
import sys
import time

AUDIT_DEFINITIONS = [
    # ==========================================================================
    # 【第1部：ドメイン・プロダクト品質規約】（第1条〜第8条）
    # ==========================================================================
    {
        "id": 1,
        "part": "第1部: ドメイン・プロダクト品質",
        "name": "🥋 剣道公式ルール・スコア・表記・配列 永続保証規約",
        "cmd": ["python3", "scripts/check_gov_01_kendo_core_rules.py"],
    },
    {
        "id": 2,
        "part": "第1部: ドメイン・プロダクト品質",
        "name": "📏 コード品質・行数制限 (Max 500 lines) ＆ アーキテクチャ境界規約",
        "cmd": ["python3", "scripts/check_gov_02_code_quality_and_architecture.py"],
    },
    {
        "id": 3,
        "part": "第1部: ドメイン・プロダクト品質",
        "name": "🎨 デザインシステム・UIレイアウト 5段構造 ＆ テーマ視認性規約",
        "cmd": ["python3", "scripts/check_gov_03_design_and_layout.py"],
    },
    {
        "id": 4,
        "part": "第1部: ドメイン・プロダクト品質",
        "name": "🔒 セキュリティ・権限ロール ＆ マルチテナント空間隔離規約",
        "cmd": ["python3", "scripts/check_gov_04_security_and_tenancy.py"],
    },
    {
        "id": 5,
        "part": "第1部: ドメイン・プロダクト品質",
        "name": "🌐 Web/PWA・クロスプラットフォーム同一動作 ＆ 入力同期規約",
        "cmd": ["python3", "scripts/check_gov_05_web_cross_platform.py"],
    },
    {
        "id": 6,
        "part": "第1部: ドメイン・プロダクト品質",
        "name": "📄 UIレンダリング安全・PDF組版 ＆ 常設ドック規約",
        "cmd": ["python3", "scripts/check_gov_06_rendering_and_pdf.py"],
    },
    {
        "id": 7,
        "part": "第1部: ドメイン・プロダクト品質",
        "name": "📚 大会運用マニュアル ＆ 独立ルール安全フォールバック規約",
        "cmd": ["python3", "scripts/check_gov_07_manual_and_rules.py"],
    },
    {
        "id": 8,
        "part": "第1部: ドメイン・プロダクト品質",
        "name": "🔗 外部連携・観客用共有URL ＆ ライブ配信直行規約",
        "cmd": ["python3", "scripts/check_gov_08_external_share_and_stream.py"],
    },
    # ==========================================================================
    # 【第2部：極限最適化・低負荷・絶対安定性規約】（第9条〜第17条）
    # ==========================================================================
    {
        "id": 9,
        "part": "第2部: 極限最適化・低負荷・絶対安定性",
        "name": "⚡ UI再描画局所化 ＆ Jank防止規約",
        "cmd": ["python3", "scripts/check_gov_09_ui_rebuild.py"],
    },
    {
        "id": 10,
        "part": "第2部: 極限最適化・低負荷・絶対安定性",
        "name": "🎨 レンダリング負荷隔離 ＆ RepaintBoundary最適化規約",
        "cmd": ["python3", "scripts/check_gov_10_rendering_boundary.py"],
    },
    {
        "id": 11,
        "part": "第2部: 極限最適化・低負荷・絶対安定性",
        "name": "📜 リスト仮想化 ＆ ビューポート描画最適化（一括生成禁止）規約",
        "cmd": ["python3", "scripts/check_gov_11_list_virtualization.py"],
    },
    {
        "id": 12,
        "part": "第2部: 極限最適化・低負荷・絶対安定性",
        "name": "🧵 Isolate完全分離・非同期バックオフ ＆ 非ブロッキング処理規約",
        "cmd": ["python3", "scripts/check_gov_12_isolate_and_concurrency.py"],
    },
    {
        "id": 13,
        "part": "第2部: 極限最適化・低負荷・絶対安定性",
        "name": "🔋 端末低負荷・省電力・タイマー沈黙 ＆ サーマル適応制御規約",
        "cmd": ["python3", "scripts/check_gov_13_low_load_and_timer.py"],
    },
    {
        "id": 14,
        "part": "第2部: 極限最適化・低負荷・絶対安定性",
        "name": "🧹 メモリ保護・LRU上限 ＆ リソース明示解放（リーク根絶）規約",
        "cmd": ["python3", "scripts/check_gov_14_memory_and_lifecycle.py"],
    },
    {
        "id": 15,
        "part": "第2部: 極限最適化・低負荷・絶対安定性",
        "name": "💾 データI/Oバッチ集約・Isar最適化 ＆ 履歴チャンク分割規約",
        "cmd": ["python3", "scripts/check_gov_15_io_batch_and_history.py"],
    },
    {
        "id": 16,
        "part": "第2部: 極限最適化・低負荷・絶対安定性",
        "name": "🌐 分散同期整合性・Clock Skew補正 ＆ CRDT調停規約",
        "cmd": ["python3", "scripts/check_gov_16_sync_and_crdt.py"],
    },
    {
        "id": 17,
        "part": "第2部: 極限最適化・低負荷・絶対安定性",
        "name": "🛡️ ツインエンジン自己修復・現場障害耐性 ＆ 完全耐障害性規約",
        "cmd": ["python3", "scripts/check_gov_17_resilience_and_twin.py"],
    },
    # ==========================================================================
    # 【第3部：大会運営支援・シミュレーション規約】（第18条）
    # ==========================================================================
    {
        "id": 18,
        "part": "第3部: 大会運営支援・シミュレーション",
        "name": "🧮 試合数計算・コート配分シミュレーション ＆ 部内戦ドック品質規約",
        "cmd": ["python3", "scripts/check_gov_18_match_calculator.py"],
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

    print("=" * 76)
    print(f" 🥋 Kendo OS - 全{len(AUDIT_DEFINITIONS)}大ガバナンス監査 統合ランナー (Unified Governance Runner)")
    print("=" * 76)
    print(f" 実行対象: {len(target_audits)} 項目")
    print("-" * 76)

    results = []
    total_start = time.time()
    current_part = None

    for audit in target_audits:
        audit_id = audit["id"]
        audit_name = audit["name"]
        audit_part = audit["part"]
        cmd = audit["cmd"]

        if audit_part != current_part and not args.only:
            current_part = audit_part
            print(f"\n【{current_part}】")

        total_count = len(AUDIT_DEFINITIONS)
        if args.verbose:
            print(f"▶ 実行中 [{audit_id:2d}/{total_count}] {audit_name} ...")
        else:
            print(f" [{audit_id:2d}/{total_count}] {audit_name} ... ", end="", flush=True)

        start_time = time.time()
        try:
            res = subprocess.run(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
            )
            duration = time.time() - start_time
            passed = (res.returncode == 0)

            if passed:
                print(f"🟢 PASS ({duration:.1f}s)")
            else:
                print(f"🔴 FAIL ({duration:.1f}s)")
                if not args.verbose:
                    print(f"\n--- [詳細ログ: {audit_name}] ---")
                    print(res.stdout)
                    print(res.stderr)
                    print("-" * 40)

            results.append({
                "id": audit_id,
                "name": audit_name,
                "passed": passed,
                "duration": duration,
                "stdout": res.stdout,
                "stderr": res.stderr,
            })
        except Exception as e:
            duration = time.time() - start_time
            print(f"💥 ERROR ({duration:.1f}s) -> {e}")
            results.append({
                "id": audit_id,
                "name": audit_name,
                "passed": False,
                "duration": duration,
                "stdout": "",
                "stderr": str(e),
            })

    total_duration = time.time() - total_start
    all_passed = all(r["passed"] for r in results)

    print("\n" + "=" * 76)
    print(f" 📊 【全{len(results)}大ガバナンス監査 総合サマリーレポート】")
    print("=" * 76)

    for r in results:
        badge = "🟢 PASS" if r["passed"] else "🔴 FAIL"
        print(f"  {badge} | 第{r['id']:2d}条 | {r['duration']:4.1f}s | {r['name']}")

    print("=" * 76)
    if all_passed:
        print(f" 🎉 祝！全{len(results)}項目 ガバナンス監査 100% 完全合格！ (総所要時間: {total_duration:.1f}s)")
        print("=" * 76)
        sys.exit(0)
    else:
        failed_count = sum(1 for r in results if not r["passed"])
        print(f" 🚨 警告: {failed_count} 件のガバナンス違反が検出されました。 (総所要時間: {total_duration:.1f}s)")
        print("=" * 76)
        sys.exit(1)

if __name__ == "__main__":
    main()
