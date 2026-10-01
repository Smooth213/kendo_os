#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 残存116件の完全職人ローカライズ実行スクリプト
"""

import json
import os

MAPPING_116 = {
    'resolvePath correctly rewrites legacy and shorthand pathsこと': '【resolvePath】レガシーパスおよび省略形パスが正しく書き換えられること',
    'BunaiksenSetupScreen renders properly with all tabsこと': '【BunaiksenSetupScreen】全タブとともに適切に描画されること',
    'CategoryRuleFormSection renders タイトル and time stepperこと': '【CategoryRuleFormSection】タイトルおよび時間ステッパーが描画されること',
    'ProgramViewerDrawingToolbar renders tools and handles callbacksこと': '【ProgramViewerDrawingToolbar】各種ツールが描画されコールバックが処理されること',
    'ProgramViewerDrawingToolbar hides shared pen options when canUseSharedPen is false (観客 Mode)こと': '【ProgramViewerDrawingToolbar】観客モード時に共有ペン設定が秘匿されること',
    'ProgramViewerDrawingToolbar shows shared pen options when canUseSharedPen is true (記録係 Mode)こと': '【ProgramViewerDrawingToolbar】記録係モード時に共有ペン設定が表示されること',
    'TeamRegistrationCategoryStep renders 部門一覧, チップ一覧 and handles selectionこと': '【TeamRegistrationCategoryStep】部門一覧およびチップが表示され選択が処理されること',
    'ViewerCategorySectionList renders 部門一覧 and teamsこと': '【ViewerCategorySectionList】部門一覧およびチーム一覧が正しく描画されること',
    'MatchPlayerRosterListSection displays active and sub playersこと': '【MatchPlayerRosterListSection】出場選手および補欠選手が正しく表示されること',
    'TeamRegistrationStickyBottomBar renders properly on page 0こと': '【TeamRegistrationStickyBottomBar】ページ0で適切に描画されること',
    'TeamRegistrationStickyBottomBar renders properly on page 2 (inputting)こと': '【TeamRegistrationStickyBottomBar】ページ2（入力中）で適切に描画されること',
    'TeamRegistrationStickyBottomBar renders properly on page 2 (not inputting)こと': '【TeamRegistrationStickyBottomBar】ページ2（未入力）で適切に描画されること',
    '[Widget] 選手 Candidate 統合テスト under Any Dojo Name テスト': '[Widget] 選手候補選択 統合テスト',
    'ViewerGroupMatchCard renders group タイトル and 試合 listこと': '【ViewerGroupMatchCard】グループタイトルおよび試合一覧が正しく描画されること',
    'OrderSetupPlayerSelectBottomSheet renders options and playersこと': '【OrderSetupPlayerSelectBottomSheet】選択肢および選手一覧が描画されること',
    'isAdvancedMatchName correctly detects finals and semi-finalsこと': '【isAdvancedMatchName】決勝・準決勝が正しく検知されること',
    'UI Layer - setup_match_format_screen renders detailed representative settings under league modeこと': '【setup_match_format_screen】リーグ戦モードで詳細な代表戦設定が描画されること',
    'RenseikaiPlayerInputField renders choices and fieldこと': '【RenseikaiPlayerInputField】選択肢および入力欄が正しく描画されること',
    'OrderSetupMatchupConfigSection renders red/white options and opponent inputこと': '【OrderSetupMatchupConfigSection】紅白オプションおよび対戦相手入力欄が描画されること',
    'MatchViewOnlyNoticeBanner renders warning and switch buttonこと': '【MatchViewOnlyNoticeBanner】警告バナーおよび切替ボタンが描画されること',
    'MatchDaihyoOverlay renders ボタン and calls callbackこと': '【MatchDaihyoOverlay】ボタンが描画されコールバックが呼び出されること',
    'mergeAndRebuildAsync executes in worker and returns properly merged matchこと': '【mergeAndRebuildAsync】Worker内で実行され正しくマージされた試合情報が返却されること',
    'TeamRegistrationAppBar renders back ボタン and manual buttonこと': '【TeamRegistrationAppBar】戻るボタンおよびマニュアルボタンが描画されること',
    'TeamRegistrationDynamicHeader renders ヘッダー タイトル and progressこと': '【TeamRegistrationDynamicHeader】ヘッダータイトルおよび進行状況が描画されること',
    'TeamRegistrationAutocompleteField renders テキスト field with suggestionsこと': '【TeamRegistrationAutocompleteField】サジェスト付き入力欄が描画されること',
    'omits (2) when subtitle makes it distinguishable, but keeps (2) when duplicatedこと': 'サブタイトルで区別可能な場合は(2)が省略され、重複時は(2)が保持されること',
    'ViewerHomeScreen displays current status and correctly renders elementsこと': '【ViewerHomeScreen】現在のステータスが表示され各要素が正しく描画されること',
    'ViewerOfficialRecordScreen renders ヘッダー and export buttonsこと': '【ViewerOfficialRecordScreen】ヘッダーおよびエクスポートボタンが正しく描画されること',
    'ViewerMatchScreen fallback renders UI when projection is loadingこと': '【ViewerMatchScreen】投影データ読み込み中にフォールバックUIが正しく描画されること',
    'ViewerMatchListTileCard correctly navigates to Scoreboard when "スコア" ボタン is tappedこと': '【ViewerMatchListTileCard】「スコア」ボタンタップ時にスコアボードへ正しく遷移すること',
    'ViewerTeamScoreboardScreen resolves groupName or matchId to tournamentId エラーなくこと': '【ViewerTeamScoreboardScreen】groupNameまたはmatchIdからtournamentIdがエラーなく解決されること',
    'generateMatches creates valid 試合一覧 for individual matchこと': '【generateMatches】個人戦の有効な試合一覧が正しく生成されること',
    'CategoryRuleEditorBottomBar renders ボタン一覧 and triggers tapこと': '【CategoryRuleEditorBottomBar】各種ボタンが描画されタップが正常に動作すること',
    'onReorderTimeline correctly calculates newOrder when moving comment between matchesこと': '【onReorderTimeline】試合間でコメント移動時にnewOrderが正しく計算されること',
    'onReorderTimeline correctly calculates newOrder when moving comment to top or bottomこと': '【onReorderTimeline】最上部または最下部へコメント移動時にnewOrderが正しく計算されること',
    'onReorderTimeline correctly moves 試合 group downward and upwardこと': '【onReorderTimeline】試合グループを上下へ正しく移動できること',
    'onReorderInnerTimeline correctly handles inner 試合一覧 and comments reorderingこと': '【onReorderInnerTimeline】内部の試合一覧およびコメントの並び替えが適切に処理されること',
    'Scoreboard does not show Draw/Tie badge when the 試合 is 進行中, but shows it when 終了済み as a tieこと': '【スコアボード】試合進行中は引分バッジが表示されず、引分終了時に正しく表示されること',
    'representative 試合 (代表戦) OFF is correctly saved and restored without automatically turning ONこと': '【代表戦】代表戦OFF設定が自動でONにならず正しく保存・復元されること',
    'representative 試合 (代表戦) ON is correctly saved and restoredこと': '【代表戦】代表戦ON設定が正しく保存・復元されること',
    'CategoryRuleChips shows extension badge for individual 試合 when enchoCount > 0こと': '【CategoryRuleChips】延長回数>0の個人戦で延長バッジが表示されること',
    'ViewerGroupMatchScoreSummary renders チーム names and scoreこと': '【ViewerGroupMatchScoreSummary】チーム名およびスコアが正しく描画されること',
    'TimelineGroupScoreSummary calculates wins and renders teamsこと': '【TimelineGroupScoreSummary】勝数が計算されチーム情報が描画されること',
    'OrderSetupBaseOrderActionsBar triggers save and load callbacksこと': '【OrderSetupBaseOrderActionsBar】保存および読込のコールバックが正常に動作すること',
    'MasterTeamNameManagementSheet displays チーム names and input fieldこと': '【MasterTeamNameManagementSheet】チーム名一覧および入力フィールドが表示されること',
    'CategoryRuleEditorHeaderCard renders 部門 and switchesこと': '【CategoryRuleEditorHeaderCard】部門情報およびスイッチが正しく描画されること',
    'CategoryRuleEditorHeaderCard previews タイトル with (2) omitted when distinctこと': '【CategoryRuleEditorHeaderCard】識別可能な場合に(2)を省略してタイトルプレビューが表示されること',
    'TimelineTeamCard renders ヘッダー and matchesこと': '【TimelineTeamCard】ヘッダーおよび試合情報が正しく描画されること',
    'OfficialRecordExpeditionSummaryCard renders properly with matchesこと': '【OfficialRecordExpeditionSummaryCard】試合情報とともに適切に描画されること',
    'MatchHeaderTitle renders matchType and namesこと': '【MatchHeaderTitle】試合形式および選手名が正しく描画されること',
    'MasterPlayerEditBottomSheet displays edit mode with existing playerこと': '【MasterPlayerEditBottomSheet】既存選手の情報とともに編集モードが表示されること',
    'CategoryRuleAdvancedTabsCard renders tabs and viewsこと': '【CategoryRuleAdvancedTabsCard】各種タブおよびビューが正しく描画されること',
    'ViewerTeamCard renders チーム ヘッダー and children cardsこと': '【ViewerTeamCard】チームヘッダーおよび子カードが正しく描画されること',
    'BulkRuleDataHelper correctly resolves 試合 typesこと': '【BulkRuleDataHelper】試合形式が正しく解決されること',
    'BunaiksenIndividualMatchesList renders 選手 names and 試合 rowsこと': '【BunaiksenIndividualMatchesList】選手名および試合行が正しく描画されること',
    'MatchFormatDynamicHeader renders ヘッダー テキスト一覧 and progressこと': '【MatchFormatDynamicHeader】ヘッダーテキストおよび進行状況が正しく描画されること',
    'MatchFormatSectionHeader renders タイトル and accent barこと': '【MatchFormatSectionHeader】タイトルおよびアクセントバーが正しく描画されること',
    'MatchFormatTeamSelectionCard renders チーム info and triggers callbacksこと': '【MatchFormatTeamSelectionCard】チーム情報が描画されコールバックが正常に動作すること',
    'MasterEditOrganizationBottomSheet displays fields and update buttonこと': '【MasterEditOrganizationBottomSheet】入力フィールドおよび更新ボタンが表示されること',
    'TeamRegistrationPlayerSelectBottomSheet renders 選手 list and handles selectionこと': '【TeamRegistrationPlayerSelectBottomSheet】選手一覧が描画され選択が正常に処理されること',
    'own チーム is prioritized with styling without swapping left/right in ViewerHomeScreenこと': '【ViewerHomeScreen】自チームの左右を入れ替えずにスタイリング付きで優先表示されること',
    'SettingsBlock renders children and dividerこと': '【SettingsBlock】子要素および区切り線が正しく描画されること',
    'CategoryRuleRenseikaiSection renders renseikai settings when isRenseikai is trueこと': '【CategoryRuleRenseikaiSection】練習会有効時に練習会設定が正しく描画されること',
    'CategoryRuleRenseikaiSection renders kachinuki settings when isKachinuki is trueこと': '【CategoryRuleRenseikaiSection】勝ち抜き戦有効時に勝ち抜き設定が正しく描画されること',
    'sanitizeFirestoreData correctly maps numbers and nested structuresこと': '【sanitizeFirestoreData】数値およびネスト構造が正しくマッピングされること',
    'CategoryRuleAdvancedSettingsSection renders ippon and hansoku limitsこと': '【CategoryRuleAdvancedSettingsSection】一本および反則の上限設定が描画されること',
    'CategoryRuleAdvancedSettingsSection renders keyword field for advanced modeこと': '【CategoryRuleAdvancedSettingsSection】詳細モード用のキーワード入力欄が描画されること',
    'ViewerOfficialScoreTableCard renders チーム タイトル and テーブル properlyこと': '【ViewerOfficialScoreTableCard】チームタイトルおよびスコアテーブルが適切に描画されること',
    'CategoryRuleMultiSceneTabsCard renders checkboxes and tab viewsこと': '【CategoryRuleMultiSceneTabsCard】チェックボックスおよびタブビューが描画されること',
    'extractActiveMatches correctly separates in_progress and waitingこと': '【extractActiveMatches】進行中と待機中の試合が正しく分離されること',
    'calculate calculates win/loss and strike breakdown correctlyこと': '【calculate】勝敗および有効打突の内訳が正しく計算されること',
    'ProgramViewerMaterialPlaceholder renders タイトル and material info textこと': '【ProgramViewerMaterialPlaceholder】タイトルおよびMaterial情報テキストが描画されること',
    'confirmBulkDelete shows ダイアログ and deletes selected items on confirmこと': '【confirmBulkDelete】確認ダイアログが表示され承認時に選択アイテムが削除されること',
    'ProgramManagementContentViews renders list view with Slidableこと': '【ProgramManagementContentViews】Slidable付きのリストビューが正しく描画されること',
    'ProgramManagementContentViews renders grid view with 選択 supportこと': '【ProgramManagementContentViews】選択機能付きのグリッドビューが正しく描画されること',
    'MatchFormatHeadingAndNoteSection renders preset チップ一覧 and テキスト fieldsこと': '【MatchFormatHeadingAndNoteSection】プリセットチップおよびテキストフィールドが描画されること',
    'generateDescriptiveLeagueTitle generates タイトル correctly for チーム leagueこと': '【generateDescriptiveLeagueTitle】団体リーグ戦のタイトルが正しく生成されること',
    'Shows AppSwitch and switches labels when switch or label is tappedこと': '【AppSwitch】スイッチまたはラベルのタップ時にラベルが切り替わること',
    'TeamRegistrationConfirmStep renders properly with empty listこと': '【TeamRegistrationConfirmStep】空リスト時に適切に描画されること',
    'TeamRegistrationConfirmStep renders properly with teamsこと': '【TeamRegistrationConfirmStep】チーム一覧とともに適切に描画されること',
    'MatchEditDataHelper extracts names and clean notes correctlyこと': '【MatchEditDataHelper】選手名および整形された備考が正しく抽出されること',
    'MatchEditTeamAndPlayersTab renders テキスト fields and handles swapこと': '【MatchEditTeamAndPlayersTab】入力欄が描画され紅白入替が正常に行えること',
    'ViewerCallBanner renders in-progress and 待機中 matchesこと': '【ViewerCallBanner】進行中および待機中の試合が正しく描画されること',
    'ViewerMatchListSearchBar renders search ボタン and sort buttonこと': '【ViewerMatchListSearchBar】検索ボタンおよびソートボタンが正しく描画されること',
    'ViewerHomeHeaderActions renders QR share ボタン and opens ダイアログ correctlyこと': '【ViewerHomeHeaderActions】QR共有ボタンが描画されダイアログが正しく開くこと',
    'ViewerBunaiksenHeaderActions renders calendar ボタン when not QR access and opens More menuこと': '【ViewerBunaiksenHeaderActions】カレンダーボタンが描画され詳細メニューが開くこと',
    'SettingsModel contains textSizeMode and updates correctlyこと': '【SettingsModel】textSizeModeが含まれ正しく更新されること',
    'deleteMatch on Web deletes directly from Firestore and updates optimistic UI stateこと': '【deleteMatch】Web環境でFirestoreから直接削除され楽観的UI更新が行われること',
    'deleteMatch on Web dynamically updates currentTournamentIdProvider and currentDojoIdProvider from MatchModel when they are empty/incorrectこと': '【deleteMatch】Web環境でプロバイダ情報が不足時にMatchModelから動的補完されること',
    'Registered チーム substitute 選手一覧 who are not in active 試合 slots are correctly identified as bench 待機中 reserve 選手一覧 (teamSubstitutes)こと': '【選手登録】試合枠外の登録控え選手がベンチ待機補欠（teamSubstitutes）として識別されること',
    'Verification that extension 試合 decisions correctly set isEncho flag for スコア cards and official recordsこと': '【延長判定】スコアカードおよび公式記録用で正しくisEnchoフラグが設定されること',
    'Verification that MatchEditSheet correctly detects 試合 ルール scene preset key for チップ selectionこと': '【MatchEditSheet】チップ選択用の試合ルール・シーンプリセットキーが正しく検知されること',
    'keeps 選手 names and swaps scores and event sides correctlyこと': '選手名を保持したままスコアおよびイベントの紅白サイドが正しく入れ替わること',
    '順序 works correctly when only comments or only 試合一覧 existこと': 'コメントのみまたは試合のみが存在する場合でも順序が正しく処理されること',
    'BunaiksenOfficialRecordScreen league テーブル should use BunaiksenHelper for pointsこと': '【BunaiksenOfficialRecordScreen】部内戦公式記録のリーグ表でBunaiksenHelperが勝点計算に使用されること',
    'Tapping unread カード should mark it as read and clear pink dotこと': '未読カードのタップ時に既読マークが付与され未読バッジが消去されること',
    'BandGroupEditDialog renders エラーなくこと': '【BandGroupEditDialog】エラーなく正常に描画されること',
    'formats expedition summary correctly for LINE sharingこと': '遠征サマリーがLINE共有用に正しくフォーマットされること',
    'Shuffling the queue preserves all elements and countこと': 'キューのシャッフル時に全要素および件数が保持されること',
    'Reordering via ドラッグ and ドロップ works correctly for both directionsこと': 'ドラッグ＆ドロップによる並び替えが双方向で正常に動作すること',
    'Guest 選手 registration saves under the correct organization, 大会 (date), and guest name subcollection pathこと': 'ゲスト選手登録時に正しい道場・大会日付・ゲスト名サブコレクション配下に保存されること',
    'Practice 試合 creation saves under the correct organization, 大会 (date), and 試合 ID subcollection pathこと': '練習試合作成時に正しい道場・大会日付・試合IDサブコレクション配下に保存されること',
    'Web Environment: Should load 試合 records from Firestoreこと': '【Web環境】Firestoreから試合記録が正しく読み込まれること',
    'Native Environment: Should load 試合 records from Local Database (Isar)こと': '【ネイティブ環境】ローカルDB（Isar）から試合記録が正しく読み込まれること',
    'Bottom ボタン area should remain visible when テキスト input is focused to allow confirmationこと': 'テキスト入力フォーカス時でも確定操作のため下部ボタン領域が視認可能であること',
    'BunaiksenHomeScreen displays today\'s date and "今日の部内戦" by defaultこと': '【BunaiksenHomeScreen】初期状態で本日の日付および「今日の部内戦」が表示されること',
    'Onboarding checklist dynamic checks update when チーム一覧 and ルール設定 are setこと': 'チーム一覧およびルール設定完了時にオンボーディングの動的チェックが更新されること',
    'CategoryRulesScreen renders setup ボタン一覧 and navigates to home when isFromSetup=trueこと': '【CategoryRulesScreen】初期設定時（isFromSetup=true）に設定ボタンが描画されホームへ遷移すること',
    'Should post announcement and timeline comment for "all" targetこと': '全対象向け（all）のアナウンスおよびタイムラインコメントが正常に投稿されること',
    'Should post staff-only announcement and timeline commentこと': 'スタッフ限定のアナウンスおよびタイムラインコメントが正常に投稿されること',
    'MatchShareOptionsBottomSheet renders クラウド and P2P optionsこと': '【MatchShareOptionsBottomSheet】クラウド共有およびP2P配信の選択肢が正しく描画されること',
    'Displays チーム name, position count, and empty memo with placeholderこと': 'チーム名、ポジション数、およびプレースホルダー付きの空メモが表示されること',
    'Correctly resolves own チーム when white side is own teamこと': '白側が自チームの場合でも自チーム情報が正しく解決されること',
    'QuickRosterSwapDialog renders reorderable 選手 list with ドラッグ handlesこと': '【QuickRosterSwapDialog】ドラッグハンドル付きの並び替え可能な選手一覧が描画されること',
    'Displays clear distinctive ボタン一覧 for new チーム 試合 and adding matchesこと': '新規団体戦および試合追加のための明確に区別されたボタン一覧が表示されること',
    'Does not display quick next 試合 ボタン when onQuickNextMatch is null (Hon-sen 大会)こと': '本戦大会時（onQuickNextMatchがnull）に次の試合ボタンが表示されないこと',
}

def main():
    with open('scratch_final_116.json') as f:
        targets = json.load(f)

    file_map = {}
    for item in targets:
        f = item['file']
        if f not in file_map:
            file_map[f] = []
        file_map[f].append(item['title'])

    total = 0
    for filepath, titles in file_map.items():
        if not os.path.exists(filepath): continue
        with open(filepath, 'r', encoding='utf-8') as fp:
            content = fp.read()

        new_content = content
        for orig in titles:
            if orig in MAPPING_116:
                repl = MAPPING_116[orig]
                if orig in new_content:
                    new_content = new_content.replace(orig, repl, 1)
                    total += 1

        if new_content != content:
            with open(filepath, 'w', encoding='utf-8') as fp:
                fp.write(new_content)

    print(f"✅ 最終116件の置換完了: {total} 箇所")

if __name__ == '__main__':
    main()
