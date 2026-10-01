#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - テストタイトル新フォーマット一括自動整形ツール
================================================================================
本ツールは、test/ 配下のテストファイルに含まれる group, test, testWidgets のタイトルを、
プロジェクト新命名規約（第23条）に準拠するように安全に一括整形します。
"""

import os
import re
import sys
import argparse

# 装飾絵文字正規表現（剣道ドメイン記号 ◯, △, ▲, ℃, ㋙, 人名漢字 𠮷 等は保持）
EMOJI_PATTERN = re.compile(
    r'[\U0001F300-\U0001F9FF'
    r'\U0001FA00-\U0001FAFF'
    r'\u2600-\u27BF'
    r'\u2300-\u23FF'
    r'\uFE0F'
    r'\u203C\u2049\u2139'
    r']+'
)

# 連番正規表現
NUMBERING_PATTERN = re.compile(
    r'^(?:\d+[\.\-:\s]+\s*|\d+-\d+[\.\-:\s]*\s*|[①-⑳]\s*|\[\d+\]\s*|#\d+\s*|Step\s*\d+(?:-\d+)?[:\.\s]*|Phase\s*\d+[:\s\-]*)',
    re.IGNORECASE
)

TAG_PATTERN = re.compile(r'^\[(Unit|Widget|Governance|Golden|E2E|Security)\]')

def determine_tag_for_file(filepath, file_content):
    norm = filepath.replace('\\', '/')
    if '/governance/' in norm or '/performance/' in norm:
        return '[Governance]'
    if '/golden/' in norm:
        return '[Golden]'
    if any(k in norm for k in ['/e2e/', '/chaos/', '/offline/', '/endurance/', '/firestore_failure/']):
        return '[E2E]'
    if '/security/' in norm:
        return '[Security]'
    if '/widget/' in norm or '/ui/' in norm:
        return '[Widget]'
    if '/unit/' in norm:
        return '[Unit]'
    if '/features/' in norm or '/shared/' in norm:
        if any(w in norm for w in ['/screens/', '/widgets/', '/components/', '/views/']):
            return '[Widget]'
        if any(u in norm for u in ['/providers/', '/models/', '/domain/', '/services/', '/infrastructure/', '/utils/', '/errors/']):
            return '[Unit]'
        if 'testWidgets(' in file_content:
            return '[Widget]'
        return '[Unit]'
    if 'testWidgets(' in file_content:
        return '[Widget]'
    return '[Unit]'

def strip_numbering_completely(text):
    t = text.strip()
    while True:
        m = NUMBERING_PATTERN.search(t)
        if m:
            t = t[m.end():].strip()
        else:
            break
    return t

def clean_group_title(title, default_tag, is_top_group):
    t = EMOJI_PATTERN.sub('', title).strip()
    t = strip_numbering_completely(t)

    # 英語グループの一般的な翻訳
    t = re.sub(r'\bIntegration Tests?\b', '統合テスト', t, flags=re.I)
    t = re.sub(r'\bWidget Tests?\b', 'ウィジェットテスト', t, flags=re.I)
    t = re.sub(r'\bUnit Tests?\b', '単体テスト', t, flags=re.I)
    t = re.sub(r'\bRegression Tests?\b', 'リグレッションテスト', t, flags=re.I)
    t = re.sub(r'\bTests?\b', 'テスト', t, flags=re.I)
    t = re.sub(r'\bVerifications?\b', '検証', t, flags=re.I)
    t = t.strip()

    m_tag = TAG_PATTERN.match(t)
    if is_top_group:
        if m_tag:
            return t
        else:
            return f'{default_tag} {t}'.strip()
    else:
        return t

# 英語タイトルマッピング辞書
EXACT_TRANSLATIONS = {
    'toKanjiNumber converts numbers to kanji correctly': '数値を漢数字へ正しく変換できること',
    'generatePositions generates correct positions for various team sizes': '各種チーム人数に対して正しいポジションが生成されること',
    'getPositionPriority returns correct priority for positions': 'ポジションに応じた正しい優先順位が返却されること',
    'sortMatches sorts scrambled 8-person team matches correctly': '8人制団体戦の順序が正しくソートされること',
    'sortMatches sorts scrambled 9-person team matches correctly with Chuken': '中堅を含む9人制団体戦の順序が正しくソートされること',
    'sortMatches sorts scrambled 10-person team matches correctly': '10人制団体戦の順序が正しくソートされること',
    'sortMatches handles arabic fallback positions correctly': 'アラビア数字のフォールバックポジションが正しく処理されること',
    'sortMatches sorts scrambled 3-person team matches correctly': '3人制団体戦の順序が正しくソートされること',
    'sortMatches prioritizes position over incorrect order': '不正な順序よりもポジションが優先されてソートされること',
    'sortProjections sorts 5-person plus daihyo match correctly': '5人制＋代表戦の投影が正しくソートされること',
    'resolveMatchPriority extracts position from note or player name if matchType is empty': 'matchTypeが空の場合に備考や選手名からポジション優先度を抽出できること',
    'NotificationService compiles and instantiates correctly': 'NotificationServiceが正常にコンパイルおよびインスタンス化されること',
    'Provider successfully resolves NotificationService': 'ProviderからNotificationServiceが正常に解決されること',
    'registerPushNotification returns safely if Firebase is not initialized': 'Firebase未初期化時にregisterPushNotificationが安全に復帰すること',
    'No Edit buttons in ViewerHomeScreenであること': 'ViewerHomeScreenに編集ボタンが表示されないこと',
}

def clean_test_title(title):
    t = EMOJI_PATTERN.sub('', title).strip()
    t = strip_numbering_completely(t)
    t = re.sub(r'^[✅❌🛡️🚀🥋]\s*', '', t).strip()

    # 末尾の補足括弧の処理 (例: 〜こと(Zero Trust) -> 【Zero Trust】〜こと)
    m_bracket = re.search(r'^(.*?)(こと|べき|れる|ない|する|ある|なる|です|ます)[、。\s]*[\(（]([^\)）]+)[\)）]$', t)
    if m_bracket:
        prefix_note = m_bracket.group(3).strip()
        body = m_bracket.group(1) + m_bracket.group(2)
        t = f'【{prefix_note}】{body}'

    # 句点の除去
    if t.endswith('。'):
        t = t[:-1].strip()

    # 完全一致辞書
    if t in EXACT_TRANSLATIONS:
        return EXACT_TRANSLATIONS[t]

    # 特殊な日本語文末対応
    if t.endswith('カンマのみを挿入しないか、あるいはスマートに扱うか'):
        return '空文字の場合はカンマのみを挿入せず適切に処理されること'
    if t.endswith('カンマと半角スペースを挿入する'):
        return '既存テキストの末尾にカーソルがある場合、カンマと半角スペースが挿入されること'
    if t.endswith('二重にカンマを挿入しない'):
        return t + 'こと'
    if t.endswith('重複挿入せず適切にフォーマット'):
        return t + 'されること'
    if t.endswith('その位置にカンマと空白を挿入しカーソルを進める'):
        return '文章の途中にカーソルがある場合、その位置にカンマと空白が挿入されカーソルが進むこと'
    if t.endswith('選択範囲をカンマと空白で置換する'):
        return '選択範囲がある場合、選択範囲がカンマと空白で置換されること'
    if t.endswith('全ポジション名の文字色視認性検証'):
        return t[:-2] + 'が確認できること'

    # 英語タイトルの置換
    t = re.sub(r'\brenders correctly with dynamic theme colors\b', '動的テーマカラーで正しく描画されること', t, flags=re.I)
    t = re.sub(r'\brenders correctly in dark and light modes\b', 'ダーク・ライト両モードで正しく描画されること', t, flags=re.I)
    t = re.sub(r'\bis themed correctly in dark and light modes\b', 'ダーク・ライト両モードでテーマが正しく適用されること', t, flags=re.I)
    t = re.sub(r'\brenders without crashes under \b', '〜モードでクラッシュせずに正しく描画されること: ', t, flags=re.I)
    t = re.sub(r'\brenders without crashes\b', 'クラッシュせずに正しく描画されること', t, flags=re.I)
    t = re.sub(r'\brenders correctly\b', '正しく描画されること', t, flags=re.I)

    # 英語タイトルの末尾 Verification
    if t.endswith('Verification') or t.endswith('verification'):
        t = re.sub(r'\s*Verification$', 'の検証が行えること', t, flags=re.I)

    # すでに「こと」で終わっていればOK
    if t.endswith('こと'):
        return t

    # 「べき」の変換
    if t.endswith('べきである'):
        t = t[:-5] + 'ること'
    elif t.endswith('るべき'):
        t = t[:-3] + 'ること'
    elif t.endswith('れるべき'):
        t = t[:-4] + 'れること'
    elif t.endswith('ないべき'):
        t = t[:-4] + 'ないこと'
    elif t.endswith('すべき'):
        t = t[:-3] + 'すること'
    elif t.endswith('べき'):
        t = t[:-2] + 'こと'

    # 「〜れる」「〜ない」「〜する」「〜できる」「〜ある」「〜いる」「〜なる」
    elif (t.endswith('れる') or t.endswith('ない') or t.endswith('する') or
          t.endswith('できる') or t.endswith('ある') or t.endswith('いる') or
          t.endswith('なる') or t.endswith('される') or t.endswith('えられない')):
        t = t + 'こと'

    # 体言止め・名詞末尾
    elif t.endswith('を検証') or t.endswith('の検証'):
        t = re.sub(r'[をの]検証$', '', t) + 'が正しく検証できること'
    elif t.endswith('を確認') or t.endswith('の確認'):
        t = re.sub(r'[をの]確認$', '', t) + 'が確認できること'
    elif t.endswith('をチェック'):
        t = t[:-5] + 'が正常に行われること'
    elif t.endswith('チェック'):
        t = t[:-4] + 'が確認できること'
    elif t.endswith('テスト'):
        t = t[:-3] + 'が正常に機能すること'
    elif t.endswith('検証'):
        t = t[:-2] + 'が正しく検証されること'
    elif t.endswith('確認'):
        t = t[:-2] + 'が確認できること'

    # 末尾が記号や等式
    elif re.search(r'(=|→|->)\s*(false|true|null|\d+|[\'\"].*?[\'\"])$', t):
        t = t + 'であること'
    elif re.search(r'[a-zA-Z0-9]$', t):
        t = t + 'であること'
    else:
        t = t + 'こと'

    return t

def format_file_content(content, filepath):
    default_tag = determine_tag_for_file(filepath, content)
    call_pattern = re.compile(r'\b(group|test|testWidgets)\s*\(\s*(r?(\"\"\"|\'\'\'|\"|\'))', re.MULTILINE)

    matches = []
    pos = 0
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
        if curr <= len(content):
            orig_title = content[start:curr]
            matches.append((fn_name, orig_title, start, curr))
            pos = curr + len(delim)
        else:
            pos = m.end()

    has_top_group = False
    replacements = []
    for fn_name, orig_title, start, end in matches:
        if fn_name == 'group':
            is_top = not has_top_group
            has_top_group = True
            new_title = clean_group_title(orig_title, default_tag, is_top)
        else:
            new_title = clean_test_title(orig_title)
        replacements.append((orig_title, new_title, start, end))

    new_content = content
    for orig_title, new_title, start, end in reversed(replacements):
        if orig_title != new_title:
            new_content = new_content[:start] + new_title + new_content[end:]

    return new_content, len([r for r in replacements if r[0] != r[1]])

def main():
    parser = argparse.ArgumentParser(description="Kendo OS テストタイトル自動整形ツール")
    parser.add_argument("--dry-run", action="store_true", help="変更を保存せず、差分・件数のみを表示")
    parser.add_argument("--target", type=str, default="test", help="処理対象のディレクトリまたはファイル (デフォルト: test)")
    args = parser.parse_args()

    target_files = []
    if os.path.isfile(args.target):
        target_files.append(args.target)
    elif os.path.isdir(args.target):
        for root, _, files in os.walk(args.target):
            for file in files:
                if file.endswith('_test.dart'):
                    target_files.append(os.path.join(root, file))
    else:
        print(f"❌ 対象が見つかりません: {args.target}")
        sys.exit(1)

    target_files.sort()
    print("=" * 68)
    print(" 🥋 Kendo OS - テストタイトル自動整形ツール")
    print("=" * 68)
    print(f" 対象ファイル数: {len(target_files)} 件")
    print(f" モード: {'🔍 DRY RUN (差分確認のみ)' if args.dry_run else '✍️ WRITE (実ファイル更新)'}")
    print("-" * 68)

    total_changed_files = 0
    total_changed_titles = 0

    for tf in target_files:
        with open(tf, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()

        new_content, changed_count = format_file_content(content, tf)
        if changed_count > 0:
            total_changed_files += 1
            total_changed_titles += changed_count
            if args.dry_run and total_changed_files <= 5:
                print(f"📝 [{tf}] {changed_count} 箇所変更予定")
            elif not args.dry_run:
                with open(tf, 'w', encoding='utf-8') as f:
                    f.write(new_content)

    print("-" * 68)
    print(f" 変更対象ファイル: {total_changed_files} / {len(target_files)}")
    print(f" 変更タイトル総数: {total_changed_titles} 件")
    print("=" * 68)

if __name__ == "__main__":
    main()
