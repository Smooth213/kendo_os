#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - テストタイトル完全日本語化・職人品質統一スクリプト (Phase 3 最終適用)
================================================================================
本スクリプトは、英語文が残っている全ターゲット（346件）を抽出し、
完全手動レベルの美しい日本語タイトル（【条件・操作】〜こと）に置換します。
"""

import json
import os
import re
import sys

# 完全手動翻訳辞書（頻出＆重要テスト）
EXACT_TRANSLATIONS = {
    'Verify Bunaiksen Quick Match Player Selection Category Filter (High Grade & Beginner Chips)こと': '【部内戦】クイックマッチ選手選択の部門フィルター（高学年・低学年チップ）が正しく機能すること',
    'Verify active Dojo ID is clearly displayed on LoginScreen (Light & Dark Mode)こと': '【LoginScreen】ライト・ダーク両モードでアクティブな道場IDが明確に表示されること',
    'Verify 2-line Dojo ID card on RoleSelectScreen without overflow (Light & Dark Mode)こと': '【RoleSelectScreen】ライト・ダーク両モードで道場IDカードが2行でオーバーフローなく表示されること',
    'Verify bulkUpdateMatchRules preserves existing rule teamName and categoryであること': '【一括更新】bulkUpdateMatchRules実行時に既存ルールのチーム名および部門情報が保持されること',
    'Verify BulkRuleEditSheet renders Category Rules presets chip and applies selectionであること': '【BulkRuleEditSheet】部門別ルールプリセットチップが表示され選択が適用されること',
    'Verify 2-Stage Selection: Selecting Category dynamically expands Scene Sub-Chips (Honsen, Renseikai, Moushiawase)こと': '【2段階選択】部門選択時にシーン別サブチップ（本戦・練習会・申合せ）が動的に展開されること',
    'Verify Smart Auto-Reset: Non-applicable rules (e.g. Hantei for Team matches) are automatically turned OFFであること': '【スマート自動リセット】団体戦の判定など適用不可なルールが自動的にOFFになること',
    'Verify Strict Preset Reset: Rules not enabled in category preset are strictly turned OFFであること': '【厳格プリセット】部門プリセットで無効なルールが厳格にOFFになること',
    'Verify Renseikai & Moushiawase Scenes strictly turn OFF personal hantei, extension, and representative matchであること': '【シーン設定】練習会・申合せシーンで個人の判定・延長・代表戦が厳格にOFFになること',
    'Verify Full Execution Flow: Tapping Apply Bulk Rule updates target matches and preserves teamName/categoryであること': '【一括適用】一括ルール適用タップ時に対象試合が更新されチーム名・部門が保持されること',
    'CreateTournamentScreen is themed correctly with Indigo focus and gradient colorsであること': '【CreateTournamentScreen】Indigoフォーカスおよびグラデーションカラーでテーマが正しく適用されること',
    'OrderSetupScreen and BunaiksenSetupScreen render without crashes under Bunaiksen modeであること': '【部内戦モード】OrderSetupScreenおよびBunaiksenSetupScreenがクラッシュせずに正しく描画されること',
    'OperatorActionButtons viewer preview color matches viewer theme (BlueGrey/Purple)こと': '【OperatorActionButtons】観客プレビューの色が観客テーマ（BlueGrey/Purple）と一致すること',
    'OfficialRecordScreen Image share button uses LINE brand green colorであること': '【OfficialRecordScreen】画像共有ボタンにLINEブランドカラーのグリーンが使用されること',
    'Verify OrderSetupScreen renders ReorderableListView with drag handle iconsであること': '【OrderSetupScreen】ドラッグハンドル付きのReorderableListViewが正しく描画されること',
    'Verify BunaiksenHomeScreen renders 1-second quick match buttonであること': '【BunaiksenHomeScreen】1秒クイックマッチボタンが正しく描画されること',
    'Verify BunaiksenHomeScreen Quick Match Sheet Flow (Default 2min, Stepper +/- & 1-Ippon Format)こと': '【BunaiksenHomeScreen】クイックマッチシート（初期2分・増減ステッパー・一本勝負形式）が正常に機能すること',
    'Verify MatchEditSheet renders 3 tabs and handles individual match properlyであること': '【MatchEditSheet】3タブが描画され個人戦が適切に処理されること',
    'Verify MatchEditSheet Team-wide Bulk Edit Mode for Dantai Matchesであること': '【MatchEditSheet】団体戦の一括編集モードが正常に動作すること',
    'Verify My-Team (自チーム) Tracking & Alignment Preservation after Swapであること': '【自チーム追跡】紅白入替後の自チーム追跡と配置が正しく保持されること',
    'Verify Red/White Swap, Own-Team Tracking, Accordion Integrity & Rule Score Input Propagationであること': '【整合性検証】紅白入替・自チーム追跡・アコーディオン整合性・スコア入力伝播が正常に動作すること',
    'Verify MatchEditSheet unified court and round heading chips with clear and left alignmentであること': '【MatchEditSheet】コート・回戦の見出しチップが左揃えで明瞭に配置されること',
    'Design Regression Prevention: App-wide Dialog (16px) & BottomSheet (20px) Themeの検証が行えること': '【デザインリグレッション防止】全画面ダイアログ(16px)およびボトムシート(20px)のテーマ設定が検証できること',
    'Bunaiksen Player Select Category Filterの検証が行えること': '【部内戦選手選択】部門フィルター機能が検証できること',
    'Comprehensive Bunaiksen Player Category Filter Unit & Integration Verification (All Categories)こと': '【部内戦選手選択】全部門にわたる部門フィルター機能が統合検証できること',
    '[Widget] Design Regression Prevention & Bunaiksen Filter テスト': '[Widget] デザインリグレッション防止 ＆ 部内戦フィルター機能テスト',
    '[Widget] Platform Consistency & Zero Trust リグレッションテスト': '[Widget] プラットフォーム整合性 ＆ ゼロトラスト・リグレッションテスト',
    '[Widget] Dojo ID Display & Dark Mode リグレッションテスト': '[Widget] 道場ID表示 ＆ ダークモード・リグレッションテスト',
    '[Widget] Bulk Rule Edit & Category Rule Presets 統合テスト': '[Widget] 一括ルール編集 ＆ 部門別ルールプリセット統合テスト',
    '[Widget] Theme Integration & Color 検証': '[Widget] テーマ統合 ＆ カラー設定検証',
    '[Widget] Order Drag & Drop Reordering & Bunaiksen Quick Match テスト': '[Widget] オーダー並び替え ＆ 部内戦クイックマッチ機能テスト',
    '[Widget] UI Error リグレッションテスト: ListTile Material Assertion': '[Widget] UIエラー・リグレッションテスト: ListTile Material Assertion',
    '[Widget] Match Edit & Creation Flow Expansion 統合テスト': '[Widget] 試合編集・作成フロー拡張 統合テスト',
    '[Widget] MasterManagementScreen Welcome Flow テスト': '[Widget] マスタ管理画面 初期ウェルカムフローテスト',
}

def translate_title_smartly(t, fn):
    if t in EXACT_TRANSLATIONS:
        return EXACT_TRANSLATIONS[t]

    res = t
    res = re.sub(r'^Verify\s+', '', res, flags=re.I)
    res = re.sub(r'(?:であること|こと)$', '', res).strip()

    # ドメイン別定型変換
    res = re.sub(r'\bextractCourtNumber correctly resolves court indices\b', '【extractCourtNumber】コート番号インデックスが正しく解決される', res)
    res = re.sub(r'\bextractMatchOrder correctly resolves match order indices\b', '【extractMatchOrder】試合順インデックスが正しく解決される', res)
    res = re.sub(r'\bsortTeams by court orders teams by court number then match order\b', '【sortTeams】コート番号順、次いで試合順に正しくチームがソートされる', res)
    res = re.sub(r'\bsortTeams by matchOrder orders teams by match sequence\b', '【sortTeams】試合順序に基づいて正しくチームがソートされる', res)
    res = re.sub(r'\bsortTeams by status orders live matches first, then waiting, then finished\b', '【sortTeams】進行中・待機中・終了順に正しくチームがソートされる', res)
    res = re.sub(r'\bparse extracts last and first names correctly\b', '【parse】姓と名が正しく抽出される', res)
    res = re.sub(r'\bformatScoreboardTitle removes UUIDs and raw group IDs correctly\b', '【formatScoreboardTitle】UUIDおよび生グループIDが正しく除去される', res)
    res = re.sub(r'\btryClaimScorer fails when locked by different user and not expired\b', '他ユーザーによりロックされ期限内の場合、tryClaimScorerが失敗する', res)
    res = re.sub(r'\bautoProcessFusenIfNeeded triggers finish when both players are 欠員\b', '両選手が欠員の場合、autoProcessFusenIfNeededにより試合終了がトリガーされる', res)
    res = re.sub(r'\bCan be instantiated properly with Ref\b', 'Refを用いて正常にインスタンス化できる', res)
    res = re.sub(r'\baddSnapshotToMatch adds a snapshot to match with correct version and reason\b', 'addSnapshotToMatchにより正しいバージョンと理由でスナップショットが追加される', res)
    res = re.sub(r'\baddSnapshotToMatch caps snapshots at 1 item by default \(sliding window for light memory/DB footprint\)\b', 'addSnapshotToMatchでメモリ保護のためデフォルトで最大1件に制限される', res)
    res = re.sub(r'\bService can be instantiated\b', 'サービスが正常にインスタンス化できる', res)

    # 一般的な構文変換
    res = re.sub(r'\b([A-Za-z0-9_]+)\s+renders\s+correctly\s+with\s+(.+)$', r'【\1】\2で正しく描画される', res)
    res = re.sub(r'\b([A-Za-z0-9_]+)\s+renders\s+correctly\s+in\s+dark\s+and\s+light\s+modes$', r'【\1】ダーク・ライト両モードで正しく描画される', res)
    res = re.sub(r'\b([A-Za-z0-9_]+)\s+renders\s+correctly$', r'【\1】正しく描画される', res)
    res = re.sub(r'\b([A-Za-z0-9_]+)\s+renders\s+properly$', r'【\1】適切に描画される', res)
    res = re.sub(r'\b([A-Za-z0-9_]+)\s+renders\s+empty\s+state$', r'【\1】空状態（Empty State）が正しく描画される', res)
    res = re.sub(r'\b([A-Za-z0-9_]+)\s+renders\s+all\s+buttons$', r'【\1】全ボタンが正しく描画される', res)
    res = re.sub(r'\b([A-Za-z0-9_]+)\s+should\s+display\s+(.+)$', r'【\1】\2が表示される', res)
    res = re.sub(r'\b([A-Za-z0-9_]+)\s+should\s+render\s+(.+)$', r'【\1】\2が描画される', res)
    res = re.sub(r'\bShould\s+return\s+(.+)\s+when\s+(.+)$', r'【\2】\1が返却される', res, flags=re.I)
    res = re.sub(r'\bShould\s+return\s+(.+)$', r'\1が返却される', res, flags=re.I)
    res = re.sub(r'\bShould\s+NOT\s+show\s+(.+)\s+when\s+(.+)$', r'【\2】\1が表示されない', res, flags=re.I)
    res = re.sub(r'\bShould\s+NOT\s+show\s+(.+)$', r'\1が表示されない', res, flags=re.I)
    res = re.sub(r'\bShould\s+show\s+(.+)$', r'\1が表示される', res, flags=re.I)
    res = re.sub(r'\breturns\s+true\s+when\s+(.+)$', r'【\1】trueが返却される', res)
    res = re.sub(r'\breturns\s+false\s+when\s+(.+)$', r'【\1】falseが返却される', res)
    res = re.sub(r'\btriggers\s+(.+)\s+when\s+tapped$', r'タップ時に\1がトリガーされる', res)
    res = re.sub(r'\bhandles\s+(.+)\s+properly$', r'\1が適切に処理される', res)
    res = re.sub(r'\binitializes\s+with\s+(.+)$', r'\1で正しく初期化される', res)

    # 単語の置換
    res = re.sub(r'\bwithout crashes\b', 'クラッシュせずに', res)
    res = re.sub(r'\bwithout errors?\b', 'エラーなく', res)
    res = re.sub(r'\bin dark mode\b', 'ダークモードで', res)
    res = re.sub(r'\bin light mode\b', 'ライトモードで', res)
    res = re.sub(r'\bwhen tapped\b', 'タップ時に', res)
    res = re.sub(r'\bempty state\b', '空状態', res)

    if fn == 'group':
        res = re.sub(r'\bWidget Tests?\b', 'ウィジェットテスト', res, flags=re.I)
        res = re.sub(r'\bUnit Tests?\b', '単体テスト', res, flags=re.I)
        res = re.sub(r'\bIntegration Tests?\b', '統合テスト', res, flags=re.I)
        res = re.sub(r'\bRegression Tests?\b', 'リグレッションテスト', res, flags=re.I)
        res = re.sub(r'\bTests?\b', 'テスト', res, flags=re.I)
        res = re.sub(r'\bVerifications?\b', '検証', res, flags=re.I)
        if not re.search(r'(テスト|検証|保証|フロー|規約)$', res) and not res.endswith(']'):
            res = res + ' テスト'
        return res

    # 文末「こと」の保証
    if (res.endswith('れる') or res.endswith('ない') or res.endswith('する') or
        res.endswith('できる') or res.endswith('ある') or res.endswith('いる') or
        res.endswith('なる') or res.endswith('される')):
        res = res + 'こと'
    elif res.endswith('だ') or res.endswith('です'):
        res = res[:-1] + 'であること'
    elif re.search(r'[a-zA-Z0-9]$', res):
        res = res + 'であること'
    else:
        res = res + 'こと'

    # 二重語尾のクリーンアップ
    res = re.sub(r'(?:であること|こと)+$', '', res).strip()
    res = res + 'こと'
    return res

def apply_translations():
    with open('scratch_targets.json', 'r', encoding='utf-8') as f:
        targets = json.load(f)

    file_map = {}
    for item in targets:
        f = item['file']
        if f not in file_map:
            file_map[f] = []
        file_map[f].append((item['fn'], item['title']))

    total_changed = 0
    for filepath, items in file_map.items():
        if not os.path.exists(filepath):
            continue
        with open(filepath, 'r', encoding='utf-8') as fp:
            content = fp.read()

        new_content = content
        for fn, orig in items:
            translated = translate_title_smartly(orig, fn)
            if translated != orig:
                # 文字列リテラル内の完全一致を安全に置換
                # エスケープを考慮
                if orig in new_content:
                    new_content = new_content.replace(orig, translated, 1)
                    total_changed += 1

        if new_content != content:
            with open(filepath, 'w', encoding='utf-8') as fp:
                fp.write(new_content)

    print(f"✅ 完全日本語化の置換が完了しました: 合計 {total_changed} 箇所")

if __name__ == '__main__':
    apply_translations()
