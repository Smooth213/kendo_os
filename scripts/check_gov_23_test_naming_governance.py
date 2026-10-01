#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 【第23条 ガバナンス監査】🧪 テスト設計・タイトル命名規約 ＆ テストスイート整合性規約
================================================================================
本監査は、test/ 配下の全テストコード（約790ファイル・3,500件以上）に対して、
以下の6大規約を1文字の妥協もなく厳格に監査し、違反を100%遮断します：

① [装飾絵文字完全撤廃規約] group, test, testWidgets 内の装飾絵文字の完全排除
② [テスト連番・ナンバリング排除規約] 先頭連番 1. 2. ① ② Step 1: Phase 1: #1 等の完全排除
③ [【】/[] 括弧排除規約] 最上位種別タグ以外の【】および[]の完全排除
④ [文末「こと」統一＆文法規約] 末尾「こと」統一、「〜べき」排除、二重語尾排除、括弧直後「)こと」排除
⑤ [英語混在・英文タイトル排除規約] 英文構文（renders/verify/should/returns等）の排除と日本語統一
⑥ [テスト種別タグ規約] 最上位 group の [Unit]/[Widget]/[Governance]/[Golden]/[E2E]/[Security] プレフィックス準拠
"""

import os
import re
import sys

# ① 装飾絵文字の検出パターン（剣道ドメイン記号 ◯, △, ▲, ℃, ㋙, 人名外字 𠮷髙﨑德 等は除外）
EMOJI_PATTERN = re.compile(
    r'[\U0001F300-\U0001F9FF'
    r'\U0001FA00-\U0001FAFF'
    r'\u2600-\u27BF'
    r'\u2300-\u23FF'
    r'\uFE0F'
    r'\u203C\u2049\u2139'
    r']'
)
ALLOWED_SPECIAL_CHARS = set('◯△▲㋙℃𠮷髙﨑德')

# ② 先頭連番・ナンバリングパターン
NUMBERING_PATTERN = re.compile(
    r'(?:^\s*\d+[\.\-:\s]+\s*|^\s*[①-⑳]\s*|^\s*\[\d+\]\s*|^\s*#\d+\s*|\bPhase\s*[\d\.\-\/]+|\bStep\s*[\d\.\-\/]+|&\s*\d+[\-\.]\d+|\bRule\s*\d+[:\s\-]|\bPart\s*\d+[:\s\-]|\bNo\.\s*\d+)',
    re.IGNORECASE
)

# ③ 括弧パターン（最上位タグ以外）
ALLOWED_TAGS = {'[Unit]', '[Widget]', '[Governance]', '[Golden]', '[E2E]', '[Security]'}
TAG_PATTERN = re.compile(r'^\[(Unit|Widget|Governance|Golden|E2E|Security)\]')

def check_brackets_violation(fn_name, title, is_top_group):
    # 【】はいかなる場合も禁止
    if '【' in title or '】' in title:
        return True
    # [] のチェック
    if fn_name != 'group':
        if '[' in title or ']' in title:
            return True
    else:
        if is_top_group:
            without_tag = TAG_PATTERN.sub('', title).strip()
            if '[' in without_tag or ']' in without_tag:
                return True
        else:
            if '[' in title or ']' in title:
                return True
    return False

# ④ 文末表現パターン
DOUBLE_KOTO_PATTERN = re.compile(r'(?:ことこと|であることこと|ことであること)$')
BRACKET_KOTO_PATTERN = re.compile(r'[\)）]こと$')

# ⑤ 英文構文パターン
ENGLISH_CLAUSE_PATTERN = re.compile(
    r'\b(renders|displays|updates|preserves|handles|resolves|orders|extracts|sorts|calculates|formats|triggers|returns|swaps|applies|expands|contains|creates|deletes|fetches|loads|parses|validates|verifies|verify|should|when\s+tapped|initial\s+state|default\s+state|can\s+be|fails\s+to|throws|emits)\b',
    re.IGNORECASE
)

def scan_dart_test_file(filepath):
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()

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
    bracket_violations = []
    koto_violations = []
    english_violations = []
    tag_violations = []

    for tf in test_files:
        items = scan_dart_test_file(tf)
        has_top_group = False
        for fn_name, title, _ in items:
            title_clean = title.strip()

            # ① 絵文字チェック
            bad_emojis = [c for c in title_clean if EMOJI_PATTERN.search(c) and c not in ALLOWED_SPECIAL_CHARS]
            if bad_emojis:
                emoji_violations.append((tf, fn_name, title_clean))

            # 最上位グループ判定
            is_top_group = False
            if fn_name == 'group' and not has_top_group:
                has_top_group = True
                is_top_group = True
                # ⑥ 最上位groupは種別タグで始まること
                if not TAG_PATTERN.match(title_clean):
                    tag_violations.append((tf, fn_name, title_clean))

            # ③ 【】/[] 括弧チェック
            if check_brackets_violation(fn_name, title_clean, is_top_group):
                bracket_violations.append((tf, fn_name, title_clean))

            if fn_name != 'group':
                # ② 連番チェック (test, testWidgets)
                if NUMBERING_PATTERN.search(title_clean):
                    numbering_violations.append((tf, fn_name, title_clean))

                # ④ 文末「こと」＆文法チェック
                cleaned_for_beki = title_clean.replace('べき等', '').replace('「〜べき」', '')
                if (not title_clean.endswith('こと') or
                    'べき' in cleaned_for_beki or
                    DOUBLE_KOTO_PATTERN.search(title_clean) or
                    BRACKET_KOTO_PATTERN.search(title_clean)):
                    koto_violations.append((tf, fn_name, title_clean))

                # ⑤ 英文構文タイトルのチェック
                hiragana_count = len(re.findall(r'[\u3040-\u309F]', title_clean))
                if (hiragana_count < 6 and ENGLISH_CLAUSE_PATTERN.search(title_clean)) or (title_clean.startswith(('should', 'can ', 'renders', 'verify', 'displays'))):
                    english_violations.append((tf, fn_name, title_clean))

    return emoji_violations, numbering_violations, bracket_violations, koto_violations, english_violations, tag_violations

def main():
    print("=" * 68)
    print(" 📊 【第23条 ガバナンス監査】🧪 テスト設計・タイトル命名規約 ＆ テストスイート整合性規約")
    print("====================================================================")

    emoji_v, num_v, bracket_v, koto_v, en_v, tag_v = audit_tests()

    rules = [
        ("① [装飾絵文字排除] group, test, testWidgets 内の装飾絵文字の完全排除", len(emoji_v) == 0, emoji_v),
        ("② [テスト連番排除] test, testWidgets 先頭の連番・ナンバリングの排除", len(num_v) == 0, num_v),
        ("③ [【】/[] 括弧排除] 最上位種別タグ以外の【】および[]の完全排除", len(bracket_v) == 0, bracket_v),
        ("④ [文末「こと」統一＆文法規約] 「〜べき」排除、二重語尾排除、末尾「こと」統一", len(koto_v) == 0, koto_v),
        ("⑤ [英語混在・英文タイトル排除] 英文主体のテストタイトル排除と日本語統一", len(en_v) == 0, en_v),
        ("⑥ [テスト種別タグ] 最上位 group の [Unit]/[Widget]/[Governance]/[Golden]/[E2E]/[Security] プレフィックス準拠", len(tag_v) == 0, tag_v),
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
        print("====================================================================")
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (第23条 テスト設計・タイトル命名規約に違反があります)")
        print("====================================================================")
        sys.exit(1)

if __name__ == "__main__":
    main()
