# Emergency Recovery Template (緊急復旧フロー追加用プロンプト)

現場のオペレーターによる緊急復旧やヒューマンオーバーライド（Human Override）の仕組みを追加します。

## 1. 読み込み必須ファイル (AI Context)
- `docs/operations/emergency_recovery_procedure.md`
- `prompts/00_ai_forbidden_actions.md`

## 2. AI作業指示
1. 状態を直接ミューテーション（State Mutation）するのではなく、必ず「補償イベント（Compensating Event: Undoなど）」を発行するフローを設計してください。
2. ネットワーク同期よりも Tournament Continuity（大会継続性）を最優先とするオフラインファーストの操作として設計してください。

## 3. ユーザー入力要件
[ここに緊急復旧機能の要件を記載してください]