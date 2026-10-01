#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - テストタイトル完全日本語化・統一ツール (Phase 3)
================================================================================
本ツールは、test/ 配下の全テストに残っている英語混在タイトル（約1,200件）を、
ドメイン知識・構文解析に基づき、美しく自然な日本語（【条件・操作】〜こと）に
完全ローカライズ・統一します。
"""

import os
import re
import sys
import argparse

# 構文置換パターン（優先度順）
PATTERNS = [
    # Verify renders patterns
    (r'\bVerify\s+([A-Za-z0-9_]+)\s+renders\s+([A-Za-z0-9_]+)\s+with\s+(.+?)(?:であること|こと)?$',
     r'【\1】\3のとき、\2が正しく描画されること'),
    (r'\bVerify\s+([A-Za-z0-9_]+)\s+renders\s+([A-Za-z0-9_]+)(?:であること|こと)?$',
     r'【\1】\2が正しく描画されること'),
    (r'\bVerify\s+([A-Za-z0-9_]+)\s+renders\s+(.+?)(?:であること|こと)?$',
     r'【\1】\2が正しく描画されること'),
    (r'\b([A-Za-z0-9_]+)\s+renders\s+correctly\s+with\s+(.+?)(?:であること|こと)?$',
     r'【\1】\2で正しく描画されること'),
    (r'\b([A-Za-z0-9_]+)\s+renders\s+correctly\s+in\s+dark\s+and\s+light\s+modes(?:であること|こと)?$',
     r'【\1】ダーク・ライト両モードで正しく描画されること'),
    (r'\b([A-Za-z0-9_]+)\s+renders\s+correctly\s+when\s+(.+?)(?:であること|こと)?$',
     r'【\1】\2のときに正しく描画されること'),
    (r'\b([A-Za-z0-9_]+)\s+renders\s+correctly(?:であること|こと)?$',
     r'【\1】正しく描画されること'),
    (r'\b([A-Za-z0-9_]+)\s+renders\s+without\s+crashes\s+under\s+([A-Za-z0-9_]+)\s+mode(?:であること|こと)?$',
     r'【\2モード】\1がクラッシュせずに正しく描画されること'),
    (r'\b([A-Za-z0-9_]+)\s+renders\s+without\s+crashes(?:であること|こと)?$',
     r'【\1】クラッシュせずに正しく描画されること'),
    (r'\b([A-Za-z0-9_]+)\s+renders\s+properly(?:であること|こと)?$',
     r'【\1】適切に描画されること'),
    (r'\b([A-Za-z0-9_]+)\s+renders\s+empty\s+state(?:であること|こと)?$',
     r'【\1】空状態（Empty State）が正しく描画されること'),
    (r'\b([A-Za-z0-9_]+)\s+renders\s+empty\s+widget(?:であること|こと)?$',
     r'【\1】空ウィジェットとして描画されること'),
    (r'\b([A-Za-z0-9_]+)\s+renders\s+all\s+buttons(?:であること|こと)?$',
     r'【\1】すべてのボタンが正しく描画されること'),
    (r'\b([A-Za-z0-9_]+)\s+renders\s+(.+?)(?:であること|こと)?$',
     r'【\1】\2が描画されること'),

    # Should show / display / return patterns
    (r'\b(?:Should\s+NOT\s+show|should\s+not\s+show)\s+(.+?)\s+when\s+(.+?)(?:であること|こと)?$',
     r'【\2】\1が表示されないこと'),
    (r'\b(?:Should\s+NOT\s+show|should\s+not\s+show)\s+(.+?)(?:であること|こと)?$',
     r'\1が表示されないこと'),
    (r'\b(?:Should\s+show|should\s+show)\s+(.+?)\s+when\s+(.+?)(?:であること|こと)?$',
     r'【\2】\1が表示されること'),
    (r'\b(?:Should\s+show|should\s+show)\s+(.+?)(?:であること|こと)?$',
     r'\1が表示されること'),
    (r'\b(?:Should\s+return|should\s+return)\s+(.+?)\s+when\s+(.+?)(?:であること|こと)?$',
     r'【\2】\1が返却されること'),
    (r'\b(?:Should\s+return|should\s+return)\s+(.+?)(?:であること|こと)?$',
     r'\1が返却されること'),
    (r'\b([A-Za-z0-9_]+)\s+should\s+display\s+(.+?)(?:であること|こと)?$',
     r'【\1】\2が表示されること'),
    (r'\b([A-Za-z0-9_]+)\s+should\s+render\s+(.+?)(?:であること|こと)?$',
     r'【\1】\2が描画されること'),

    # Returns true / false / empty patterns
    (r'\breturns\s+true\s+when\s+(.+?)(?:であること|こと)?$',
     r'【\1】trueが返却されること'),
    (r'\breturns\s+false\s+when\s+(.+?)(?:であること|こと)?$',
     r'【\1】falseが返却されること'),
    (r'\breturns\s+empty\s+when\s+(.+?)(?:であること|こと)?$',
     r'【\1】空のデータが返却されること'),

    # Triggers / Handles / Updates
    (r'\btriggers\s+(.+?)\s+when\s+tapped(?:であること|こと)?$',
     r'タップ時に\1がトリガーされること'),
    (r'\btriggers\s+(.+?)\s+when\s+(.+?)(?:であること|こと)?$',
     r'【\2】\1がトリガーされること'),
    (r'\bhandles\s+(.+?)\s+properly(?:であること|こと)?$',
     r'\1が適切に処理されること'),
    (r'\bhandles\s+(.+?)\s+correctly(?:であること|こと)?$',
     r'\1が正しく処理されること'),
    (r'\bupdates\s+(.+?)\s+when\s+(.+?)(?:であること|こと)?$',
     r'【\2】\1が正しく更新されること'),
    (r'\binitializes\s+with\s+(.+?)(?:であること|こと)?$',
     r'\1で正しく初期化されること'),
    (r'\bformat\s+(.+?)\s+correctly(?:であること|こと)?$',
     r'\1が正しくフォーマットされること'),
    (r'\bcalculate\s+(.+?)\s+correctly(?:であること|こと)?$',
     r'\1が正しく計算されること'),
    (r'\bsort\s+(.+?)\s+correctly(?:であること|こと)?$',
     r'\1が正しくソートされること'),

    # Can be patterns
    (r'\b([A-Za-z0-9_]+)\s+can\s+be\s+instantiated\s+correctly(?:であること|こと)?$',
     r'【\1】正常にインスタンス化できること'),
    (r'\b([A-Za-z0-9_]+)\s+can\s+be\s+compiled\s+and\s+instantiated(?:であること|こと)?$',
     r'【\1】正常にコンパイルおよびインスタンス化できること'),

    # Renders in dark / light mode
    (r'\bRenders\s+in\s+dark\s+mode(?:であること|こと)?$',
     r'ダークモードで正しく描画されること'),
    (r'\bRenders\s+in\s+light\s+mode(?:であること|こと)?$',
     r'ライトモードで正しく描画されること'),
    (r'\bRenders\s+in\s+dark\s+and\s+light\s+modes(?:であること|こと)?$',
     r'ダーク・ライト両モードで正しく描画されること'),
]

# 単語レベルの安全な日英置換
WORD_REPLACEMENTS = [
    (r'\bwhen tapped\b', 'タップ時'),
    (r'\bwhen clicked\b', 'クリック時'),
    (r'\bin dark mode\b', 'ダークモード時'),
    (r'\bin light mode\b', 'ライトモード時'),
    (r'\bwithout error\b', 'エラーなしで'),
    (r'\bwithout crash\b', 'クラッシュなしで'),
    (r'\bwithout crashes\b', 'クラッシュなしで'),
    (r'\bwithout overflow\b', 'オーバーフローなしで'),
    (r'\bempty state\b', '空状態'),
    (r'\bempty list\b', '空リスト'),
    (r'\bdefault values\b', '初期値'),
    (r'\bdefault value\b', '初期値'),
    (r'\bcorrectly\b', '正しく'),
    (r'\bproperly\b', '適切に'),
    (r'\bsuccessfully\b', '正常に'),
    (r'\binvalid input\b', '不正入力時'),
    (r'\bvalid input\b', '有効入力時'),
    (r'\bpreserves existing rule teamName and category\b', '既存ルールのチーム名および部門情報が保持される'),
    (r'\bis clearly displayed\b', 'が明確に表示される'),
    (r'\bpreserves\b', 'が保持される'),
    (r'\bmatches\b', 'と一致する'),
    (r'\bdisplays\b', 'が表示される'),
    (r'\bupdates\b', 'が更新される'),
    (r'\bcalculates\b', 'が計算される'),
    (r'\bformats\b', 'がフォーマットされる'),
    (r'\bsorts\b', 'がソートされる'),
]

def localize_group_title(title):
    t = title.strip()
    tag_match = re.match(r'^(\[(?:Unit|Widget|Governance|Golden|E2E|Security)\])\s*', t)
    tag = tag_match.group(1) + ' ' if tag_match else ''
    body = t[len(tag):].strip()

    # 英語グループの翻訳
    body = re.sub(r'\bWidget Tests?\b', 'ウィジェットテスト', body, flags=re.I)
    body = re.sub(r'\bUnit Tests?\b', '単体テスト', body, flags=re.I)
    body = re.sub(r'\bIntegration Tests?\b', '統合テスト', body, flags=re.I)
    body = re.sub(r'\bRegression Tests?\b', 'リグレッションテスト', body, flags=re.I)
    body = re.sub(r'\bTests?\b', 'テスト', body, flags=re.I)
    body = re.sub(r'\bVerifications?\b', '検証', body, flags=re.I)
    body = re.sub(r'\bComponents?\b', 'コンポーネント', body, flags=re.I)
    body = re.sub(r'\bDisplay & Dark Mode\b', '表示 ＆ ダークモード', body, flags=re.I)
    body = re.sub(r'\bDesign Regression Prevention\b', 'デザインリグレッション防止', body, flags=re.I)
    body = re.sub(r'\bPlatform Consistency\b', 'プラットフォーム整合性', body, flags=re.I)
    body = re.sub(r'\bZero Trust\b', 'ゼロトラスト', body, flags=re.I)
    body = re.sub(r'\bBulk Rule Edit\b', '一括ルール編集', body, flags=re.I)
    body = re.sub(r'\bCategory Rule Presets\b', '部門別ルールプリセット', body, flags=re.I)
    body = re.sub(r'\bTheme Integration & Color\b', 'テーマ統合 ＆ カラー', body, flags=re.I)
    body = re.sub(r'\bOrder Drag & Drop Reordering\b', 'オーダー並び替え', body, flags=re.I)
    body = re.sub(r'\bQuick Match\b', 'クイックマッチ', body, flags=re.I)
    body = re.sub(r'\bUI Error\b', 'UIエラー', body, flags=re.I)
    body = re.sub(r'\bMatch Edit & Creation Flow Expansion\b', '試合編集・作成フロー拡張', body, flags=re.I)
    body = re.sub(r'\bWelcome Flow\b', '初期ウェルカムフロー', body, flags=re.I)

    # クラス名単体の場合、末尾に「テスト」を付与
    if not re.search(r'(テスト|検証|保証|フロー|規約)$', body) and not body.endswith(']'):
        body = body + ' テスト'

    return f'{tag}{body}'.strip()

def localize_test_title(title):
    t = title.strip()

    # 先頭のVerify等を除去
    # パターンマッチ
    applied = False
    for pat, repl in PATTERNS:
        if re.search(pat, t, flags=re.I):
            t = re.sub(pat, repl, t, flags=re.I)
            applied = True
            break

    if not applied:
        # 単語置換
        for pat, repl in WORD_REPLACEMENTS:
            t = re.sub(pat, repl, t, flags=re.I)

    # 二重「であること」「こと」のクリーンアップ
    t = re.sub(r'(?:であること|こと)+$', '', t).strip()

    # 日本語の文末助動詞の付与
    if (t.endswith('れる') or t.endswith('ない') or t.endswith('する') or
        t.endswith('できる') or t.endswith('ある') or t.endswith('いる') or
        t.endswith('なる') or t.endswith('される')):
        t = t + 'こと'
    elif t.endswith('だ') or t.endswith('です'):
        t = t[:-1] + 'であること'
    elif re.search(r'[a-zA-Z0-9]$', t):
        t = t + 'であること'
    else:
        t = t + 'こと'

    # 整形
    t = re.sub(r'\s+', ' ', t).strip()
    return t

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()

    call_pattern = re.compile(r'\b(group|test|testWidgets)\s*\(\s*(r?(\"\"\"|\'\'\'|\"|\'))', re.MULTILINE)

    matches = []
    pos = 0
    while pos < len(content):
        m = call_pattern.search(content, pos)
        if not m: break
        fn = m.group(1)
        delim = m.group(3)
        start = m.end()
        curr = start
        escaped = False
        while curr < len(content):
            if delim in ('\"\"\"', '\'\'\''):
                if content.startswith(delim, curr): break
                curr += 1
            else:
                if escaped: escaped = False
                elif content[curr] == '\\': escaped = True
                elif content[curr] == delim: break
                curr += 1
        if curr <= len(content):
            matches.append((fn, content[start:curr], start, curr))
            pos = curr + len(delim)
        else:
            pos = m.end()

    replacements = []
    for fn, orig, start, end in matches:
        # Check if title has significant ascii
        letters = [c for c in orig if c.isalpha()]
        ascii_letters = [c for c in letters if c.isascii()]
        is_english = len(letters) > 5 and len(ascii_letters) / len(letters) > 0.6
        if is_english:
            if fn == 'group':
                new_title = localize_group_title(orig)
            else:
                new_title = localize_test_title(orig)
            replacements.append((orig, new_title, start, end))

    if not replacements:
        return content, 0

    new_content = content
    for orig, new_title, start, end in reversed(replacements):
        if orig != new_title:
            new_content = new_content[:start] + new_title + new_content[end:]

    return new_content, len(replacements)

def main():
    parser = argparse.ArgumentParser(description="Kendo OS テストタイトル完全日本語化ツール")
    parser.add_argument("--dry-run", action="store_true", help="変更を保存せず、件数・差分のみ表示")
    parser.add_argument("--target", type=str, default="test", help="対象ディレクトリまたはファイル")
    args = parser.parse_args()

    target_files = []
    if os.path.isfile(args.target):
        target_files.append(args.target)
    elif os.path.isdir(args.target):
        for root, _, files in os.walk(args.target):
            for file in files:
                if file.endswith('_test.dart'):
                    target_files.append(os.path.join(root, file))
    target_files.sort()

    print("=" * 68)
    print(" 🥋 Kendo OS - テストタイトル完全日本語化ツール (Phase 3)")
    print("=" * 68)
    print(f" 対象ファイル数: {len(target_files)} 件")
    print(f" モード: {'🔍 DRY RUN (差分確認のみ)' if args.dry_run else '✍️ WRITE (実ファイル更新)'}")
    print("-" * 68)

    total_files = 0
    total_titles = 0
    for tf in target_files:
        with open(tf, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
        new_content, count = process_file(tf)
        if count > 0:
            total_files += 1
            total_titles += count
            if not args.dry_run:
                with open(tf, 'w', encoding='utf-8') as f:
                    f.write(new_content)

    print(f" 更新対象ファイル: {total_files} 件")
    print(f" 日本語化タイトル総数: {total_titles} 件")
    print("=" * 68)

if __name__ == "__main__":
    main()
