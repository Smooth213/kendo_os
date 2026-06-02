# Stage 2 β Baseline Status
Date: 2026-05-31
Commit Hash: [Current HEAD]

## 1. 現在の機能一覧
- 大会運営管理 (Create/Update/Delete)
- 選手抽選ロジック (Deterministic Logic)
- 試合進行ステート管理 (Waiting/Playing/Finished)
- リアルタイムスコアリング (ScoreEvent-based)
- 同時編集競合解決 (Logical Clock / CRDT)

## 2. 公開機能一覧
- 審判用スコア操作インターフェース
- 大会運営ダッシュボード
- リアルタイム同期機能

## 3. 非公開機能一覧
- 監査用ログ解析ツール
- システムデバッグモード

## 4. 既知制限
- 大規模通信遮断時の再同期待機時間 (現状仕様通り)
- ネットワーク環境に依存したレイテンシ