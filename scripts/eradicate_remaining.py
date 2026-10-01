#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 残存英文＆括弧完全根絶スクリプト (Eradicate Remaining English & Brackets)
======================================================================================
"""

import os

REPLACEMENTS = {
    # 英文18件の完全日本語化
    'formatScoreboardTitle removes UUIDs and raw group IDs correctlyこと': 'formatScoreboardTitleがUUIDおよび生グループIDを正しく除去すること',
    'Service can be instantiatedこと': 'サービスのインスタンスが正常に生成できること',
    'forceClaimScorer overrides existing lock immediatelyこと': 'forceClaimScorerが既存のロックを即座に上書きできること',
    'MatchUndoHelper can be instantiated properlyこと': 'MatchUndoHelperのインスタンスが正常に生成できること',
    'buildHeader generates header with correct metadataこと': 'buildHeaderが正しいメタデータを含むヘッダーを生成すること',
    'Render options, checkboxes, filters, and update successfullyこと': 'オプション・チェックボックス・フィルターが描画され更新が成功すること',
    'TimelineLeagueTitleHelper generates descriptive title correctlyこと': 'TimelineLeagueTitleHelperが説明的タイトルを正しく生成すること',
    'buildSpans generates correct spans for continuous matchesこと': '連続試合に対して正しいスパンが生成されること',
    'generatePositions generates correct listsこと': 'ポジションリストが正しく生成されること',
    'manual index list and filters items on searchが正しく描画されること': 'マニュアル目次リストが表示され検索時にアイテムが正しく絞り込まれること',
    'generateDescriptiveLeagueTitle generates title for team leagueこと': '団体リーグ戦用のタイトルが正しく生成されること',
    'ViewerOfficialRecordScreen matches should be sorted by matchOrderこと': '観客用公式記録画面の試合一覧が試合順序（matchOrder）でソートされること',
    'NotificationBellButton should display sakura pink dot if unread notifications existこと': '未読通知が存在する場合に通知ベルボタンに桜ピンクのドットが表示されること',
    'Removing players (leaving) removes them without disturbing other players\\': '選手の離脱削除時に他の選手データに影響を与えることなく正常に削除されること',
    'PopFirst retrieves and removes the front playerこと': '先頭の選手が正常に取り出されキューから除去されること',
    'ボトムシート should present "確定して終了" ボタン and transition to 試合 終了済み ダイアログ on tapこと': 'ボトムシートに「確定して終了」ボタンが表示されタップ時に試合終了済みダイアログへ遷移すること',
    'WebViewHtml generates correct HTML with host and portこと': 'ホストとポートを含む正しいWebView用HTMLが生成されること',

    # グループ名の英日混在解消
    'UIエラー・リグレッションテスト: ListTile Material Assertion': 'UIエラー・リグレッションテスト: ListTileのMaterial例外アサーション回避',
    'MasterManagementScreen Welcome Flow テスト': 'マスタ管理画面 初期ウェルカムフローテスト',
    'Code Quality & リグレッションテスト: Hardcoded Specific Names Protection': 'コード品質＆リグレッションテスト: ハードコード固有名保護',
    'ReadAnnouncementsNotifier Synchronization & Persistence テスト': '既読アナウンス同期および永続化テスト',
    'QuickMemoStorageService Cloud Sync & Backward Compatibility テスト': 'クイックメモストレージ クラウド同期および後方互換性テスト',
    'Timeline UI State Provider テスト': 'タイムラインUI状態プロバイダーテスト',
    'League Table Painters テスト (描画レイヤー保護テスト)': 'リーグ対戦表ペインター描画レイヤー保護テスト',
    'SyncEngine Status Protection テスト (同期時のステータス巻き戻り保護テスト)': '同期エンジンステータス巻き戻り保護テスト',
    'マニュアル検索・クエリ機能テスト (Manual Search & Query テスト)': 'マニュアル検索およびクエリ機能テスト',
    'マニュアル完全性＆整合性テスト (Manual Integrity テスト)': 'マニュアル完全性および整合性テスト',
    'AddScoreUseCase - Event Driven Update': 'AddScoreUseCase イベント駆動更新テスト',

    # テスト名内の余計な [Golden] プレフィックスの除去
    "testWidgets('[Golden] 複数名個人戦（中学生の部）取り込みカードがダークモード・ライトモードでオーバーフローなく描画されること": "testWidgets('複数名個人戦（中学生の部）取り込みカードがダークモード・ライトモードでオーバーフローなく描画されること",
    "testWidgets('[Golden] 全6カテゴリ（小学生低学年〜一般）の個人戦バッジがモバイル幅（375px）で崩れず描画されること": "testWidgets('全6カテゴリ（小学生低学年〜一般）の個人戦バッジがモバイル幅（375px）で崩れず描画されること",
    "testWidgets('[Golden] 試合形式編集ボトムシート（全8形式）がタブレット＆モバイルでレイアウト崩れなく表示されること": "testWidgets('試合形式編集ボトムシート（全8形式）がタブレット＆モバイルでレイアウト崩れなく表示されること",

    # テスト名内の角括弧リストの除去
    "最上位groupが規約タグ([Unit], [Widget], [Governance], [Golden], [E2E], [Security])で始まっていること": "最上位groupが規約タグ（Unit・Widget・Governance・Golden・E2E・Security）で始まっていること",
}

def main():
    total_files = 0
    total_count = 0
    for root, _, files in os.walk('test'):
        for file in files:
            if file.endswith('_test.dart'):
                p = os.path.join(root, file)
                with open(p, 'r', encoding='utf-8', errors='ignore') as f:
                    content = f.read()

                new_content = content
                file_count = 0
                for target, repl in REPLACEMENTS.items():
                    if target in new_content:
                        new_content = new_content.replace(target, repl)
                        file_count += 1

                if file_count > 0:
                    total_files += 1
                    total_count += file_count
                    with open(p, 'w', encoding='utf-8') as f:
                        f.write(new_content)

    print(f"徹底根絶完了: {total_files} ファイル / {total_count} 箇所修正")

if __name__ == '__main__':
    main()
