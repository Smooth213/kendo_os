#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 新・全31大ガバナンス法典 統合ランナー (Unified Governance Runner)
========================================================================
kendo OS の全31大ガバナンス監査を「6大ドメイン・100番台法典方式」で一括実行し、
品質・アーキテクチャ・堅牢性を完全検証します。

【法典体系 (6大ドメイン)】:
- 第1章：競技ドメイン ＆ 大会運営規約（第101条〜第105条）
- 第2章：セキュリティ ＆ データ整合性規約（第201条〜第206条）
- 第3章：UI・UX ＆ レンダリング最適化規約（第301条〜第306条）
- 第4章：極限低負荷 ＆ サーマル・リソース管理規約（第401条〜第405条）
- 第5章：現場通信 ＆ 耐障害性・分散調停規約（第501条〜第504条）
- 第6章：プラットフォーム境界 ＆ コード品質規約（第601条〜第606条）
"""

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import os
import subprocess
import sys
import threading
import time

CHAPTER_NAMES = {
    1: "第1章: 競技ドメイン ＆ 大会運営規約",
    2: "第2章: セキュリティ ＆ データ整合性規約",
    3: "第3章: UI・UX ＆ レンダリング最適化規約",
    4: "第4章: 極限低負荷 ＆ サーマル・リソース管理規約",
    5: "第5章: 現場通信 ＆ 耐障害性・分散調停規約",
    6: "第6章: プラットフォーム境界 ＆ コード品質規約",
}

CATEGORY_MAP = {
    "domain": 1,
    "1": 1,
    "security": 2,
    "2": 2,
    "ui": 3,
    "3": 3,
    "perf": 4,
    "4": 4,
    "resilience": 5,
    "5": 5,
    "quality": 6,
    "6": 6,
}

# 旧番号（1〜31）から新番号（101〜605）への自動ルーティングマップ
OLD_TO_NEW_ID_MAP = {
    1: 101, 7: 102, 8: 103, 18: 104, 21: 105,
    4: 201, 20: 202, 25: 203, 26: 204, 29: 205, 15: 206,
    3: 301, 6: 302, 9: 303, 10: 304, 11: 305, 24: 306,
    12: 401, 13: 402, 27: 403, 14: 404, 31: 405,
    22: 501, 16: 502, 17: 503, 28: 504,
    2: 601, 23: 602, 5: 603, 19: 604, 30: 605,
}

AUDIT_DEFINITIONS = [
    # ==========================================================================
    # 【第1章：競技ドメイン ＆ 大会運営規約】（100番台）
    # ==========================================================================
    {
        "id": 101,
        "old_id": 1,
        "chapter_num": 1,
        "name": "🥋 剣道公式ルール・スコア・試合形式・表記・配列 永続保証規約",
        "cmd": ["python3", "scripts/check_gov_101_kendo_rules.py"],
    },
    {
        "id": 102,
        "old_id": 7,
        "chapter_num": 1,
        "name": "📚 大会運用マニュアル ＆ 独立ルール安全フォールバック規約",
        "cmd": ["python3", "scripts/check_gov_102_tournament_ops_manual.py"],
    },
    {
        "id": 103,
        "old_id": 8,
        "chapter_num": 1,
        "name": "🔗 外部連携・観客用共有URL ＆ ライブ配信直行規約",
        "cmd": ["python3", "scripts/check_gov_103_external_share_url.py"],
    },
    {
        "id": 104,
        "old_id": 18,
        "chapter_num": 1,
        "name": "🧮 試合数計算・コート配分シミュレーション ＆ 部内戦ドック品質規約",
        "cmd": ["python3", "scripts/check_gov_104_match_calc_simulation.py"],
    },
    {
        "id": 105,
        "old_id": 21,
        "chapter_num": 1,
        "name": "🔀 現場動的運用・急遽コート振替 ＆ リアルタイム進行整合性保証規約",
        "cmd": ["python3", "scripts/check_gov_105_court_transfer_integrity.py"],
    },
    {
        "id": 106,
        "old_id": None,
        "chapter_num": 1,
        "name": "🔄 全ルール設定画面間相互完全同期 ＆ 先祖返り・上書き防止規約",
        "cmd": ["python3", "scripts/check_gov_106_rule_synchronization_integrity.py"],
    },

    # ==========================================================================
    # 【第2章：セキュリティ ＆ データ整合性規約】（200番台）
    # ==========================================================================
    {
        "id": 201,
        "old_id": 4,
        "chapter_num": 2,
        "name": "🔒 セキュリティ・権限ロール ＆ マルチテナント空間隔離規約",
        "cmd": ["python3", "scripts/check_gov_201_auth_multitenant_isolation.py"],
    },
    {
        "id": 202,
        "old_id": 20,
        "chapter_num": 2,
        "name": "🔐 ディープリンク・未認証URLルーティング完全性規約",
        "cmd": ["python3", "scripts/check_gov_202_deeplink_route_integrity.py"],
    },
    {
        "id": 203,
        "old_id": 25,
        "chapter_num": 2,
        "name": "🔐 スコアイベント電子署名・改ざん隔離 ＆ ゼロトラストデータ完全性保証規約",
        "cmd": ["python3", "scripts/check_gov_203_score_event_signature_zero_trust.py"],
    },
    {
        "id": 204,
        "old_id": 26,
        "chapter_num": 2,
        "name": "🛡️ データ入力サニタイズ・CSV/JSONインジェクション防護 ＆ 制御文字排除規約",
        "cmd": ["python3", "scripts/check_gov_204_input_sanitization_injection_defense.py"],
    },
    {
        "id": 205,
        "old_id": 29,
        "chapter_num": 2,
        "name": "🗄️ データベース整合性・Firestore複合クエリ ＆ インデックス契約完全保証規約",
        "cmd": ["python3", "scripts/check_gov_205_database_integrity_firestore_contract.py"],
    },
    {
        "id": 206,
        "old_id": 15,
        "chapter_num": 2,
        "name": "💾 データI/Oバッチ集約・Isar最適化 ＆ 履歴チャンク分割規約",
        "cmd": ["python3", "scripts/check_gov_206_io_batch_chunk_optimization.py"],
    },

    # ==========================================================================
    # 【第3章：UI・UX ＆ レンダリング最適化規約】（300番台）
    # ==========================================================================
    {
        "id": 301,
        "old_id": 3,
        "chapter_num": 3,
        "name": "🎨 デザインシステム・UIレイアウト 5段構造 ＆ テーマ視認性規約",
        "cmd": ["python3", "scripts/check_gov_301_design_system_tokens.py"],
    },
    {
        "id": 302,
        "old_id": 6,
        "chapter_num": 3,
        "name": "📄 UIレンダリング安全・PDF組版 ＆ 常設ドック規約",
        "cmd": ["python3", "scripts/check_gov_302_rendering_dock_safety.py"],
    },
    {
        "id": 303,
        "old_id": 9,
        "chapter_num": 3,
        "name": "⚡ UI再描画局所化 ＆ Jank防止規約",
        "cmd": ["python3", "scripts/check_gov_303_ui_repaint_jank_prevention.py"],
    },
    {
        "id": 304,
        "old_id": 10,
        "chapter_num": 3,
        "name": "🎨 レンダリング負荷隔離 ＆ RepaintBoundary最適化規約",
        "cmd": ["python3", "scripts/check_gov_304_repaint_boundary_isolation.py"],
    },
    {
        "id": 305,
        "old_id": 11,
        "chapter_num": 3,
        "name": "📜 リスト仮想化 ＆ ビューポート描画最適化（一括生成禁止）規約",
        "cmd": ["python3", "scripts/check_gov_305_list_viewport_optimization.py"],
    },
    {
        "id": 306,
        "old_id": 24,
        "chapter_num": 3,
        "name": "🖌️ 手書きズーム・InteractiveViewerジェスチャー排他 ＆ Transform座標不変性保証規約",
        "cmd": ["python3", "scripts/check_gov_306_handwriting_zoom_exclusive_gesture.py"],
    },

    # ==========================================================================
    # 【第4章：極限低負荷 ＆ サーマル・リソース管理規約】（400番台）
    # ==========================================================================
    {
        "id": 401,
        "old_id": 12,
        "chapter_num": 4,
        "name": "🧵 Isolate完全分離・非同期バックオフ ＆ 非ブロッキング処理規約",
        "cmd": ["python3", "scripts/check_gov_401_isolate_concurrency_nonblocking.py"],
    },
    {
        "id": 402,
        "old_id": 13,
        "chapter_num": 4,
        "name": "🔋 端末低負荷・省電力・タイマー沈黙 ＆ サーマル適応制御規約",
        "cmd": ["python3", "scripts/check_gov_402_thermal_battery_adaptation.py"],
    },
    {
        "id": 403,
        "old_id": 27,
        "chapter_num": 4,
        "name": "🚨 サーマル適応警告・省電力UIトースト非ブロッキング表示 ＆ メモリリークゼロ規約",
        "cmd": ["python3", "scripts/check_gov_403_thermal_warning_nonblocking_toast.py"],
    },
    {
        "id": 404,
        "old_id": 14,
        "chapter_num": 4,
        "name": "🧹 メモリ保護・LRU上限 ＆ リソース明示解放（リーク根絶）規約",
        "cmd": ["python3", "scripts/check_gov_404_memory_leak_lru_cleanup.py"],
    },
    {
        "id": 405,
        "old_id": 31,
        "chapter_num": 4,
        "name": "🧹 ブラウザBlobリソース即時解放・メモリリークゼロ規約",
        "cmd": ["python3", "scripts/check_gov_405_blob_resource_release.py"],
    },

    # ==========================================================================
    # 【第5章：現場通信 ＆ 耐障害性・分散調停規約】（500番台）
    # ==========================================================================
    {
        "id": 501,
        "old_id": 22,
        "chapter_num": 5,
        "name": "📶 現場P2Pローカル配信 ＆ ソケットライフサイクル・Webプラットフォーム完全隔離規約",
        "cmd": ["python3", "scripts/check_gov_501_p2p_socket_web_isolation.py"],
    },
    {
        "id": 502,
        "old_id": 16,
        "chapter_num": 5,
        "name": "🌐 分散同期整合性・Clock Skew補正 ＆ CRDT調停規約",
        "cmd": ["python3", "scripts/check_gov_502_distributed_clock_skew_crdt.py"],
    },
    {
        "id": 503,
        "old_id": 17,
        "chapter_num": 5,
        "name": "🛡️ ツインエンジン自己修復・現場障害耐性 ＆ 完全耐障害性規約",
        "cmd": ["python3", "scripts/check_gov_503_twin_engine_self_healing.py"],
    },
    {
        "id": 504,
        "old_id": 28,
        "chapter_num": 5,
        "name": "🚨 障害データ隔離・フェイルセーフ二次破壊完全阻止 ＆ 生データ救済規約",
        "cmd": ["python3", "scripts/check_gov_504_corrupted_data_quarantine_raw_recovery.py"],
    },

    # ==========================================================================
    # 【第6章：プラットフォーム境界 ＆ コード品質規約】（600番台）
    # ==========================================================================
    {
        "id": 601,
        "old_id": 2,
        "chapter_num": 6,
        "name": "📏 コード品質・行数制限 (Max 500 lines) ＆ アーキテクチャ境界規約",
        "cmd": ["python3", "scripts/check_gov_601_line_count_boundary.py"],
    },
    {
        "id": 602,
        "old_id": 23,
        "chapter_num": 6,
        "name": "🧪 テスト設計・タイトル命名規約 ＆ テストスイート整合性規約",
        "cmd": ["python3", "scripts/check_gov_602_test_naming_convention.py"],
    },
    {
        "id": 603,
        "old_id": 5,
        "chapter_num": 6,
        "name": "🌐 Web/PWA・クロスプラットフォーム同一動作 ＆ 入力同期規約",
        "cmd": ["python3", "scripts/check_gov_603_web_pwa_cross_platform.py"],
    },
    {
        "id": 604,
        "old_id": 19,
        "chapter_num": 6,
        "name": "📦 重厚ライブラリ遅延読み込み（Deferred Loading）＆ 初期バンドル最小化規約",
        "cmd": ["python3", "scripts/check_gov_604_deferred_loading_bundle.py"],
    },
    {
        "id": 605,
        "old_id": 30,
        "chapter_num": 6,
        "name": "🌐 Web/ネイティブプラグイン完全隔離・バウンダリ漏洩ゼロ規約",
        "cmd": ["python3", "scripts/check_gov_605_web_native_plugin_isolation.py"],
    },
    {
        "id": 606,
        "old_id": None,
        "chapter_num": 6,
        "name": "⚡ ガバナンススクリプト静的検査専念 ＆ 二重テスト起動完全禁止規約",
        "cmd": ["python3", "scripts/check_gov_606_governance_runner_efficiency.py"],
    },
    {
        "id": 607,
        "old_id": None,
        "chapter_num": 6,
        "name": "🛡️ 非同期 BuildContext マウント安全性完全保証規約",
        "cmd": ["python3", "scripts/check_gov_607_build_context_mounted_safety.py"],
    },
    {
        "id": 608,
        "old_id": None,
        "chapter_num": 6,
        "name": "⚖️ CI環境パリティ ＆ Fast-Fail実行整合性完全保証規約",
        "cmd": ["python3", "scripts/check_gov_608_ci_parity_fast_fail.py"],
    },
]


def resolve_target_id(input_id: int) -> int:
    """旧番号（1〜31）が渡された場合は新番号（101〜605）に自動マッピング。"""
    if input_id in OLD_TO_NEW_ID_MAP:
        new_id = OLD_TO_NEW_ID_MAP[input_id]
        print(f"💡 旧番号 第{input_id}条 を検知しました -> 新体系 第{new_id}条 へルーティングします。")
        return new_id
    return input_id


def main():
    parser = argparse.ArgumentParser(
        description="Kendo OS 新・全31大ガバナンス法典 統合ランナー (100番台法典方式)"
    )
    parser.add_argument(
        "--only",
        type=int,
        help="指定した監査条番号（新番号: 101〜605、旧番号: 1〜31）のみを実行",
    )
    parser.add_argument(
        "--category",
        "-c",
        type=str,
        help="指定した章（1〜6 または domain, security, ui, perf, resilience, quality）のみを実行",
    )
    parser.add_argument(
        "--jobs",
        "-j",
        type=int,
        default=4,
        help="並列実行ワーカー数 (デフォルト: 4)",
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="各監査の詳細ログを逐次出力",
    )
    args = parser.parse_args()

    target_audits = AUDIT_DEFINITIONS

    # カテゴリ指定フィルタ
    if args.category:
        cat_key = args.category.lower()
        if cat_key not in CATEGORY_MAP:
            print(f"❌ 不正なカテゴリ指定です: '{args.category}'")
            print("   利用可能: domain(1), security(2), ui(3), perf(4), resilience(5), quality(6)")
            sys.exit(1)
        target_chap = CATEGORY_MAP[cat_key]
        target_audits = [a for a in target_audits if a["chapter_num"] == target_chap]

    # 単一実行フィルタ（新番号・旧番号両対応）
    if args.only:
        resolved_id = resolve_target_id(args.only)
        target_audits = [a for a in target_audits if a["id"] == resolved_id]
        if not target_audits:
            print(f"❌ 監査条番号 第{args.only}条 は存在しません。")
            sys.exit(1)

    workers = 1 if args.only else max(1, args.jobs)

    print("=" * 80)
    print(f" 🥋 Kendo OS - 全{len(AUDIT_DEFINITIONS)}大ガバナンス法典 統合ランナー (100番台体系)")
    print("=" * 80)
    print(f" 実行対象: {len(target_audits)} 条項 | 並列実行: {workers} ワーカー")
    print("-" * 80)

    completed_count = 0
    print_lock = threading.Lock()

    def run_worker(audit_item):
        nonlocal completed_count
        audit_id = audit_item["id"]
        audit_name = audit_item["name"]
        chap_num = audit_item["chapter_num"]
        cmd = audit_item["cmd"]

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
            record = {
                "id": audit_id,
                "chapter_num": chap_num,
                "name": audit_name,
                "passed": passed,
                "duration": duration,
                "stdout": res.stdout,
                "stderr": res.stderr,
            }
        except Exception as e:
            duration = time.time() - start_time
            record = {
                "id": audit_id,
                "chapter_num": chap_num,
                "name": audit_name,
                "passed": False,
                "duration": duration,
                "stdout": "",
                "stderr": str(e),
            }

        with print_lock:
            completed_count += 1
            badge = "🟢 PASS" if record["passed"] else "🔴 FAIL"
            print(f" [{completed_count:2d}/{len(target_audits)}] 第{audit_id:3d}条 {audit_name} ... {badge} ({duration:.1f}s)")
            if not record["passed"] and not args.verbose:
                print(f"\n--- [詳細ログ: 第{audit_id}条 {audit_name}] ---")
                print(record["stdout"])
                print(record["stderr"])
                print("-" * 40)

        return record

    total_start = time.time()
    results = []

    if workers == 1:
        for audit in target_audits:
            results.append(run_worker(audit))
    else:
        with ThreadPoolExecutor(max_workers=workers) as executor:
            futures = [executor.submit(run_worker, audit) for audit in target_audits]
            for future in as_completed(futures):
                results.append(future.result())

    # 元の定義順（ID昇順）に並べ替え
    results.sort(key=lambda r: r["id"])

    chapter_results = {i: [] for i in range(1, 7)}
    for r in results:
        chapter_results[r["chapter_num"]].append(r)

    total_duration = time.time() - total_start
    all_passed = all(r["passed"] for r in results)

    # ==========================================================================
    # 総合サマリーレポート（条別 ＆ 章別集計）
    # ==========================================================================
    print("\n" + "=" * 80)
    print(f" 📊 【Kendo OS ガバナンス法典 総合監査レポート】")
    print("=" * 80)

    for r in results:
        badge = "🟢 PASS" if r["passed"] else "🔴 FAIL"
        print(f"  {badge} | 第{r['id']:3d}条 | {r['duration']:4.1f}s | {r['name']}")

    print("-" * 80)
    print(" 📑 【章別サマリー (Chapter Overview)】")
    passed_chapters_count = 0
    total_evaluated_chapters = 0

    for chap_num in range(1, 7):
        records = chapter_results[chap_num]
        if not records:
            continue
        total_evaluated_chapters += 1
        chap_passed = all(r["passed"] for r in records)
        chap_duration = sum(r["duration"] for r in records)
        badge = "🟢 PASS" if chap_passed else "🔴 FAIL"
        if chap_passed:
            passed_chapters_count += 1
        print(
            f"  {badge} | {CHAPTER_NAMES[chap_num]} "
            f"({len(records)}/{len(records)} 条項適合, {chap_duration:.1f}s)"
        )

    print("=" * 80)
    if all_passed:
        print(
            f" 🎉 祝！全{len(results)}条項 完全適合！ "
            f"({passed_chapters_count}/{total_evaluated_chapters} Chapters PASSED, "
            f"総所要時間: {total_duration:.1f}s)"
        )
        print("=" * 80)
        sys.exit(0)
    else:
        failed_count = sum(1 for r in results if not r["passed"])
        print(
            f" 🚨 警告: {failed_count} 件のガバナンス違反が検出されました。 "
            f"(総所要時間: {total_duration:.1f}s)"
        )
        print("=" * 80)
        sys.exit(1)


if __name__ == "__main__":
    main()
