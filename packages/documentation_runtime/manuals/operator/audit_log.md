---
ai_metadata:
  screen: audit_log_screen
  role: operator_admin
  risk: low
  governance_level: L2
  offline_supported: true
---
[総合ホーム](../manual_index.md) > [運営・記録マニュアル](index.md) > 監査ログ（操作履歴）の確認

# 監査ログ（操作履歴）の確認

「いつ、誰が、どの端末で、何を変更したか」を秒単位で追跡・検証できるシステム監査画面です。
審判の疑義や記録ミスが発生した際、過去の全操作を確実に検証できます。

## 1. 画面の見方と記録項目 {#operate-audit-view}

- **発生時刻**: 操作が行われた正確なタイムスタンプ（最新順に表示）。
- **操作元端末・役割**: 操作を行った端末情報（例: 「第1試合場 記録係」など）。
- **イベント種別**:
  - `SCORE_ADDED`: 有効打突（面、小手など）の記録
  - `SCORE_UNDO`: 点数の取り消し
  - `RULE_CHANGED`: 一括ルール変更などの設定更新
  - `MATCH_CONFIRMED`: 試合結果の長押し確定
- **対象試合ID**: 操作対象となった試合の一意な識別番号。

## 2. 試合IDによるリアルタイム絞り込み {#filter-by-match}

画面上部の検索バーに **試合ID（またはキーワード）** を入力すると、疑義の生じている特定試合の操作ログのみを瞬時に抽出できます。

## 3. 改ざん防止とイベントソーシングの仕組み {#operate-audit-reason}

本システムは「過去のデータを上書きして消す」ことを行いません。
点数を間違えて取り消した場合も、「取り消したというイベント」を追加記録する **イベントソーシング（Event Sourcing）** アーキテクチャを採用しています。これにより、不正な改ざんを完全に防ぎ、誰が見ても100%納得できる公正な大会運営を証明できます。

---

## 関連ページ
- [成績管理と公式記録](official_record.md)
- [進行中の一括ルール変更](bulk_rule_edit.md)
- [緊急トラブル解決ガイド](../recovery/failure_catalog.md)

## 困ったとき
- [点数の経緯をさかのぼりたい](../recovery/failure_catalog.md#recovery-mistake)
- [システム監視ダッシュボード](../recovery/observability_dashboard.md)