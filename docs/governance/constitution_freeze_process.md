# Constitution Freeze Process (憲法凍結・変更プロセス)

本ドキュメントは、`kendo_os` における決定権限の階層と、最上位規約である「憲法」の変更フローを定義する。

## 1. 権限階層 (Constitution Hierarchy) (Step 3-1)
下位の規約は、常に上位の規約を遵守しなければならない。

1. **Constitution (憲法)**: `governance_constitution.md` - 最上位哲学。
2. **Architecture Invariants (不変条件)**: `architecture_invariants.md` - 技術的絶対制約。
3. **ADR (Architecture Decision Records)**: 特定設計の決定背景。
4. **Runtime Policy**: `forbidden_patterns.yaml` 等の実行ルール。
5. **Prompt Template**: AIへの具体的指示書。

## 2. 凍結・変更ワークフロー (Step 3-2)
憲法または不変条件を変更する場合、以下のステップを例外なく踏まなければならない。 AIによる独断での修正は「違憲」としてCIで自動却下される。

1. **Proposal**: 変更が必要な背景と目的の明示。
2. **ADR Creation**: 変更内容をADRとして記録。
3. **Replay Analysis**: 変更が過去の試合結果（Replay）に与える影響の機械的証明。
4. **Human Approval**: 裁定権を持つ人間によるデジタル署名（GOVERNANCE_HUMAN_TOKEN）。
5. **Freeze Tag**: `governance/runtime_version.yaml` のバージョン更新とハッシュの再固定。