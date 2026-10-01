#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - タイトル最終完璧ポリッシュスクリプト (Final Polish Titles)
========================================================================
残存する以下の全項目を確実に置換・解決し、0件にします。
"""

import os
import re

POLISH_MAP = {
    # 閉じ括弧残存
    '[Governance] 120Hz ProMotion ディスプレイ完全同期】ガバナンステスト': '[Governance] 120Hz ProMotion ディスプレイ完全同期ガバナンステスト',
    '[Governance] 通信パケット・同期ペイロード極小化】Gzip 圧縮・解凍ガバナンステスト': '[Governance] 通信パケット・同期ペイロード極小化 Gzip 圧縮・解凍ガバナンステスト',
    '[Governance] アダプティブ省電力・サーマル冷却】ガバナンステスト': '[Governance] アダプティブ省電力・サーマル冷却ガバナンステスト',
    '[Governance] Dart AOT コンパイル関数インライン化】マイクロベンチマーク＆整合性テスト': '[Governance] Dart AOT コンパイル関数インライン化マイクロベンチマーク＆整合性テスト',
    '[Governance] Isar メモリマップトI/O（MMAP）＆ ページサイズ最適化】ガバナンステスト': '[Governance] Isar メモリマップトIOおよびページサイズ最適化ガバナンステスト',

    # 残存英文タイトル
    'tryClaimScorer succeeds when claimed by same userこと': '同一ユーザーによる記録係権限の再取得が成功すること',
    'tryClaimScorer succeeds when previous lock is expiredこと': '過去のロックが期限切れの場合に記録係権限の取得に成功すること',
    'Event Signature (改ざん防止署名)': 'イベント改ざん防止署名が正しく機能すること',
    'Identifies advanced matches correctlyこと': '進行中の試合を正しく特定できること',
    'Identifies advanced matches with custom keywords correctlyこと': 'カスタムキーワードによる進行中試合の特定が正しく行えること',
    'Hides registration button when isReadOnly is trueこと': '読み取り専用モード時は登録ボタンが非表示になること',
    'Hides buttons when flags are falseこと': 'フラグが無効な場合は各ボタンが非表示になること',
    'ViewerBunaiksenMatchCard.buildScoreMarks handles zero scoresこと': '部内戦カードのスコア表示においてゼロ得点が正常に処理されること',
    'position slot with 選手 name, change ボタン, and handles vacantが正しく描画されること': '選手名・変更ボタン・空枠スロットが正しく描画されること',
    'LiquidBackgroundにおいて static layout when Eco Mode is activeが描画されること': '省電力モード有効時に静的レイアウトが描画されること',
    'LiquidBackgroundにおいて animated layout with blur when Eco Mode is inactiveが描画されること': '省電力モード無効時にブラー付きアニメーションレイアウトが描画されること',
    'ProgramViewerMediaCache handles placeholder image sizesこと': 'プログラム表示メディアキャッシュがプレースホルダー画像サイズを正しく処理すること',
    'ProgramViewerMediaCache handles empty URLこと': 'プログラム表示メディアキャッシュが空URLを正しく処理すること',
    'buildContentWidgets generates fallback when list is emptyこと': 'リストが空のときにフォールバックウィジェットが生成されること',
    'HoldConfirmButton does not trigger when disabledこと': '非活性時に長押し確定ボタンがトリガーされないこと',
    'selectable 選手 カード and handles tapが正しく描画されること': '選択可能な選手カードが描画されタップが正常に処理されること',
    'shows error state when hasError is trueこと': 'エラー発生時にエラー状態が表示されること',
    'league points テキスト fields and handles inputが正しく描画されること': 'リーグ勝ち点テキストフィールドが描画され入力が正常に処理されること',
    'responds to double tap when confirmBehavior is doubleこと': '確認動作がダブルタップ設定時にダブルタップへ応答すること',
    'Disables restore button when isViewOnly is trueこと': '閲覧専用モード時は復元ボタンが無効化されること',
    'shows approved text when isApproved is trueこと': '承認済み状態のテキストが正しく表示されること',
    'default 3 scene ルール cards and handles selectionが正しく描画されること': 'デフォルト3つのシーンルールカードが描画され選択が正常に処理されること',
    'healRepresentativeMatch heals corrupted or finished state when events emptyこと': 'イベントが空の場合に代表戦の破損または終了状態が修復されること',
    'groupPlayers groups by gradeName when mode is 0こと': 'モードが0のときに学年名で選手が正しくグループ分けされること',
    'groupPlayers groups by category when mode is 1こと': 'モードが1のときに部門別で選手が正しくグループ分けされること',
    'all 3 export ボタン一覧 and handles callbacksが正しく描画されること': '3つのエクスポートボタン一覧が描画されコールバックが正しく動作すること',
    'Disables buttons when isExporting is trueこと': 'エクスポート実行中は各ボタンが無効化されること',
    'Hides toggle when hasMultipleCategories is falseこと': '複数部門が存在しない場合はトグルが非表示になること',
    'BunaiksenQuickMatchSheet 正しく描画されること and handles interactionこと': '部内戦クイックマッチシートが正しく描画され操作が処理できること',
    'deleteMatch on Web does NOT overwrite active currentDojoIdProvider when match has default_orgこと': 'Web環境での試合削除時にアクティブな道場IDが上書きされないこと',
    'Renseikai candidate player chips filter by match category when same team name exists across categoriesこと': '同名チームが複数部門に存在する場合でも部門別に候補選手チップが正しく絞り込まれること',
    'Bunaiksen calendar picker does not crash when initialDate (viewDate) is not in selectableDayPredicateこと': '部内戦カレンダーピッカーで初期日付が選択可能範囲外でもクラッシュしないこと',
    'Checklist is completely hidden when matches existこと': '試合が存在する場合はチェックリストが完全に非表示になること',
    'CategoryRulesScreen skip button navigates to home when isFromSetup=trueこと': 'セットアップ経由の場合に部門ルール画面のスキップボタンでホームに遷移すること',
    'CategoryRulesScreen does NOT show setup UI elements when isFromSetup=falseこと': '通常表示時に部門ルール画面のセットアップ用UI要素が表示されないこと',
    'Highlights red team when isRedOwn is trueこと': '自チームが赤の場合に赤チームがハイライト表示されること',
    'Highlights white team when isWhiteOwn is trueこと': '自チームが白の場合に白チームがハイライト表示されること',

    # ルール連番・E2E連番の日本語化
    'Native Rule 1: アプリ内ブラウザ（inAppWebView / platformDefault）を厳格に禁止し、必ず LaunchMode.externalApplication が指定されること': 'ネイティブ環境でアプリ内ブラウザ（inAppWebView / platformDefault）を厳格に禁止し、必ず LaunchMode.externalApplication が指定されること',
    'Native Rule 2: バンドID形式（https://band.us/band/12345）は直接ネイティブスキーム bandapp://band/12345 へ自動変換されること': 'ネイティブ環境でバンドID形式（https://band.us/band/12345）は直接スキーム bandapp://band/12345 へ自動変換されること',
    'Native Rule 3: 空URLまたはband.usトップはデフォルトで bandapp:// へ自動変換されること': 'ネイティブ環境で空URLまたはband.usトップはデフォルトで bandapp:// へ自動変換されること',
    'Web Rule 1: トップURLやバンドID形式は安全に bandapp:// スキームへ変換され、招待URL等はUniversal Linkとして保持されること': 'Web環境でトップURLやバンドID形式は安全に bandapp:// スキームへ変換され、招待URL等はUniversal Linkとして保持されること',
    'Web Rule 2: Web環境では window.open をバイパスし、同一ウィンドウ直接キック（launchWebDirect）が最優先実行されること': 'Web環境では window.open をバイパスし、同一ウィンドウ直接キック（launchWebDirect）が最優先実行されること',
    'Web Rule 3: Webフォールバック時でも webOnlyWindowName: _self かつ LaunchMode.externalApplication が厳格に渡されること': 'Web環境のフォールバック時でも webOnlyWindowName: _self かつ LaunchMode.externalApplication が厳格に渡されること',
    'E2E-3: 同一IDのコマンドが短時間に複数回投入されても、完全べき等性により重複実行が防止されること': '同一IDのコマンドが短時間に複数回投入されても、完全べき等性により重複実行が防止されること',
    'ヒント色検証として 3. ライト/ダークで onSurface の色が異なること': 'ヒント色検証としてライトおよびダークで onSurface の色が異なること',
    '[Unit] Unitにおいて 相互同時反則・2-2サドンデス突入＆合議Undo完全復元テスト': '[Unit] 相互同時反則・2-2サドンデス突入＆合議Undo完全復元テスト',
    'Rule 6: 完全べき等キューイングに関して、 match_command_queue.dart に重複UUIDコマンド排除配備規約こと': '完全べき等キューイングにおいて match_command_queue.dart に重複UUIDコマンド排除配備規約が遵守されていること',

    # 不自然な文末
    'ライトモード: 入力文字色が onSurface（ほぼ黒）こと': 'ライトモードで入力文字色がほぼ黒となること',
    'ダークモード: 入力文字色が onSurface（ほぼ白）こと': 'ダークモードで入力文字色がほぼ白となること',
    'ライトモード: 背景色が indigo.shade50（薄紫）こと': 'ライトモードで背景色が薄紫となること',
    'ダークモード: 背景色が C1C2E（暗い紺色）こと': 'ダークモードで背景色が暗い紺色となること',
    'ライトモード: タイルの tileColor は null（テーマ依存）こと': 'ライトモードでタイルの背景色がテーマ依存となること',
    'ダークモード: タイルの tileColor が C1C1E（暗色）こと': 'ダークモードでタイルの背景色が暗色となること',
    'ダークモード: 選択ハイライトが indigo.shade900（半透明）こと': 'ダークモードで選択ハイライトが半透明となること',
    'SettingsModel のデフォルトで sleepPrevent が true（消灯防止有効）こと': '設定モデルの初期値で画面消灯防止が有効となること',
    '時間切れかつ同点の場合、延長戦に突入すべきと判定されること': '時間切れかつ同点の場合、延長戦突入と判定されること',
    '一般ユーザー画面において、隠蔽すべき特権操作ボタンやメニューが一切露出していないこと': '一般ユーザー画面において、特権操作ボタンやメニューが一切露出していないこと',
    '複数ページPDFでも1ページ目のときはボタンが非活性（onPressed: null）こと': '複数ページPDFでも1ページ目表示時はボタンが非活性となること',
    '複数ページPDFでも1ページ目表示時はボタンが非活性（onPressed == null）こと': '複数ページPDFでも1ページ目表示時はボタンが非活性となること',
    'ダークモード時にスコアカードの背景がダーク系(cardBackground)こと': 'ダークモード時にスコアカードの背景がダーク系色となること',
    '全カテゴリ一括出力トグル ON 状態 (全カテゴリ一括出力モード: PDF（全）/ 画像（全）/ CSV（全）)こと': '全カテゴリ一括出力トグルがONのときに各全出力モードが正しく反映されること',
    '初期状態では通常モード（100ms・高精度レスポンス）こと': '初期状態では高精度レスポンスの通常モードが適用されること',
}

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()

    new_content = content
    count = 0
    for target, repl in POLISH_MAP.items():
        if target in new_content:
            new_content = new_content.replace(target, repl)
            count += 1

    return new_content, count

def main():
    total_files = 0
    total_count = 0
    for root, _, files in os.walk('test'):
        for file in files:
            if file.endswith('_test.dart'):
                p = os.path.join(root, file)
                new_content, c = process_file(p)
                if c > 0:
                    total_files += 1
                    total_count += c
                    with open(p, 'w', encoding='utf-8') as f:
                        f.write(new_content)

    print(f"✨ 最終ポリッシュ完了: {total_files} ファイル / {total_count} 箇所修正")

if __name__ == '__main__':
    main()
