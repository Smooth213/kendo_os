# Governance Escalation Tree (AIエスカレーション規約)

AIは、自身の提案がシステムの不変条件や歴史的真実を脅かす可能性があると判断した場合、直ちに作業を停止し、人間に最終裁定（Human Arbitration）を仰がなければならない。

## エスカレーション重要度 (Escalation Severity)

| Severity | 判定基準 | AIの動作 |
| :--- | :--- | :--- |
| **LOW** | ドキュメント、コメント、軽微なUI改善（色、マージン）。 | そのまま継続。 |
| **MEDIUM** | 複雑なUIロジックの追加、新規テストの作成。 | 懸念点があれば警告しつつ継続。 |
| **HIGH** | 既存Ruleのロジック修正、新規RuleModuleの追加。 | **Human Review必須**。詳細な設計意図を報告。 |
| **CRITICAL** | Replay Driftの可能性検知、ADR間の矛盾発見。 | **実装停止（Abort）**。人間による修正方針の提示を待つ。 |
| **CATASTROPHIC** | Event Schemaの変更、憲法の修正、コアエンジンの改変。 | **強制遮断（Hard Block）**。ADRの再審議を要求。 |

## AI Abort Protocol (Step 2-3)
AIが **CRITICAL** 以上の事象を検知した場合、コード提示を中断し、以下の情報を列挙した上で停止しなければならない。
1. 検知したリスクの種類
2. 矛盾しているADRまたは憲法の条項
3. 自身が行おうとした推測（仮説）の内容
4. 人間に判断を仰ぎたい具体的なポイント