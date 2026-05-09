# Documentation Constitution (ドキュメント憲法) - Final Version

本プロジェクトの統治構造を支えるドキュメント体系の最終定義です。

## 🏛 ガバナンスの柱 (Governance Pillars)
1. **[Core Philosophy](./core_philosophy.md)**: 決して揺るがない5つの設計哲学。
2. **[Architecture Invariants](./../adr/001_rule_engine_pluginization.md)**: 技術的な絶対不変条件（ADR-001内）。
3. **[Automation Policy](./automation_policy.md)**: 機械的な監視と整合性保証の仕組み。

## 📂 ドキュメントの住所 (Final Taxonomy)
- `docs/adr/`: **Why** (なぜ選んだか、何を守るか)
- `docs/architecture/`: **How** (どう設計されているか、どう拡張するか)
- `docs/operations/`: **Run** (現場でどう動かし、どう救済するか)
- `docs/domain/`: **What** (競技として何が正しいか、用語の定義)
- `docs/testing/`: **Quality** (どう品質を証明し、歴史を守るか)
- `docs/governance/`: **Rule** (ドキュメント自体をどう統治するか)

## ⚖️ 最終監査基準 (Final Governance Audit)
すべての変更は、以下の4項目を損なわないことを条件に承認されます。
- **Replay Truth**: 歴史改変を 1 bit も許さない。
- **Human Authority**: 人間の審判・運営をシステムの上位に置く。
- **Tournament Continuity**: 障害時でも大会を止めない。
- **Determinism**: 常に予測可能で冪等な計算を行う。