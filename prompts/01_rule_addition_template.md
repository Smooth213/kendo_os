# Rule Addition Template (ルール追加時用プロンプト)

以下の要件に従って、新しい `RuleModule` を作成してください。

## 1. 読み込み必須ファイル (AI Context)
- `docs/architecture/rule_authoring_guide.md`
- `prompts/00_ai_forbidden_actions.md`

## 2. AI作業指示
1. 制約（Forbidden Actions）を絶対に破らない**純粋関数 (Pure Function)**として実装してください。
2. 新しいルールクラスは `lib/domain/rules/` に配置してください。
3. `RuleResolver` への登録コードを含めてください。
4. 単体テストおよび `test/integration/replay_regression_test.dart` に影響がない（歴史破壊がない）ことを確認するコードを提示してください。

## 3. ユーザー入力要件
[ここに新しいルールの要件を記載してください]