#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ==============================================================================
# 🥋 kendo OS - 【ガバナンス監査 16/18】📚 アプリ内マニュアル＆取説整合性 監査スクリプト
# ==============================================================================
import json
import os
import re
import subprocess
import sys

TARGET_CATEGORIES = ["quickstart", "recovery", "operator", "viewer", "faq"]

def check_manual_integrity():
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    manuals_dir = os.path.join(base_dir, "packages", "documentation_runtime", "manuals")
    index_file = os.path.join(manuals_dir, "manual_search_index.json")

    errors = {
        "index_missing": [],
        "line_limit": [],
        "deprecated_words": [],
        "broken_links": [],
    }

    if not os.path.exists(index_file):
        return False, {"index_file_missing": ["manual_search_index.json が存在しません"]}

    with open(index_file, "r", encoding="utf-8") as f:
        try:
            index_data = json.load(f)
        except Exception as e:
            return False, {"index_parse_error": [f"パース失敗: {e}"]}

    indexed_paths = {item.get("path", "").replace("\\", "/") for item in index_data}

    link_regex = re.compile(r'\[([^\]]+)\]\(([^)]+)\)')

    # 1. カテゴリ内ファイルの検証
    for cat in TARGET_CATEGORIES:
        cat_dir = os.path.join(manuals_dir, cat)
        if not os.path.isdir(cat_dir):
            continue

        for root, _, files in os.walk(cat_dir):
            for file in files:
                if not file.endswith(".md"):
                    continue

                full_path = os.path.join(root, file)
                rel_path = os.path.relpath(full_path, base_dir).replace("\\", "/")

                # インデックス登録漏れチェック
                if rel_path not in indexed_paths:
                    errors["index_missing"].append(rel_path)

                with open(full_path, "r", encoding="utf-8") as f:
                    lines = f.readlines()

                # 行数チェック (500行上限)
                if len(lines) > 500:
                    errors["line_limit"].append(f"{rel_path} ({len(lines)}行)")

                content = "".join(lines)

                # 非推奨語句チェック ("スコアラー")
                if "スコアラー" in content:
                    errors["deprecated_words"].append(rel_path)

                # 相対リンク切れチェック
                for m in link_regex.finditer(content):
                    link = m.group(2)
                    if (link.startswith("http://") or link.startswith("https://") or 
                        link.startswith("#") or link.startswith("mailto:")):
                        continue
                    clean_link = link.split("#")[0]
                    if not clean_link:
                        continue
                    target_path = os.path.normpath(os.path.join(os.path.dirname(full_path), clean_link))
                    if not os.path.exists(target_path):
                        errors["broken_links"].append(f"{rel_path} -> {link}")

    has_error = any(len(v) > 0 for v in errors.values())
    return (not has_error), errors

def run_manual_governance():
    integrity_ok, errors = check_manual_integrity()

    # マニュアル関連テスト実行
    test_files = [
        "test/unit/manuals/manual_integrity_test.dart",
        "test/unit/manuals/manual_search_and_query_test.dart",
        "test/widget/manual_pane_search_integration_test.dart",
        "test/golden/manual_ui_integrity_golden_test.dart",
    ]

    cmd = ["flutter", "test"] + test_files + ["--reporter=expanded"]
    result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    tests_ok = (result.returncode == 0)

    rules = [
        ("1. manual_search_index.json 全件登録・同期完全性規約", len(errors["index_missing"]) == 0),
        ("2. マニュアル間リンク（Markdown相対リンク）デッドリンクゼロ規約", len(errors["broken_links"]) == 0),
        ("3. ドキュメント憲法（全ファイル500行以内・単一責任）規約", len(errors["line_limit"]) == 0),
        ("4. 非推奨・廃止語句（スコアラー等）排除規約", len(errors["deprecated_words"]) == 0),
        ("5. マニュアル自動テスト（整合性・クエリ検索・UI Widget・Golden）100%合格規約", tests_ok),
    ]

    passed_all = all(is_ok for _, is_ok in rules)

    print("=" * 60)
    print(" 📊 【ガバナンス監査 16/18】📚 アプリ内マニュアル＆取説整合性 監査レポート")
    print("=" * 60)

    for label, is_ok in rules:
        status = "🟢 適合 (Passed)" if is_ok else "🔴 違反 (Failed)"
        print(f" {label}: {status}")

    print("-" * 60)
    if passed_all:
        print(" 🟢 監査結果: 合格 (全取説・インデックス・検索UI・Goldenテスト完全整合！)")
        print("=" * 60)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (マニュアル整合性またはテストに問題があります)")
        print("=" * 60)
        for key, err_list in errors.items():
            if err_list:
                print(f"  ❌ {key}: {err_list}")
        if not tests_ok:
            print("\n🚨 テスト実行エラー:")
            try:
                from test_failure_formatter import parse_and_format_failures
                print(parse_and_format_failures(result.stdout + result.stderr))
            except Exception:
                print(result.stdout + result.stderr)
        sys.exit(1)

if __name__ == "__main__":
    run_manual_governance()
