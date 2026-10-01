#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 第23条完全適合・連番＆英文全件置換スクリプト
===========================================================
"""

import os
import re

REPLACE_MAP = {
    # 連番8件の解消
    '0-0 終了済みにおいて draw mark × correctlyが正しく描画されること': 'スコア0-0の終了済みにおいて引き分けマーク（×）が正しく描画されること',
    '1-1引き分け vs 0-0引き分けの本数差において 1-1ドローは総本数に双方+1加算、0-0ドローは総本数+0加算として正確に計算されること': '引き分け本数差の検証において、1-1ドローは総本数に双方+1加算、0-0ドローは総本数+0加算として正確に計算されること',
    '0の状態で赤が途中棄権 白に不戦勝2本が付与され、スコア白2-赤0で白の勝ちとなること': 'スコア0の状態で赤が途中棄権したとき白に不戦勝2本が付与され、スコア白2-赤0で白の勝ちとなること',
    '①装飾絵文字排除において test配下のすべてのテストおよびグループ名に装飾絵文字が含まれていないこと': '装飾絵文字排除規約において test配下のすべてのテストおよびグループ名に装飾絵文字が含まれていないこと',
    '②テスト連番排除において testおよびtestWidgetsの先頭に連番やナンバリングが存在しないこと': 'テスト連番排除規約において testおよびtestWidgetsの先頭に連番やナンバリングが存在しないこと',
    '③文末統一＆文法規約において 末尾が「こと」で終わり、「〜べき」や二重語尾が存在しないこと': '文末統一＆文法規約において 末尾が「こと」で終わり、「〜べき」や二重語尾が存在しないこと',
    '④英語混在・英文タイトル排除において 英文構文（renders/verify/displays等）を含まない日本語タイトルであること': '英語混在・英文タイトル排除規約において 英文構文（renders/verify/displays等）を含まない日本語タイトルであること',
    '⑤テスト種別タグ規約において 最上位groupに許可されたテスト種別タグが付与されていること': 'テスト種別タグ規約において 最上位groupに許可されたテスト種別タグが付与されていること',

    # 英語構文85件の日本語化
    'BunaiksenRuleSettingsCard renders expansion tileこと': '部内戦ルール設定カードのExpansionTileが正しく描画されること',
    'BunaiksenLeagueGridTable renders league table gridこと': '部内戦リーグ戦グリッドテーブルが正しく描画されること',
    'renders MatchTimerSection correctlyこと': '試合タイマーセクションが正しく描画されること',
    'MatchActionCard renders action items properlyこと': '試合アクションカードのアクション項目が正しく描画されること',
    'OrderSetupPositionSlot renders slot with player name and change buttonこと': 'オーダー設定位置スロットに選手名と変更ボタンが正しく描画されること',
    'BunaiksenQuickMatchSheet renders tournament and match selectorsこと': '部内戦クイックマッチシートの大会および試合セレクターが正しく描画されること',
    'MatchPlayerNameEditBottomSheet displays title and buttons properlyこと': '選手名編集ボトムシートのタイトルとボタン群が正しく描画されること',
    'TimelineTieBreakDialog displays title, reason and options properlyこと': 'タイブレークダイアログのタイトル・理由・選択肢が正しく描画されること',
    'OrderSetupHeaderBar displays title, counter and back buttonこと': 'オーダー設定ヘッダーバーのタイトル・カウンター・戻るボタンが正しく描画されること',
    'renders MatchStatusIndicator correctlyこと': '試合ステータスインジケーターが正しく描画されること',
    'displays match type chips and select updates stateこと': '試合形式チップが表示され選択時に状態が正しく更新されること',
    'ScoreInputPad displays 10 buttons with correct labelsこと': 'スコア入力パッドに10個のボタンが正しいラベルで描画されること',
    'ScoreInputPad tap triggers onScoreSelected with correct ScoreTypeこと': 'スコア入力パッドのタップ時に正しいScoreTypeでコールバックが実行されること',
    'MatchFormatStickyBottomAction renders page 0 correctlyこと': '試合形式ボトムアクションの最初のページが正しく描画されること',
    'MatchFormatStickyBottomAction renders last page correctlyこと': '試合形式ボトムアクションの最終ページが正しく描画されること',
    'MatchContentLayoutBuilder renders portrait layoutこと': '縦画面レイアウトが正しく描画されること',
    'MasterPlayerEditBottomSheet displays player registration fieldsこと': '選手編集ボトムシートに選手登録フィールド群が正しく描画されること',
    'CategoryRuleIndividualSection renders extension settingsこと': '部門ルール個別セクションの延長設定が正しく描画されること',
    'renders CreateTournamentDynamicHeader correctlyこと': '大会作成ダイナミックヘッダーが正しく描画されること',
    'renders CreateTournamentPage1 correctlyこと': '大会作成第1ページが正しく描画されること',
    'renders CreateTournamentPage2 correctlyこと': '大会作成第2ページが正しく描画されること',
    'renders CreateTournamentStickyBottomAction correctlyこと': '大会作成ボトムアクションが正しく描画されること',
    'AutoKanaHelper updates kana on name changeこと': '氏名変更時にフリガナが自動更新されること',
    'OrderSetupStickyBottomBar renders properlyこと': 'オーダー設定ボトムバーが正しく描画されること',
    'OrderSetupReorderableSlotsView renders slotsこと': 'オーダー設定の並び替え可能スロットが正しく描画されること',
    'parseCategoryToState parses correctlyこと': '部門文字列から状態へのパースが正しく行えること',
    'TimelineUnifiedAnnounceDialog renders properlyこと': 'タイムライン統合アナウンスダイアログが正しく描画されること',
    'isAdvancedMatchName returns false if useAdvancedRule is disabledこと': '詳細ルール無効時は詳細試合名判定がfalseを返すこと',
    'getRuleForScene returns normalRule if useAdvancedRule is falseこと': '詳細ルール無効時は通常ルールが返却されること',
    'getRuleForScene returns correct MatchRuleこと': 'シーンに応じた正しいMatchRuleが返却されること',
    'MatchPlayerNameEditBottomSheet renders properlyこと': '選手名編集ボトムシートが正しく描画されること',
    'Renders position player tile correctlyこと': 'ポジション選手タイルが正しく描画されること',
    'MatchFormatCategoryPreviewCard renders category textこと': '部門プレビューカードに部門テキストが正しく描画されること',
    'Renders simple strike mark correctlyこと': 'シンプルな打突マークが正しく描画されること',
    'buildTeamCell renders team name correctlyこと': 'チームセルにチーム名が正しく描画されること',
    'Verify proper grouping/accordion display in ViewerHomeScreenこと': '観客ホーム画面で適切なグループ分けおよびアコーディオン表示が行われること',
    'Renders team names correctlyこと': 'チーム名が正しく描画されること',
    'OfficialRecordScoreTableBuilder renders score tableこと': '公式記録スコアテーブルが正しく描画されること',
    'OfficialRecordLeagueSection renders league titleこと': '公式記録リーグセクションにリーグタイトルが正しく描画されること',
    'ViewerOfficialIndividualListCard renders individual match item properlyこと': '観客用個人戦リストカードの試合項目が正しく描画されること',
    'BunaiksenRecordActionBar renders action buttonsこと': '部内戦記録アクションバーのアクションボタンが正しく描画されること',
    'BunaiksenTeamScoreTable renders matchup properlyこと': '部内戦チームスコアテーブルの対戦表が正しく描画されること',
    'Renders standard rules chipsこと': '標準ルールチップが正しく描画されること',
    'Long press triggers onLongPress callback in normal modeこと': '通常モード時の長押しでコールバックが正常に発火すること',
    'TimelineTieBreakDialog renders properlyこと': 'タイブレークダイアログが正しく描画されること',
    'Renders simple vertical text charactersこと': '縦書き文字が正しく描画されること',
    'MatchFormatRuleSummaryCard renders match rule detailsこと': '試合ルール概要カードに詳細が正しく描画されること',
    'ExpeditionStrikeStatRow renders strike badges correctlyこと': '遠征打突統計行に打突バッジが正しく描画されること',
    'renders match result cell correctlyこと': '試合結果セルが正しく描画されること',
    'OfficialRecordIndividualMatchesList renders individual matches list correctlyこと': '公式記録個人戦リストが正しく描画されること',
    'TimelineSummaryInputDialog renders properlyこと': 'タイムラインサマリー入力ダイアログが正しく描画されること',
    'executeRewind returns initialMatch if targetVersion >= validEvents.lengthこと': '対象バージョンが有効イベント数以上のときは初期試合状態が返却されること',
    'SettingsScreen displays text size selectorこと': '設定画面に文字サイズ選択セレクターが表示されること',
    'bulkUpdateMatchRules command updates specific matches rules in Firestoreこと': 'Firestore内で特定試合のルールが一括更新されること',
    'returns correct timeline propertiesこと': 'タイムラインのプロパティが正しく返却されること',
    'Should NOT show dialog if notifyOnEmergency settings is disabledこと': '緊急時通知が無効設定の場合はダイアログが表示されないこと',
    'Staff target announcement: Should show in staff room, but skip in non-staff roomこと': 'スタッフ向けアナウンスは係員室で表示され一般室ではスキップされること',
    'matchCommandProvider.deleteMatch on Web preserves currentDojoIdProviderこと': 'Web環境での試合削除時にアクティブな道場IDが保持されること',
    'Moving a player to the last position preserves other ordersこと': '選手を末尾に移動した際に他の選手の順序が正常に維持されること',
    'Verify that KendoRuleEngine does not evaluate an in-progress infinite kachinuki match as a tieこと': '進行中の勝ち抜き試合が引き分けとして判定されないことが検証できること',
    'Verify queue restoration on return to list / break after win or drawこと': '勝敗または引き分け後のリスト復帰時に待機キューが正常に復元されること',
    'Tapping confirm button in auto-finished Infinite Kachinuki match triggers next match setup dialogこと': '自動終了した勝ち抜き試合の確定ボタンタップ時に次試合設定ダイアログが表示されること',
    'Displays matches in correct kendo position order (先鋒 -> 中堅 -> 大将) even if input is scrambledこと': '入力順序が乱れている場合でも剣道の正しいポジション順で試合が表示されること',
    'icon and label, triggers onTap callbackが正しく描画されること': 'アイコンとラベルが表示されタップ時にコールバックが正常に実行されること',
    'all 4 ボタン一覧 and triggers callbacksが正しく描画されること': '全4ボタン一覧が表示されコールバックが正常に実行されること',
    'available 選手一覧 list and select returns 選手 nameが正しく描画されること': '選択可能な選手一覧が表示され選手名が正常に返却されること',
    'filters, units and triggers callbacksが正しく描画されること': 'フィルターとユニットが表示されコールバックが正常に実行されること',
    'MatchInfiniteNextDialog and triggers actionsが正しく描画されること': '次試合ダイアログが表示されアクションが正常に実行されること',
    'positions and members correctly and triggers clear on tapが正しく描画されること': 'ポジションとメンバーが正しく描画されタップ時にクリアが正常に実行されること',
    '部門 チップ一覧 with subtitle and resolves (2)が正しく描画されること': '部門チップ一覧がサブタイトルとともに正しく描画されること',
    'tool ボタン and triggers onTapが正しく描画されること': 'ツールボタンが表示されタップ時にコールバックが正常に実行されること',
    'pen option ボタン and triggers onTapが正しく描画されること': 'ペンオプションボタンが表示されタップ時にコールバックが正常に実行されること',
    'all ボタン一覧 and triggers callbacks accuratelyが正しく描画されること': '全ボタン一覧が表示されコールバックが正確に実行されること',
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
                for target, repl in REPLACE_MAP.items():
                    if target in new_content:
                        new_content = new_content.replace(target, repl)
                        file_replaces += 1

                if file_replaces > 0:
                    total_files += 1
                    total_replaces += file_replaces
                    with open(p, 'w', encoding='utf-8') as f:
                        f.write(new_content)

    print(f"✨ 英語構文＆連番置換完了: {total_files} ファイル / {total_replaces} 箇所修正")

if __name__ == '__main__':
    main()
