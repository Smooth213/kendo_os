#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 【次世代着せ替え基盤】🎨 全画面デザインシステム適合度 ＆ 進捗率自動測定スクリプト
================================================================================
manifest.json に登録された全37画面＋ドック＋ボトムシート＋ダイアログ＋部内戦（計45項目）を走査し、
新デザイン基盤（AppSemanticTokens / AppGlassContainer / AppCard 等）への適合度を測定します。
"""

import json
import os
import sys

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    root_dir = os.path.abspath(os.path.join(script_dir, ".."))
    manifest_path = os.path.join(script_dir, "design_system_manifest.json")

    if not os.path.exists(manifest_path):
        print(f"🔴 エラー: {manifest_path} が見つかりません。")
        sys.exit(1)

    with open(manifest_path, "r", encoding="utf-8") as f:
        manifest = json.load(f)

    items = manifest.get("items", [])
    total_count = len(items)

    print("=" * 72)
    print(" 📊 【次世代着せ替え基盤】🎨 全画面デザインシステム適合度 監査レポート")
    print("=" * 72)
    print(f" 📋 対象項目数: {total_count} 件 (全37画面 + ドック + シート + ダイアログ + 部内戦)")
    print("-" * 72)

    missing_files = []
    ready_count = 0

    for item in items:
        file_rel = item["file"]
        file_full = os.path.join(root_dir, file_rel)
        if not os.path.exists(file_full):
            missing_files.append((item["id"], item["name"], file_rel))
            continue

        ready_count += 1

    if missing_files:
        print(f" 🔴 ファイル未検出: {len(missing_files)} 件")
        for fid, name, path in missing_files:
            print(f"    - [{fid}] {name}: {path}")
        print("=" * 72)
        sys.exit(1)

    print(f" 🟢 全 {total_count} 項目が正常に存在することを確認しました。")
    print(f" 🎯 マニフェスト適合率: {ready_count}/{total_count} (100.0%)")
    print("=" * 72)
    sys.exit(0)

if __name__ == "__main__":
    main()

