# AI-assisted Development Workflow

本ドキュメントは、AI（LLM）を安全かつ効果的に開発プロセスへ組み込むための標準ワークフローを定義します。

## 1. AI実装範囲の定義 (Scope of AI Implementation)
AIによるコード生成を利用する際は、ガバナンスリスクに応じて以下の境界を厳格に守らなければなりません。

### 🟢 AI許可範囲 (Allowed)
- **Boilerplate生成:** DTO, Entityのプロパティ追加, `freezed` クラスの枠組み作成。
- **Test生成:** `rule_testing_standard.md` に準拠したパターンテスト、Property-based testの入力シミュレーションコード。
- **Mapper生成:** `Event` と `Projection` の変換ロジックなど、副作用のない純粋なマッピング関数の作成。

### 🔴 AI禁止範囲 (Forbidden)
- **Architecture Rewrite:** `ADR-001` で定義されたコアルールエンジンやリポジトリ層の根本的なアーキテクチャ書き換え。
- **Replay Semantics 変更:** 過去のイベント履歴（ゴールデンデータ）から導出される勝敗結果を覆すような、ルールの意味論的変更。

## 2. AI Output Audit Flow (AI出力の監査フロー)
AIが生成したコードは、以下の監査フローを必ず通過しなければなりません。

1. **AI Output Generation:** 規定のテンプレート（`prompts/`）を使用してAIにコードを生成させる。
2. **Human Review:** 人間が `review_checklist.md` に基づき、隠れた状態保持やIOアクセスがないか目視確認する。
3. **AI-generated Test Validation:** AIに書かせたテストが、わざとバグを仕込んだ際に「正しく失敗する（Red）」状態を作れるか確認し、テスト自体の妥当性を検証する。
4. **CI Pipeline Validation:** Governance Scanner と Replay Regression Test の自動チェックを通過させる。