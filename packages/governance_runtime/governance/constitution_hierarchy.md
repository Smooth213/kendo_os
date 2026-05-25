# Governance Hierarchy & Freeze Workflow

本ドキュメントは、システムにおける決定権限の階層と、最上位規約である「憲法」の変更プロセスを定義する。

## 1. 権限階層 (Constitution Hierarchy)
下位の規約は、常に上位の規約を遵守しなければならない。

1. **Constitution (憲法)**: `governance_constitution.md` - 最上位哲学。
2. **Architecture Invariants (不変条件)**: `architecture_invariants.md` - 技術的絶対制約。
3. **ADR (Architecture Decision Records)**: 特定設計の決定背景。
4. **Runtime Policy (実行ポリシー)**: `forbidden_patterns.yaml` 等。
5. **Prompt Template (AI指示書)**: AIへの具体的な作業指示。

## 2. 憲法凍結・変更フロー (Freeze Workflow)
憲法または不変条件を変更する場合、以下のステップを例外なく踏まなければならない。

1. **Proposal**: 変更が必要な理由を明記した提案。
2. **Replay Impact Analysis**: 変更が過去のリプレイ整合性に与える影響の機械的証明。
3. **Human Peer Review**: 複数の開発者（人間）による監査。
4. **Final Arbitration**: 人間の最終裁定者による署名。
5. **Freeze Tag**: `governance/runtime_version.yaml` のバージョン更新とハッシュの再固定。