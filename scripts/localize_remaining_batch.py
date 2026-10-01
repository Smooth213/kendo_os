#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 残存英語タイトル（279件）の完全職人ローカライズ
"""

import json
import os
import re

PATTERNS_2 = [
    # Renders patterns
    (r'^Renders\s+([A-Za-z0-9_]+)\s+and\s+displays\s+(.+?)(?:こと)?$',
     r'【\1】描画され、\2が表示されること'),
    (r'^([A-Za-z0-9_]+)\s+renders\s+player\s+name\s+and\s+matches(?:こと)?$',
     r'【\1】選手名と試合一覧が正しく描画されること'),
    (r'^Renders\s+download\s+card\s+when\s+not\s+downloaded(?:こと)?$',
     r'未ダウンロード時にダウンロードカードが正しく描画されること'),
    (r'^Renders\s+downloading\s+indicator\s+when\s+isDownloading\s+is\s+true(?:こと)?$',
     r'ダウンロード中（isDownloading=true）にインジケータが正しく描画されること'),
    (r'^Renders\s+markdown\s+fallback\s+header\s+when\s+forceMarkdownFallback\s+is\s+true(?:こと)?$',
     r'マークダウン強制フォールバック時にフォールバックヘッダーが正しく描画されること'),
    (r'^Renders\s+simple\s+scene\s+rule\s+form\s+and\s+handles\s+type\s+toggle(?:こと)?$',
     r'シンプルシーンルールフォームが描画され形式トグルが正常に操作できること'),
    (r'^Renders\s+minute\s+and\s+second\s+text\s+fields\s+with\s+initial\s+values(?:こと)?$',
     r'分・秒のテキストフィールドが初期値とともに正しく描画されること'),
    (r'^Updates\s+value\s+and\s+returns\s+computed\s+total\s+minutes\s+on\s+submit(?:こと)?$',
     r'送信時に値が更新され計算された合計分が正しく返却されること'),
    (r'^([A-Za-z0-9_]+)\s+renders\s+rule\s+summary\s+and\s+switches\s+correctly(?:こと)?$',
     r'【\1】ルール概要が描画され切り替えが正常に行えること'),
    (r'^Renders\s+(.+?)\s+when\s+(.+?)(?:こと)?$',
     r'【\2】\1が正しく描画されること'),
    (r'^Renders\s+(.+?)(?:こと)?$',
     r'\1が正しく描画されること'),

    # Should patterns
    (r'^([A-Za-z0-9_]+)\s+should\s+download\s+file\s+and\s+trigger\s+onProgress(?:こと)?$',
     r'【\1】ファイルがダウンロードされonProgressがトリガーされること'),
    (r'^([A-Za-z0-9_]+)\s+should\s+delete\s+the\s+file\s+from\s+storage(?:こと)?$',
     r'【\1】ストレージからファイルが正常に削除されること'),
    (r'^([A-Za-z0-9_]+)\s+should\s+(.+?)(?:こと)?$',
     r'【\1】\2すること'),

    # Returns patterns
    (r'^([A-Za-z0-9_]+)\s+returns\s+valid\s+UTF-8\s+bytes\s+with\s+BOM(?:こと)?$',
     r'【\1】BOM付きの有効なUTF-8バイト列が返却されること'),
    (r'^([A-Za-z0-9_]+)\s+returns\s+(.+?)\s+when\s+(.+?)(?:こと)?$',
     r'【\1】\3のとき、\2が返却されること'),
    (r'^([A-Za-z0-9_]+)\s+returns\s+(.+?)(?:こと)?$',
     r'【\1】\2が返却されること'),

    # Handles patterns
    (r'^([A-Za-z0-9_]+)\s+handles\s+empty\s+categoryRules\s+correctly\s+for\s+backward\s+compatibility(?:こと)?$',
     r'【\1】後方互換性のため空のcategoryRulesが適切に処理されること'),
    (r'^([A-Za-z0-9_]+)\s+handles\s+empty\s+events\s+gracefully\s+without\s+throwing(?:こと)?$',
     r'【\1】空イベント時に例外をスローせず安全に処理されること'),
    (r'^([A-Za-z0-9_]+)\s+handles\s+(.+?)\s+correctly(?:こと)?$',
     r'【\1】\2が正しく処理されること'),
    (r'^([A-Za-z0-9_]+)\s+handles\s+(.+?)(?:こと)?$',
     r'【\1】\2が適切に処理されること'),

    # Converts patterns
    (r'^toEntity\s+&\s+toModel\s+correctly\s+converts\s+([A-Za-z0-9_]+)\s+with\s+(.+?)(?:こと)?$',
     r'【双方向変換】toEntityおよびtoModelにより\2付きの\1が正しく変換されること'),

    # General phrases
    (r'^Bunaiksen\s+and\s+Standard\s+Viewer\s+Routing\s+Isolation\s*\((.+?)\)(?:こと)?$',
     r'【ルーティング隔離】\1が正常に機能すること'),
    (r'^Keyword\s+detection\s+analysis\s+テスト\s+for\s+advanced\s+rounds\s+テスト$',
     r'[Unit] 上位回戦（準決勝・決勝等）のキーワード検知分析テスト'),
]

# 単語レベルの安全な日英置換
WORD_SUBS = [
    (r'\bmatches\s+order\b', '試合順序'),
    (r'\bmatches\b', '試合一覧'),
    (r'\bmatch\b', '試合'),
    (r'\bplayers\b', '選手一覧'),
    (r'\bplayer\b', '選手'),
    (r'\bteams\b', 'チーム一覧'),
    (r'\bteam\b', 'チーム'),
    (r'\brules\b', 'ルール設定'),
    (r'\brule\b', 'ルール'),
    (r'\bcourt\b', 'コート'),
    (r'\bscore\b', 'スコア'),
    (r'\borders\b', '順序'),
    (r'\border\b', '順序'),
    (r'\bbunaiksen\b', '部内戦'),
    (r'\btournament\b', '大会'),
    (r'\bcategory\b', '部門'),
    (r'\bcategories\b', '部門一覧'),
    (r'\bviewer\b', '観客'),
    (r'\boperator\b', '記録係'),
    (r'\badmin\b', '管理者'),
    (r'\bdialog\b', 'ダイアログ'),
    (r'\bbottom\s+sheet\b', 'ボトムシート'),
    (r'\bbuttons\b', 'ボタン一覧'),
    (r'\bbutton\b', 'ボタン'),
    (r'\bchips\b', 'チップ一覧'),
    (r'\bchip\b', 'チップ'),
    (r'\bcard\b', 'カード'),
    (r'\btable\b', 'テーブル'),
    (r'\bheader\b', 'ヘッダー'),
    (r'\bfooter\b', 'フッター'),
    (r'\bbanner\b', 'バナー'),
    (r'\btexts\b', 'テキスト一覧'),
    (r'\btext\b', 'テキスト'),
    (r'\btitle\b', 'タイトル'),
    (r'\bselection\b', '選択'),
    (r'\btap\b', 'タップ'),
    (r'\bclick\b', 'クリック'),
    (r'\bdrag\b', 'ドラッグ'),
    (r'\bdrop\b', 'ドロップ'),
    (r'\bsync\b', '同期'),
    (r'\bcloud\b', 'クラウド'),
    (r'\bstorage\b', 'ストレージ'),
    (r'\bcache\b', 'キャッシュ'),
    (r'\boffline\b', 'オフライン'),
    (r'\bonline\b', 'オンライン'),
    (r'\berror\b', 'エラー'),
    (r'\bsuccess\b', '成功'),
    (r'\bfailure\b', '失敗'),
    (r'\bloading\b', '読み込み中'),
    (r'\bfinished\b', '終了済み'),
    (r'\bin\s+progress\b', '進行中'),
    (r'\bwaiting\b', '待機中'),
]

def translate_remaining(title, fn):
    t = title.strip()
    for pat, repl in PATTERNS_2:
        if re.search(pat, t, flags=re.I):
            t = re.sub(pat, repl, t, flags=re.I)
            break

    # 単語置換
    for pat, repl in WORD_SUBS:
        t = re.sub(pat, repl, t, flags=re.I)

    # Clean up double koto
    t = re.sub(r'(?:であること|こと)+$', '', t).strip()

    if fn == 'group':
        if not re.search(r'(テスト|検証|保証|フロー|規約)$', t) and not t.endswith(']'):
            t = t + ' テスト'
        return t

    # Ensure ends with こと
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

    t = re.sub(r'(?:であること|こと)+$', '', t).strip()
    t = t + 'こと'
    return t

def main():
    with open('scratch_remaining_targets.json') as f:
        targets = json.load(f)

    file_map = {}
    for item in targets:
        f = item[0]
        if f not in file_map:
            file_map[f] = []
        file_map[f].append((item[1], item[2]))

    total = 0
    for filepath, items in file_map.items():
        if not os.path.exists(filepath): continue
        with open(filepath, 'r', encoding='utf-8') as fp:
            content = fp.read()

        new_content = content
        for fn, orig in items:
            trans = translate_remaining(orig, fn)
            if trans != orig and orig in new_content:
                new_content = new_content.replace(orig, trans, 1)
                total += 1

        if new_content != content:
            with open(filepath, 'w', encoding='utf-8') as fp:
                fp.write(new_content)

    print(f"✅ 残存英語タイトルの日本語化完了: {total} 箇所")

if __name__ == '__main__':
    main()
