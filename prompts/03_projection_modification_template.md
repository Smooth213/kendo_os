# Projection Modification Template (射影・UI変更用プロンプト)

UI（Viewer等）のための状態構築（Projection）ロジックを変更します。

## 1. 読み込み必須ファイル (AI Context)
- `prompts/00_ai_forbidden_actions.md`

## 2. AI作業指示
1. Projectionのロジックが、ドメインの「真実（Truth）」を再定義してはなりません（UI結果をイベントソースに書き戻さないこと）。
2. UIの都合（遅延や一時的な非同期）を、RuleEngine内部のドメインイベントに持ち込まないでください。
3. イベントストリームから導出される読み取り専用のデータモデル（View Model）としてのみ構築してください。

## 3. ユーザー入力要件
[ここにProjection変更の要件を記載してください]