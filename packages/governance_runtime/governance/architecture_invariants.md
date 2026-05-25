# Architecture Invariants & Forbidden List (基準線固定)

本ドキュメントは、Phase 0において抽出・固定されたシステムの絶対不変条件と禁止APIの一覧です。以降のAIおよび人間による開発において、これらを破ることは例外なく禁止されます。

## 1. Architecture Invariants (不変条件)
ADR 001 および Core Philosophy より抽出された、設計上絶対に守るべき条件です。

- **Deterministic & Idempotent:** ルール評価は、同じ入力に対して常に同じ結果を返し、何度評価しても隠れた副作用を蓄積しないこと。
- **Stateless:** `RuleModule` は内部キャッシュや評価履歴などの状態を保持しないこと。
- **No IO:** ルール評価中のネットワーク、DB、ファイルシステムへのアクセスを一切禁ずる。
- **Replay Compatibility:** いかなる改修においても、過去のイベント履歴から導出される結果（真実）を改変しないこと。
- **No Silent Correction:** オペレーターの明示的承認なしにデータを自動補正しないこと。

## 2. Forbidden API List (禁止事項一覧)
コードレビューおよび今後のCIパイプライン（Phase 1）において、以下のAPIやパターンの使用を「哲学違反」として検出・拒否します。

```yaml
forbidden:
  - "DateTime.now()" # 明示的な TimeSource を使用すること
  - "Random()" # 決定論的挙動を破壊するため
  - "HttpClient" # IOアクセスの禁止
  - "File()" # IOアクセスの禁止
  - "static mutable" # グローバル状態の保持禁止
  - "implicit singleton" # 隠蔽された状態の保持禁止