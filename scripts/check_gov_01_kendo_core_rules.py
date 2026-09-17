#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 【第1条 ガバナンス監査】🥋 剣道公式ルール・スコア・表記・配列 永続保証規約
================================================================================
① 公式スコア表示＆PDF描画（Table斜め・先取丸・勝者丸・Inline・Scoreboard）
② 剣道メタデータ（シーン・選手名・結果タグ）
③ 試合シーン（本戦・錬成・申合せ）表記＆配色
④ 団体戦スコア順序（先鋒〜大将・代表戦）剣道標準配列
"""

import subprocess
import sys

SUB_AUDITS = [
    ("① 剣道公式スコア表示＆PDF描画規約", ["python3", "scripts/check_kendo_score_governance.py"]),
    ("② 剣道メタデータ（シーン・選手名・結果タグ）規約", ["python3", "scripts/check_kendo_metadata_governance.py"]),
    ("③ 試合シーン（本戦・錬成・申合せ）表記＆配色規約", ["python3", "scripts/check_kendo_scene_governance.py"]),
    ("④ 団体戦スコア順序（先鋒〜大将・代表戦）剣道標準配列規約", ["python3", "scripts/check_team_match_order_governance.py"]),
]

def main():
    print("=" * 68)
    print(" 📊 【第1条 ガバナンス監査】🥋 剣道公式ルール・スコア・表記・配列 永続保証規約")
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
        print(" 🟢 監査結果: 合格 (剣道公式ルール・スコア・表記・配列 永続保証規約に完全適合！)")
        print("=" * 68)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (第1条 剣道公式ルール・スコア・表記・配列規約に違反があります)")
        print("=" * 68)
        sys.exit(1)

if __name__ == "__main__":
    main()
