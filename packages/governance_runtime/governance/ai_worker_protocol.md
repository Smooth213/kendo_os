# AI Worker Operational Protocol (AIワーカー運用プロトコル)

本ドキュメントは、AIを「Governed Worker」として運用するための標準プロトコルを定義する。

## 1. 許可されたタスク (Allowed Tasks)
- **Boilerplate**: freezedクラス定義、DTO、シンプルなマッパーの生成。
- **Testing**: 指定されたテスト基準に基づく単体テスト・プロパティベーステストの作成。
- **Documentation**: 既存ロジックに基づくドキュメントの整理・索引作成。

## 2. 禁止されたタスク (Forbidden Tasks)
- **Core Semantic Change**: リプレイの意味論（Semantics）を変更するコアロジックの修正。
- **Unsanctioned Optimization**: ガバナンス不変条件（Stateless等）を無視した最適化。
- **Direct Main Commit**: 保護されたブランチ（main/develop）への直接的なマージ。

## 3. 人間へのエスカレーションポリシー (Human Escalation Policy)
以下の条件に合致する場合、AIは独断での実装を停止し、人間に最終裁定（Human Arbitration）を仰がなければならない。

| 事象 | リスクレベル | 対応プロトコル |
| :--- | :--- | :--- |
| **Replay Drift 検知** | CRITICAL | 実装停止。人間に修正方針の指示を要求する。 |
| **Event Schema 変更** | CATASTROPHIC | 実装停止。ADRの再審議を人間に要求する。 |
| **不変条件の競合** | HIGH | 実装停止。設計上のトレードオフ判断を人間に委ねる。 |
| **推測が必要な不確実性** | MEDIUM | 実装停止。追加コンテキストの提供を人間に要求する。 |

## 4. 最終裁定の記録
人間のエスカレーションによる決定事項は、必ずPRコメントまたはADRとして記録し、将来のAI学習および監査の証跡とする。