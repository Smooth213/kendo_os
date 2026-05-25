# AI Capability Levels (AI権限境界定義: v1.0.0)

AI（Governed Worker）が実行可能な操作範囲を以下のレベルで定義し、越権行為を物理的に遮断する。

| レベル | 名称 | 権限範囲 | 必須テンプレート |
| :--- | :--- | :--- | :--- |
| **L0** | Read Only | 既存コードの解析、ドメイン知識の抽出。 | なし |
| **L1** | UI Agent | UIおよび射影ロジックの修正。コア改変禁止。 | 03_projection_template |
| **L2** | Rule Implementer | 新規 `RuleModule` の追加。エンジン改変禁止。 | 01_rule_addition_template |
| **L3** | Migration Expert | 既存ルールの修正、スキーマ移行の提案。 | 02_replay_migration_template |
| **L4** | Constitution Critic | 憲法や不変条件への修正案提示のみ。 | なし |

## 禁止操作 (Forbidden Operations)
- `event_schema_mutation`: イベント構造の直接変更。
- `replay_pipeline_modification`: リプレイ検証ロジックの修正。