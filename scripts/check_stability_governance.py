#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ==============================================================================
# 🥋 Kendo OS - 【ガバナンス監査 29/29】🛡️ 絶対的安定性・同期無限ループ根絶＆データ消失ゼロ 永続保証規約 監査スクリプト
# ==============================================================================
import subprocess
import sys

def run_stability_governance():
    test_files = [
        "test/governance/plan3_extreme_stability_governance_test.dart",
    ]

    cmd = ["flutter", "test"] + test_files + ["--reporter=expanded"]
    result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    passed_all = (result.returncode == 0)

    rules = [
        ("1. [同期ビジー再帰ループ根絶] 指数バックオフ＆サーキットブレーカーによるCPU暴走・フリーズ防止規約", passed_all),
        ("2. [CRDTステータス不可逆ガード] resolveMonotonicStatus による確定終了ステータス(finished/approved)巻き戻り防止規約", passed_all),
        ("3. [ネイティブ電波検知修復] 999日擬似遅延撤廃 ＆ Connectivityリアルタイム購読規約", passed_all),
        ("4. [コネクティビティ判定統一] isOnlineStreamProvider / isOfflineStreamProvider 判定意味論統一規約", passed_all),
        ("5. [データ消失ゼロ暗号フォールバック] saveMatchSafeMode による不正署名データ隔離退避・データ保護規約", passed_all),
        ("6. [ツイン・エンジン永続化＆自己修復] Isar破損・レコード消失時のスナップショット自己修復規約", passed_all),
        ("7. [Fatal Crash Trap] 未捕捉例外発生時の直前状態緊急退避＆セーフティネット規約", passed_all),
        ("8. [物理的誤操作ガード] PopScope による試合操作中エッジスワイプ・誤爆離脱防止規約", passed_all),
        ("9. [完全べき等キューイング] 重複UUIDコマンドの自動排除＆適応型指数バックオフ規約", passed_all),
    ]

    print("=" * 60)
    print(" 📊 【ガバナンス監査 29/29】🛡️ 絶対的安定性・同期無限ループ根絶＆データ消失ゼロ 永続保証 監査レポート")
    print("=" * 60)

    for label, is_ok in rules:
        status = "🟢 適合 (Passed)" if is_ok else "🔴 違反 (Failed)"
        print(f" {label}: {status}")

    print("-" * 60)
    if passed_all:
        print(" 🟢 監査結果: 合格 (絶対的安定性・同期無限ループ根絶＆データ消失ゼロ規約に完全適合！)")
        print("=" * 60)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (絶対的安定性・同期無限ループ根絶・データ保護ガバナンスに規約違反があります)")
        print("=" * 60)
        print("\n🚨 テスト実行エラー:")
        try:
            from test_failure_formatter import parse_and_format_failures
            print(parse_and_format_failures(result.stdout + result.stderr))
        except Exception:
            print(result.stdout + result.stderr)
        sys.exit(1)

if __name__ == "__main__":
    run_stability_governance()
