#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 【第102条 ガバナンス監査】📚 大会運用マニュアル ＆ 独立ルール安全フォールバック規約
================================================================================
① アプリ内マニュアル＆取説整合性規約
② 独立カテゴリ・ルール設定フォールバック安全規約
③ マニュアルルートID・実体Markdown 1対1整合性静的保証規約
④ README ＆ docs 体系的デッドリンク完全ゼロ ＆ 索引登録網羅性静的保証規約
"""

import subprocess
import sys

SUB_AUDITS = [
    ("① アプリ内マニュアル＆取説整合性規約", ["python3", "scripts/check_manual_governance.py"]),
    ("② 独立カテゴリ・ルール設定フォールバック安全規約", ["python3", "scripts/check_category_rules_governance.py"]),
    (
        "③ マニュアルルートID・実体Markdown 1対1整合性静的保証規約",
        ["python3", "scripts/gov_test_helper.py", "test/governance/manual_route_integrity_governance_test.dart"],
    ),
]

def main():
    print("=" * 68)
    print(" 📊 【第102条 ガバナンス監査】📚 大会運用マニュアル ＆ 独立ルール安全フォールバック規約")
    print("=" * 68)

    import os
    import re

    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(script_dir)

    # ③ マニュアルルートID・実体Markdown 1対1整合性静的保証 (Python自前検証)
    route_file = os.path.join(project_root, "packages/documentation_runtime/lib/manual_routes.dart")
    manual_routes_ok = True
    missing_manual_paths = []

    if os.path.isfile(route_file):
        with open(route_file, "r", encoding="utf-8") as f:
            c = f.read()
        paths = re.findall(r"['\"](packages/documentation_runtime/manuals/[^'\"]+\.md)['\"]", c)
        if not paths:
            paths = re.findall(r"['\"](manuals/[^'\"]+\.md)['\"]", c)
        for p in paths:
            full = os.path.join(project_root, p)
            if not os.path.exists(full):
                full = os.path.join(project_root, "packages/documentation_runtime", p)
            if not os.path.exists(full):
                manual_routes_ok = False
                missing_manual_paths.append(p)
    else:
        manual_routes_ok = False

    all_passed = True
    for label, cmd in SUB_AUDITS[:2]:
        res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        is_ok = (res.returncode == 0)
        status = "🟢 適合 (Passed)" if is_ok else "🔴 違反 (Failed)"
        print(f" {label}: {status}")
        if not is_ok:
            all_passed = False
            print(f"\n--- [詳細エラー: {label}] ---")
            print(res.stdout + res.stderr)
            print("-" * 40)

    status3 = "🟢 適合 (Passed)" if manual_routes_ok else "🔴 違反 (Failed)"
    print(f" ③ マニュアルルートID・実体Markdown 1対1整合性静的保証規約: {status3}")
    if not manual_routes_ok:
        all_passed = False
        print(f"  ❌ 未実体マニュアルファイル: {missing_manual_paths}")

    # ④ README ＆ docs 体系的デッドリンク完全ゼロ ＆ 索引登録網羅性静的保証規約
    import glob
    docs_files = [os.path.join(project_root, "README.md")] + glob.glob(
        os.path.join(project_root, "docs/**/*.md"), recursive=True
    )
    link_pattern = re.compile(r"\[([^\]]+)\]\(([^)]+)\)")
    dead_links = []

    for f_path in docs_files:
        if not os.path.isfile(f_path):
            continue
        with open(f_path, "r", encoding="utf-8") as fp:
            content = fp.read()
        dir_path = os.path.dirname(f_path)
        for text, url in link_pattern.findall(content):
            url = url.strip()
            if url.startswith(("http://", "https://", "mailto:")):
                continue
            clean_url = url.split("#")[0]
            if not clean_url:
                continue
            target_path = os.path.normpath(os.path.join(dir_path, clean_url))
            if not os.path.exists(target_path):
                rel_f = os.path.relpath(f_path, project_root)
                dead_links.append((rel_f, text, url))

    # 索引登録網羅性検証 (index.mdを持つdocsサブディレクトリを対象に孤立ファイルを検知)
    unindexed_docs = []
    docs_base = os.path.join(project_root, "docs")
    if os.path.isdir(docs_base):
        for sub in sorted(os.listdir(docs_base)):
            sub_dir = os.path.join(docs_base, sub)
            if not os.path.isdir(sub_dir):
                continue
            idx_file = os.path.join(sub_dir, "index.md")
            if not os.path.isfile(idx_file):
                continue
            with open(idx_file, "r", encoding="utf-8") as fp:
                idx_content = fp.read()
            for child in sorted(os.listdir(sub_dir)):
                if child.endswith(".md") and child != "index.md":
                    if child not in idx_content:
                        rel_child = os.path.join("docs", sub, child)
                        unindexed_docs.append(rel_child)

    docs_integrity_ok = (len(dead_links) == 0 and len(unindexed_docs) == 0)
    status4 = "🟢 適合 (Passed)" if docs_integrity_ok else "🔴 違反 (Failed)"
    print(f" ④ README ＆ docs 体系的デッドリンク完全ゼロ ＆ 索引登録網羅性静的保証規約: {status4}")
    if not docs_integrity_ok:
        all_passed = False
        if dead_links:
            print("  ❌ デッドリンク検知:")
            for rel_f, text, url in dead_links:
                print(f"     - [{rel_f}] [{text}]({url})")
        if unindexed_docs:
            print("  ❌ 未登録・孤立ドキュメント検知 (親 index.md に未記載):")
            for u in unindexed_docs:
                print(f"     - {u}")

    print("-" * 68)
    if all_passed:
        print(" 🟢 監査結果: 合格 (大会運用マニュアル ＆ 独立ルール安全フォールバック規約に完全適合！)")
        print("=" * 68)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (第102条 大会運用マニュアル ＆ 独立ルール安全フォールバック規約に違反があります)")
        print("=" * 68)
        sys.exit(1)

if __name__ == "__main__":
    main()
