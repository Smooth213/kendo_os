#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 【第205条 ガバナンス監査】🗄️ データベース整合性・Firestore複合クエリ ＆ インデックス契約完全保証規約
================================================================================
① firestore.indexes.json の妥当性・必須コレクション複合インデックス定義検証
② コード内 Firestore クエリ（where + orderBy）と indexes.json の完全整合性照合
③ インデックス不整合による未定義インデックス実行時例外（FAILED_PRECONDITION）100%防止
"""

import json
import os
import subprocess
import sys

def check_firestore_indexes_json():
    indexes_file = "firestore.indexes.json"
    if not os.path.exists(indexes_file):
        return False, "firestore.indexes.json が存在しません。"

    try:
        with open(indexes_file, "r", encoding="utf-8") as f:
            data = json.load(f)
    except Exception as e:
        return False, f"firestore.indexes.json のパースに失敗しました: {e}"

    if "indexes" not in data or not isinstance(data["indexes"], list):
        return False, "indexes 配列が存在しません。"

    indexes = data["indexes"]
    collection_groups = {idx.get("collectionGroup") for idx in indexes if "collectionGroup" in idx}

    required_collections = {"matches", "announcements", "programs"}
    missing = required_collections - collection_groups
    if missing:
        return False, f"必須コレクションのインデックスが不足しています: {missing}"

    return True, "firestore.indexes.json 正常"

def main():
    print("=" * 68)
    print(" 📊 【第205条 ガバナンス監査】🗄️ データベース整合性・Firestore複合クエリ ＆ インデックス契約完全保証規約")
    print("=" * 68)

    ok_json, msg = check_firestore_indexes_json()
    status_json = "🟢 適合 (Passed)" if ok_json else "🔴 違反 (Failed)"
    print(f" ① [インデックス契約定義] firestore.indexes.json 整合性検証: {status_json}")
    if not ok_json:
        print(f"    ❌ 詳細: {msg}")

    # flutter test 実行
    cmd = [
        "flutter",
        "test",
        "test/governance/firestore_indexes_governance_test.dart",
        "--reporter=expanded",
    ]
    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    ok_test = (res.returncode == 0)
    status_test = "🟢 適合 (Passed)" if ok_test else "🔴 違反 (Failed)"
    print(f" ② [クエリ契約照合] コード内複合クエリ ＆ インデックス完全合致規約: {status_test}")

    all_passed = ok_json and ok_test
    print("-" * 68)
    if all_passed:
        print(" 🟢 監査結果: 合格 (データベース整合性・Firestoreインデックス契約に完全適合！)")
        print("=" * 68)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (第205条 Firestoreインデックス契約に違反があります)")
        print("=" * 68)
        if not ok_test:
            print(res.stdout + res.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
