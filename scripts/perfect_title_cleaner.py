#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - テストタイトル完全クレンジングスクリプト (Perfect Title Cleaner v2)
================================================================================
本スクリプトは、test/ 配下の全テストファイルから以下の5大要素を完全に除去・日本語化します：
1. 絵文字（🛡️, 🚀, 🥋など装飾記号の完全排除。外字・ドメイン記号 ◯△▲㋙℃ 等は保護）
2. 連番・フェーズ表記（【Phase X-Y/Z】, & X-Y:, Step X:, 1., 2. などの完全排除）
3. 【】/[]の括弧の排除（group先頭の [Unit], [Widget], [Governance], [Golden], [E2E], [Security] 以外は完全撤廃し自然な日本語に統合）
4. 英文・英日混在タイトルの完全日本語化
5. 文末表現の統一（すべて自然な動詞＋「こと」に統一、〜べき、体言止め、)こと の完全排除）
"""

import os
import re

# 連番・フェーズ番号の除去パターン
PHASE_NUM_RE = re.compile(
    r'(?:【?\bPhase\s*[\d\.\-\/]+(?:[〜~][\d\.\-\/]+)?】?\s*|&\s*\d+[\-\.]\d+[:\s]*|【?\bStep\s*[\d\.\-\/]+】?[:\s]*|#\d+\s*|^\s*\d+[\.\-\)]\s*|^\s*[-—]\s*)',
    re.IGNORECASE
)

# 装飾絵文字の除去パターン（外字 𠮷髙﨑德 や ドメイン記号 ◯△▲㋙℃ 等は保護）
EMOJI_RE = re.compile(r'[\U00010000-\U0010ffff\u2600-\u27bf\u2300-\u23ff\u2b50]')

# 英文・特定パターンの完全置換マップ
EXACT_REPLACEMENTS = {
    'Comprehensive Bunaiksen Player Category Filter Unit & Integration Verification (All Categories)こと': '部内戦の全選手部門フィルター機能が統合検証できること',
    'Bunaiksen Player Select Category Filterの検証が行えること': '部内戦選手選択の部門フィルター機能が正しく検証できること',
    'OperatorActionButtons viewer preview color matches viewer theme (BlueGrey/Purple)こと': '観客プレビューの色が観客テーマのBlueGreyおよびPurpleと一致すること',
    'OfficialRecordScreen Image share button uses LINE brand green colorであること': '公式記録画面の画像共有ボタンにLINEブランドカラーのグリーンが使用されること',
    'Verify Red/White Swap, Own-Team Tracking, Accordion Integrity & Rule Score Input Propagationであること': '紅白入替および自チーム追跡とアコーディオン整合性ならびにスコア入力伝播が正常に動作すること',
    'Verify My-Team (自チーム) Tracking & Alignment Preservation after Swapであること': 'チーム入替後も自チーム追跡および配置の整合性が維持されること',
    'Verify Strict Preset Reset: Rules not enabled in category preset are strictly turned OFFであること': '部門プリセットで有効化されていないルールが確実にOFFへリセットされること',
    '[Bad Pattern] 色付きDecoratedBoxが直接ListTileをラップすると例外が発生すること': 'アンチパターンとして色付きDecoratedBoxが直接ListTileをラップすると例外が発生すること',
    '[Good Pattern] 中間に透明なMaterialを挟むことで例外を回避できること': '推奨パターンとして中間に透明なMaterialを挟むことで例外を回避できること',
    'MasterManagementScreen Welcome Flow テスト': 'マスタ管理画面 初期ウェルカムフローテスト',
    '& 8-3: Drift & Projection Attack Semantic Drift Attack Simulationであること': '状態ドリフト攻撃シミュレーションが安全に防御されること',
    '& 8-3: Drift & Projection Attack Projection Corruption Detectionであること': '投影データの破損が正常に検知および防御されること',
    'Chaos & Operational Safety (体育館障害耐性) & 7-2: Offline & Sync Delay Chaos (オフライン・遅延同期耐性)こと': 'オフラインおよび遅延同期時のカオス環境で正常に同期されること',
    'Chaos & Operational Safety (体育館障害耐性) Battery Saver Test (省電力モード時の動作低下検証)こと': '省電力モード時でもスコア動作が低下せず正常に機能すること',
    'Chaos & Operational Safety (体育館障害耐性) Tablet Kill Recovery (クラッシュからの完全復旧)こと': '端末クラッシュから試合状態が完全に復旧すること',
    'Chaos & Operational Safety (体育館障害耐性) Concurrent Operator Conflict (同時操作の競合解決)こと': '複数記録係による同時操作の競合が正常に解決されること',
    'Chaos & Operational Safety (体育館障害耐性) Emergency Recovery Drill (緊急人道復旧)こと': '緊急復旧ドリルにより即座に試合状態が復旧すること',
    '& 8-4: Rogue AI & Hallucination テスト Forbidden Pattern Detectionであること': '不正AI入力および禁止パターンが正常に検知および遮断されること',
    'Viewer ユーザーによる特権操作（スコア入力API）呼び出しのゼロトラスト遮断こと': 'Viewerユーザーによる特権スコア入力API呼び出しがゼロトラスト規約により厳格に遮断されること',
    '前後の不可視文字・制御文字・全角スペースの除去と純粋性保証こと': '前後の不可視文字・制御文字・全角スペースが除去され純粋性が保証されること',
    'JS Safe Integer Limitation (64bit整数限界エラー防止)こと': '64bit整数限界によるJavaScriptエラーが防止されること',
    'Isar Web Isolation (Isar Web起動時の自爆クラッシュ防止)こと': 'Web環境でのIsar起動によるクラッシュが確実に防止されること',
    'Single Router Architecture (URL消失・ホワイトアウト防止)こと': 'シングルルーター構成によりURL消失および画面ホワイトアウトが防止されること',
    'Zero Trust AuthGuard Logic (未ログイン観客のスルー検証)こと': '未ログイン観客による不当アクセスがAuthGuardにより遮断されること',
    'addSnapshotToMatch caps snapshots at 1 item by default (sliding window for light memory/DB footprint)こと': 'メモリおよびDB負荷軽減のためスナップショットが最大1件に制限されること',
    'プログラムインデックスの保存と即時復元（メモリキャッシュ＆SharedPreferences）こと': 'メモリキャッシュおよびSharedPreferencesによるプログラムインデックスの保存と即時復元が行えること',
    'PDFページ番号の保存と即時復元（メモリキャッシュ＆SharedPreferences）こと': 'メモリキャッシュおよびSharedPreferencesによるPDFページ番号の保存と即時復元が行えること',
    'sortTeams by court orders teams by court number then match orderであること': '試合順の前にコート番号順でチームが正常にソートされること',
    'sortTeams by matchOrder orders teams by match sequenceであること': '試合順序のシーケンス順にチームが正常にソートされること',
    'sortTeams by status orders live matches first, then waiting, then finishedであること': '進行中・待機中・終了済みの優先順序でチームが正常にソートされること',
    'tryClaimScorer succeeds when scorerId is nullであること': '記録係IDが未設定の場合に記録権限の取得に成功すること',
    'Design Regression Prevention: App-wide Dialog (16px) & BottomSheet (20px) Themeの検証が行えること': 'アプリ全体のダイアログおよびボトムシートの角丸テーマが正常に検証できること',
    'Empty UIの登録ボタンが幅240に制限されていること': 'データ空UIの登録ボタンの幅が240に制限されていること',
    '待機時タイマー沈黙＆イベント駆動化規約 (setInterval禁止＆preload保証)こと': '待機時のタイマーが沈黙しイベント駆動化規約が保証されること',
    'テキストパーサーによるセクションおよびチーム形式検出（3人制・5人制）こと': 'テキストパーサーによるセクションおよびチーム形式の検出が行えること',
    '空文字 → エラー（コード入力を求める）こと': '空文字入力時にコード入力を求めるエラーが発生すること',
}

def clean_brackets(t):
    # 【...】の除去と自然な展開
    def replace_sumitsuki(m):
        content = m.group(1).strip()
        # 英単語や定型句の日本語化
        bracket_map = {
            'Partial Write': '部分書き込み失敗時において',
            'Duplicate Event': '重複イベント受信時において',
            'Timestamp逆転': 'タイムスタンプ逆転時において',
            'Offline Resume': 'オフライン復旧時において',
            'Firestore完全停止': 'Firestore完全停止時において',
            '10秒高遅延耐性': '10秒高遅延耐性において',
            '同期中切断レジリエンス': '同期中切断レジリエンスにおいて',
            '部内戦': '部内戦において',
            'Zero Trust': 'ゼロトラスト規約において',
            'Web/Native共通': 'WebおよびNative共通環境において',
            '推奨パターン': '推奨パターンとして',
            'アンチパターン': 'アンチパターンとして',
            'ヒント色は同じグレー': 'ヒント色検証として',
            'セマンティックドリフト': 'セマンティックドリフト検証として',
            'プロジェクション破損': 'プロジェクション破損検知として',
            '体育館障害耐性': '体育館障害耐性として',
            '不正パターン検知': '不正パターン検知として',
            'ゼロトラスト': 'ゼロトラスト規約として',
            '文字列サニタイズ': '文字列サニタイズとして',
            'JavaScript安全性': 'JavaScript安全性として',
            'Web分離': 'Web分離として',
            'シングルルーター': 'シングルルーター構成として',
            'スナップショット上限': 'スナップショット上限として',
            'プログラムインデックス': 'プログラムインデックスとして',
            'PDFページ番号': 'PDFページ番号として',
            '整合性検証': '整合性検証として',
            'OperatorActionButtons': '操作アクションボタンにおいて',
            'OfficialRecordScreen': '公式記録画面において',
            '個人リーグ戦': '個人リーグ戦において',
            '団体戦': '団体戦において',
            '個人戦': '個人戦において',
            '基本動作': '基本動作として',
            '異常系': '異常系として',
            '正常系': '正常系として',
            '境界値': '境界値として',
        }
        res = bracket_map.get(content, f'{content}において')
        return res + ' '

    t = re.sub(r'【(.*?)】', replace_sumitsuki, t)

    # [...] の角括弧（グループ先頭のタグ [Unit], [Widget], [Governance], [Golden], [E2E], [Security] 以外）
    def replace_square(m):
        content = m.group(1).strip()
        square_map = {
            'Web/Native共通': 'WebおよびNative共通環境で、',
            'Zero Trust': 'ゼロトラスト規約のもとで、',
            'Bad Pattern': 'アンチパターンとして、',
            'Good Pattern': '推奨パターンとして、',
        }
        return square_map.get(content, f'{content}に関して、')

    # 先頭以外の角括弧を置換
    t = re.sub(r'(?<!^)\[(.*?)\]', replace_square, t)
    # 先頭にあっても許可タグでなければ置換
    if t.startswith('['):
        m = re.match(r'^\[(Unit|Widget|Governance|Golden|E2E|Security)\]', t)
        if not m:
            t = re.sub(r'^\[(.*?)\]\s*', replace_square, t)

    return t

def clean_title(title, fn):
    t = title.strip()

    # 1. 完全一致マップ
    if t in EXACT_REPLACEMENTS:
        t = EXACT_REPLACEMENTS[t]

    # 2. 絵文字除去（外字 𠮷髙﨑德、ドメイン記号 ◯△▲㋙℃ 等は保護）
    cleaned_chars = []
    for c in t:
        if c in '𠮷髙﨑德◯△▲㋙℃' or not EMOJI_RE.match(c):
            cleaned_chars.append(c)
    t = ''.join(cleaned_chars).strip()

    # 3. 連番・フェーズ表記の完全除去
    t = PHASE_NUM_RE.sub('', t).strip()
    t = re.sub(r'^\s*[-—]\s*', '', t).strip()

    # 4. 【】および[]の括弧の解除（groupの先頭タグ以外）
    if fn != 'group':
        t = clean_brackets(t)
    else:
        # groupの場合、先頭のタグを取り出し、残りをクレンジング
        m_tag = re.match(r'^(\[(?:Unit|Widget|Governance|Golden|E2E|Security)\])\s*(.*)', t)
        if m_tag:
            tag = m_tag.group(1)
            rest = clean_brackets(m_tag.group(2))
            t = f'{tag} {rest}'
        else:
            t = clean_brackets(t)

    # 5. 末尾の不自然な括弧＋こと の解消: e.g. 〜 (補足)こと -> 補足において〜こと
    m_bracket_end = re.search(r'^(.*?)\s*[\(（]([^\)）]+)[\)）]こと$', t)
    if m_bracket_end:
        body = m_bracket_end.group(1).strip()
        note = m_bracket_end.group(2).strip()
        t = f'{note}において{body}こと'

    # 6. 残存英文フレーズの日本語化
    t = re.sub(r'\bDrift Monitor時:\s*', 'ドリフト監視時において、', t)
    t = re.sub(r'\bAll Categories\b', '全カテゴリー', t)
    t = re.sub(r'\bMatchModel\s+MatchEntity\s+MatchModel\b', 'MatchModelとMatchEntityの双方向変換', t)

    # 7. group 先頭タグの整形
    if fn == 'group':
        # 重複スペース除去
        t = re.sub(r'\s+', ' ', t).strip()
        # [Tag] の直後に不要な記号がある場合
        t = re.sub(r'^(\[(?:Unit|Widget|Governance|Golden|E2E|Security)\])\s*[-—・:]\s*', r'\1 ', t)

    # 8. test/testWidgets の文末表現正規化
    if fn != 'group':
        # 「〜べき」の排除
        t = re.sub(r'すべきである$', 'すること', t)
        t = re.sub(r'べきである$', 'こと', t)
        t = re.sub(r'べき$', 'こと', t)
        # 「〜テスト」「〜の検証」で終わっている場合の動詞化
        t = re.sub(r'の検証が行えること$', 'が正しく検証できること', t)
        t = re.sub(r'検証テスト$', '検証できること', t)
        t = re.sub(r'テスト$', '正しく動作すること', t)
        
        # 二重語尾の解消
        t = re.sub(r'(?:であること|こと)+$', '', t).strip()
        if not t.endswith('こと'):
            t = t + 'こと'

    # 余分な空白、全角空白の連続を正規化
    t = re.sub(r'[ 　]+', ' ', t).strip()
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
        new_title = clean_title(orig, fn)
        if new_title != orig:
            replacements.append((orig, new_title, start, end))

    if not replacements:
        return content, 0

    new_content = content
    for orig, new_title, start, end in reversed(replacements):
        if orig != new_title:
            new_content = new_content[:start] + new_title + new_content[end:]

    return new_content, len(replacements)

def main():
    test_files = []
    for root, _, files in os.walk('test'):
        for file in files:
            if file.endswith('_test.dart'):
                test_files.append(os.path.join(root, file))
    test_files.sort()

    total_files = 0
    total_titles = 0

    for tf in test_files:
        new_content, count = process_file(tf)
        if count > 0:
            total_files += 1
            total_titles += count
            with open(tf, 'w', encoding='utf-8') as f:
                f.write(new_content)

    print(f"✅ クレンジング完了: {total_files} ファイル / {total_titles} 箇所修正")

if __name__ == '__main__':
    main()
