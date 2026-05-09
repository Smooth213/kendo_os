# Replay Migration Template (リプレイ互換性維持修正用プロンプト)

イベントストリームやルールの意味論（Semantics）を変更する作業を行います。

## 1. 読み込み必須ファイル (AI Context)
- `docs/architecture/replay_compatibility_policy.md`
- `prompts/00_ai_forbidden_actions.md`

## 2. AI作業指示
1. 既存の `ruleVersion` のロジックを直接書き換える（In-place mutation）ことは絶対にしないでください。
2. 意味論が変わる場合は、新しい `RuleModule` クラスを作成し `ruleVersion` をインクリメントしてください。
3. 新機能であっても、過去のイベント履歴から再構築される勝敗結果を改変してはなりません。

## 3. ユーザー入力要件
[ここにマイグレーションの要件を記載してください]