#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 【第23条 ガバナンス監査】🧪 テスト設計・タイトル命名規約 ＆ テストスイート整合性規約
================================================================================
① 装飾絵文字完全撤廃規約（group, test, testWidgets 内の装飾絵文字の完全排除）
② テスト連番排除規約（先頭のナンバリング 1. 2. ① ② Step 1: 等の排除）
③ 文末「〜こと」統一規約（test, testWidgets の末尾がすべて「こと」で完結すること）
④ テスト種別タグ規約（group の最上位プレフィックス [Unit], [Widget], [Governance], [Golden], [E2E], [Security] 準拠）
"""

import os
import re
import sys
import subprocess

# 装飾絵文字の検出パターン（剣道ドメイン記号 ◯, △, ▲, ℃, ㋙, 人名漢字 𠮷 等は除外）
EMOJI_PATTERN = re.compile(
    r'[\U0001F300-\U0001F9FF'
    r'\U0001FA00-\U0001FAFF'
    r'\u2600-\u27BF'
    r'\u2300-\u23FF'
    r'\uFE0F'
    r'\u203C\u2049\u2139'
    r']'
)

# 先頭連番パターン
NUMBERING_PATTERN = re.compile(
    r'^(?:\d+[\.\-]\s*|\d+-\d+[\.\-]?\s*|[①-⑳]\s*|\[\d+\]\s*|#\d+\s*|Step\s*\d+(?:-\d+)?[:\.\s]*|Phase\s*\d+[:\s\-]*)',
    re.IGNORECASE
)

ALLOWED_TAGS = {'[Unit]', '[Widget]', '[Governance]', '[Golden]', '[E2E]', '[Security]'}
TAG_PATTERN = re.compile(r'^\[(Unit|Widget|Governance|Golden|E2E|Security)\]')

def scan_dart_test_file(filepath):
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()

    # 関数呼び出しを正確にスキャン
    call_pattern = re.compile(r'\b(group|test|testWidgets)\s*\(\s*(r?(\"\"\"|\'\'\'|\"|\'))', re.MULTILINE)

    pos = 0
    items = []
    while pos < len(content):
        m = call_pattern.search(content, pos)
        if not m:
            break
        fn_name = m.group(1)
        delim = m.group(3)
        start = m.end()
        curr = start
        escaped = False
        while curr < len(content):
            if delim in ('\"\"\"', '\'\'\''):
                if content.startswith(delim, curr):
                    break
                curr += 1
            else:
                if escaped:
                    escaped = False
                elif content[curr] == '\\':
                    escaped = True
                elif content[curr] == delim:
                    break
                curr += 1
        title = content[start:curr]
        items.append((fn_name, title, m.start()))
        pos = curr + len(delim)
    return items

def audit_tests():
    test_files = []
    for root, _, files in os.walk('test'):
        for file in files:
            if file.endswith('_test.dart'):
                test_files.append(os.path.join(root, file))

    emoji_violations = []
    numbering_violations = []
    koto_violations = []
    tag_violations = []

    for tf in test_files:
        items = scan_dart_test_file(tf)
        has_top_group = False
        for fn_name, title, _ in items:
            title_clean = title.strip()

            # ① 絵文字チェック
            if EMOJI_PATTERN.search(title_clean):
                emoji_violations.append((tf, fn_name, title_clean))

            if fn_name == 'group':
                if not has_top_group:
                    has_top_group = True
                    # 最上位groupは種別タグで始まる必要がある
                    if not TAG_PATTERN.match(title_clean):
                        tag_violations.append((tf, fn_name, title_clean))
            else:
                # ② 連番チェック (test, testWidgets)
                if NUMBERING_PATTERN.search(title_clean):
                    numbering_violations.append((tf, fn_name, title_clean))

                # ③ 文末「こと」チェック (test, testWidgets)
                # 括弧閉じや空白を除いた末尾が「こと」であること
                if not title_clean.endswith('こと'):
                    koto_violations.append((tf, fn_name, title_clean))

    return emoji_violations, numbering_violations, koto_violations, tag_violations

def main():
    print("=" * 68)
    print(" 📊 【第23条 ガバナンス監査】🧪 テスト設計・タイトル命名規約 ＆ テストスイート整合性規約")
    print("=" * 68)

    emoji_v, num_v, koto_v, tag_v = audit_tests()

    rules = [
        ("① [装飾絵文字排除] group, test, testWidgets 内の装飾絵文字の完全排除", len(emoji_v) == 0, emoji_v),
        ("② [テスト連番排除] test, testWidgets 先頭の連番・ナンバリングの排除", len(num_v) == 0, num_v),
        ("③ [文末「こと」統一] test, testWidgets の末尾がすべて「こと」で完結すること", len(koto_v) == 0, koto_v),
        ("④ [テスト種別タグ] 最上位 group の [Unit]/[Widget]/[Governance]/[Golden]/[E2E]/[Security] プレフィックス準拠", len(tag_v) == 0, tag_v),
    ]

    all_passed = True
    for label, ok, violations in rules:
        status = "🟢 適合 (Passed)" if ok else f"🔴 違反 ({len(violations)}件 Failed)"
        print(f" {label}: {status}")
        if not ok:
            all_passed = False
            for tf, fn, title in violations[:3]:
                print(f"   - [{tf}] {fn}('{title[:50]}...')")
            if len(violations) > 3:
                print(f"   ... 他 {len(violations) - 3} 件")

    print("-" * 68)
    if all_passed:
        print(" 🟢 監査結果: 合格 (第23条 テスト設計・タイトル命名規約 ＆ テストスイート整合性規約に完全適合！)")
        print("=" * 68)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (第23条 テスト設計・タイトル命名規約に違反があります)")
        print("=" * 68)
        sys.exit(1)

if __name__ == "__main__":
    main()
