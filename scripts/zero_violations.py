#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 第23条完全適合・最終ゼロ違反スクリプト
=====================================================
"""

import os

REPLACE_DICT = {
    # 連番4件
    '②連番排除において test配下のすべてのテストタイトルの先頭に連番やナンバリングが存在しないこと': 'テスト連番排除規約において test配下のすべてのテストタイトルの先頭に連番やナンバリングが存在しないこと',
    '④英文タイトル排除において 英文主体のテストタイトルが存在せず日本語に統一されていること': '英文タイトル排除規約において 英文主体のテストタイトルが存在せず日本語に統一されていること',
    '⑤種別タグにおいて 最上位groupが規約タグ(Unitに関して、, Widgetに関して、, Governanceに関して、, Goldenに関して、, E2Eに関して、, Securityに関して、)で始まっていること': 'テスト種別タグ規約において 最上位groupが規約タグ([Unit], [Widget], [Governance], [Golden], [E2E], [Security])で始まっていること',
    '1500.0, 1000.0において cacheExtent値が正しく計算できること': '画面サイズ1500.0および1000.0において cacheExtent値が正しく計算できること',

    # 英語構文41件
    'BunaiksenLeagueGridTable renders league table grid headersこと': '部内戦リーグ戦グリッドテーブルのヘッダーが正しく描画されること',
    'MatchRepresentativeModalBottomSheet renders properlyこと': '代表戦モーダルボトムシートが正しく描画されること',
    'MatchPlayerSelectionCard renders sub player correctlyこと': '選手選択カードに補員選手が正しく描画されること',
    'Renders tournament info correctlyこと': '大会情報が正しく描画されること',
    'buildMatchRule creates valid MatchRule instanceこと': '有効なMatchRuleインスタンスが正しく生成されること',
    'heading presets and triggers preset toggle and clearが正しく描画されること': '見出しプリセットが表示されトグルおよびクリアが正しく動作すること',
    'Renders markdown content correctlyこと': 'マークダウンコンテンツが正しく描画されること',
    'renders teamResultCell correctlyこと': 'チーム結果セルが正しく描画されること',
    'renders summaryCell correctlyこと': 'サマリーセルが正しく描画されること',
    'OfficialRecordLeagueGridTable renders league grid table correctlyこと': '公式記録リーグ対戦表が正しく描画されること',
    'ボタン一覧 and triggers callbacksが正しく描画されること': 'ボタン一覧が表示されコールバックが正しく動作すること',
    'Renders in dark mode correctlyこと': 'ダークモード環境で正しく描画されること',
    'CategoryRuleTeamSection renders daihyo settingsこと': '部門ルール団体戦セクションに代表戦設定が正しく描画されること',
    'getCategory returns formatted string correctlyこと': 'フォーマットされた部門文字列が正しく返却されること',
    'applyMatchRule updates fields properlyこと': 'ルール適用により各フィールドが正しく更新されること',
    'history list and triggers rewind callbackが正しく描画されること': '履歴リストが表示され巻き戻しコールバックが正しく動作すること',
    'Renders ManualQuickGuideTabView structure correctlyこと': 'マニュアルクイックガイドタブビューが正しく描画されること',
    'organization dropdown and triggers selectionが正しく描画されること': '道場組織ドロップダウンが表示され選択が正しく動作すること',
    'renders BunaiksenQuickMatchPlayerSelectSection correctlyこと': '部内戦クイックマッチ選手選択セクションが正しく描画されること',
    'renders BunaiksenQuickMatchRuleSection correctlyこと': '部内戦クイックマッチルールセクションが正しく描画されること',
    '部門 name and triggers onShowRuleDetail on tapが正しく描画されること': '部門名が表示されタップ時にルール詳細コールバックが正しく実行されること',
    'Renders Kachinuki Matchこと': '勝ち抜き試合画面が正しく描画されること',
    'OrderSetupLeagueParticipantsSection renders league participants listこと': 'オーダー設定リーグ参加者リストが正しく描画されること',
    'ReorderableListView widget integration: onReorderItem updates comment order between matchesこと': '並び替えリスト操作により試合間コメント順序が正しく更新されること',
    'BunaiksenMatchListHeaderBar renders properlyこと': '部内戦試合リストヘッダーバーが正しく描画されること',
    'BunaiksenMatchCard renders match detailsこと': '部内戦試合カードに試合詳細が正しく描画されること',
    'RenseikaiAddNextMatchBottomSheet renders properlyこと': '錬成会次試合追加ボトムシートが正しく描画されること',
    'TeamScoreboardTableBuilder calcPts parses points correctlyこと': 'チームスコアボードの勝ち点計算が正しくパースされること',
    'Renders player details correctlyこと': '選手詳細が正しく描画されること',
    'events and triggers onUndo callbackが正しく描画されること': 'イベント一覧が表示されUndoコールバックが正しく実行されること',
    'TimelineRenameTeamSheet renders properlyこと': 'タイムラインチーム名変更シートが正しく描画されること',
    'TimelineInnerCommentWidget renders text properlyこと': 'タイムライン内部コメントが正しく描画されること',
    'cards and triggers change callbacksが正しく描画されること': 'カード群が表示され変更コールバックが正しく実行されること',
    'ViewerQuickActionButtons renders buttons correctlyこと': '観客用クイックアクションボタンが正しく描画されること',
    'TeamRegistrationOrderStep renders properlyこと': 'チーム登録オーダー設定ステップが正しく描画されること',
    'formatCategoryName formats categories correctlyこと': '部門名が正しくフォーマットされること',
    'parseCategoryToState parses saved category strings correctlyこと': '保存済み部門文字列が状態へ正しくパースされること',
    'HoldConfirmButton displays circular indicator on long pressこと': '長押し確定ボタンの長押し時にインジケーターが表示されること',
    'HoldConfirmButton triggers onConfirm after full durationこと': '長押し確定ボタンの規定時間長押し完了時に確定処理が実行されること',
    'CategoryRuleEditorView renders properlyこと': '部門ルールエディタービューが正しく描画されること',
    'コート and round preset チップ一覧 and triggers selectionが正しく描画されること': 'コートおよび回戦プリセットチップが表示され選択が正しく動作すること',
}

def main():
    total_files = 0
    total_replaces = 0
    for root, _, files in os.walk('test'):
        for file in files:
            if file.endswith('_test.dart'):
                p = os.path.join(root, file)
                with open(p, 'r', encoding='utf-8', errors='ignore') as f:
                    content = f.read()

                new_content = content
                file_replaces = 0
                for target, repl in REPLACE_DICT.items():
                    if target in new_content:
                        new_content = new_content.replace(target, repl)
                        file_replaces += 1

                if file_replaces > 0:
                    total_files += 1
                    total_replaces += file_replaces
                    with open(p, 'w', encoding='utf-8') as f:
                        f.write(new_content)

    print(f"ゼロ違反達成完了: {total_files} ファイル / {total_replaces} 箇所修正")

if __name__ == '__main__':
    main()
