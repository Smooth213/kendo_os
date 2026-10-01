#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 深層厳格全件スキャナー (Deep Strict Scanner)
=========================================================
test/ 配下の全テストコード（約790ファイル・3,500件以上）に対して、
ユーザーから指定された以下の5大観点を1文字の狂いもなく厳格スキャンします：
1. 絵文字（装飾記号の完全排除。外字 𠮷髙﨑德、ドメイン記号 ◯△▲㋙℃ は保護）
2. 連番（1., 2., ①, ②, Phase, Step, Part, No., #1, & 1-1 等の連番・ナンバリング）
3. 【】/[]の括弧（group先頭の種別タグ以外のすべての【】や[]）
4. 英語と日本語の混在（英文主体のタイトル、動詞句、構文等）
5. 文末表現（末尾が「こと」でないもの、「べき」、二重語尾、括弧直後の「こと」等）
"""

import os
import re

TEST_DIR = 'test'
CALL_RE = re.compile(r'\b(group|test|testWidgets)\s*\(\s*(r?(\"\"\"|\'\'\'|\"|\'))', re.MULTILINE)

# 1. Emoji (excluding domain symbols and gaiji)
EMOJI_RE = re.compile(r'[\U00010000-\U0010ffff\u2600-\u27bf\u2300-\u23ff\u2b50]')
ALLOWED_SPECIAL_CHARS = set('◯△▲㋙℃𠮷髙﨑德')

# 2. Numbering pattern
NUM_PATTERN = re.compile(
    r'(?:^\s*\d+[\.\-:\s]+\s*|^\s*[①-⑳]\s*|^\s*\[\d+\]\s*|^\s*#\d+\s*|\bPhase\s*[\d\.\-\/]+|\bStep\s*[\d\.\-\/]+|&\s*\d+[\-\.]\d+|\bRule\s*\d+[:\s\-]|\bPart\s*\d+[:\s\-]|\bNo\.\s*\d+)',
    re.IGNORECASE
)

# 3. Brackets 【】 or non-category []
def check_brackets(fn, t):
    if '【' in t or '】' in t:
        return True, 'Contains 【 or 】'
    if fn != 'group' and ('[' in t or ']' in t):
        return True, 'Test contains [ or ]'
    if fn == 'group':
        without_tag = re.sub(r'^\[(?:Unit|Widget|Governance|Golden|E2E|Security)\]\s*', '', t)
        if '[' in without_tag or ']' in without_tag:
            return True, 'Group contains non-tag [ or ]'
    return False, ''

# 4. English clauses/sentences
ENG_CLAUSE_PATTERN = re.compile(
    r'\b(renders|displays|updates|preserves|handles|resolves|orders|extracts|sorts|calculates|formats|triggers|returns|swaps|applies|expands|contains|creates|deletes|fetches|loads|parses|validates|verifies|verify|should|when\s+tapped|initial\s+state|default\s+state|can\s+be|fails\s+to|throws|emits)\b',
    re.IGNORECASE
)

# 5. Sentence endings
def check_ending(fn, t):
    if fn == 'group':
        return False, ''
    s = t.strip()
    if not s.endswith('こと'):
        return True, 'Does not end with こと'
    cleaned_for_beki = s.replace('べき等', '').replace('「〜べき」', '')
    if 'べき' in cleaned_for_beki:
        return True, 'Contains べき'
    if re.search(r'(?:ことこと|であることこと|ことであること)$', s):
        return True, 'Double koto ending'
    if re.search(r'[\)）]こと$', s):
        return True, 'Ending with bracket + こと'
    return False, ''

def scan_all():
    all_items = []
    for root, _, files in os.walk(TEST_DIR):
        for f in files:
            if f.endswith('_test.dart'):
                p = os.path.join(root, f)
                with open(p, 'r', encoding='utf-8', errors='ignore') as fp:
                    content = fp.read()

                pos = 0
                while pos < len(content):
                    m = CALL_RE.search(content, pos)
                    if not m:
                        break
                    fn = m.group(1)
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
                    line_no = content[:start].count('\n') + 1
                    all_items.append((fn, title, p, line_no))
                    pos = curr + len(delim)

    print(f'=== 総テスト・グループ定義数: {len(all_items)} 件 ===')

    emoji_hits = []
    num_hits = []
    bracket_hits = []
    eng_hits = []
    ending_hits = []

    for fn, t, p, line in all_items:
        # 1. Emoji
        bad_emojis = [c for c in t if EMOJI_RE.match(c) and c not in ALLOWED_SPECIAL_CHARS]
        if bad_emojis:
            emoji_hits.append((p, line, fn, t, bad_emojis))

        # 2. Numbering
        if NUM_PATTERN.search(t):
            num_hits.append((p, line, fn, t))

        # 3. Brackets
        has_b, b_reason = check_brackets(fn, t)
        if has_b:
            bracket_hits.append((p, line, fn, t, b_reason))

        # 4. English
        if ENG_CLAUSE_PATTERN.search(t):
            eng_hits.append((p, line, fn, t))

        # 5. Ending
        has_e, e_reason = check_ending(fn, t)
        if has_e:
            ending_hits.append((p, line, fn, t, e_reason))

    print(f'1. 絵文字違反: {len(emoji_hits)} 件')
    for p, l, fn, t, em in emoji_hits:
        print(f'   {p}:{l} [{fn}] {t} -> {em}')

    print(f'2. 連番違反: {len(num_hits)} 件')
    for p, l, fn, t in num_hits:
        print(f'   {p}:{l} [{fn}] {t}')

    print(f'3. 括弧違反（【】/[]）: {len(bracket_hits)} 件')
    for p, l, fn, t, r in bracket_hits:
        print(f'   {p}:{l} [{fn}] {t} ({r})')

    print(f'4. 英語混在構文違反: {len(eng_hits)} 件')
    for p, l, fn, t in eng_hits:
        print(f'   {p}:{l} [{fn}] {t}')

    print(f'5. 文末違反: {len(ending_hits)} 件')
    for p, l, fn, t, r in ending_hits:
        print(f'   {p}:{l} [{fn}] {t} ({r})')

if __name__ == '__main__':
    scan_all()
