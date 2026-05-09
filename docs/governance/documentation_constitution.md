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
- `docs/manuals/`: **Knowledge** (運用知識・取扱説明書の唯一の情報源) ## ⚖️ 最終監査基準 (Final Governance Audit)
すべての変更は、以下の4項目を損なわないことを条件に承認されます。
- **Replay Truth**: 歴史改変を 1 bit も許さない。
- **Human Authority**: 人間の審判・運営をシステムの上位に置く。
- **Tournament Continuity**: 障害時でも大会を止めない。
- **Determinism**: 常に予測可能で冪等な計算を行う。

---

## 📖 取扱説明書・運用知識の必須原則 (Manuals & Knowledge Base Principles)
本項は、`docs/manuals/` 配下におけるドキュメント（取扱説明書、クイックガイド等）が単なる後付けの成果物ではなく、「システムの振る舞いを定義し、監査されるべきガバナンス資産（Operational Runtime）の一部」であることを宣言する。

1. **Markdown is the Source of Truth (Markdownこそが真実である)**
   - 全ての運用知識と取扱説明書は、リポジトリ内のMarkdownとして管理されなければならない。
2. **PDF is a projection artifact (PDFは単なる射影である)**
   - PDFや印刷物は、Markdownから機械的に生成された一時的なビュー（Projection）に過ぎない。PDFを直接編集することは違憲とする。
3. **Documentation must evolve with code (コードとドキュメントの同期進化)**
   - UIやルールの変更が行われた場合、対応するドキュメントも更新されなければならない。未更新はCIによって自動的にマージブロックされる。
4. **UI changes require documentation review (UI変更時のドキュメント監査)**
   - 画面構成が変わる場合、取扱説明書の該当箇所およびスクリーンショット参照が矛盾しないかレビューを必須とする。
5. **Emergency procedures require auditability (緊急対応手順の監査可能性)**
   - ネットワーク断やデータ破損時の対応手順は、現場の誰もが実行でき、かつ後から監査可能な形でドキュメント化されていなければならない。
6. **AI-readable structure is mandatory (AI可読な構造の義務化)**
   - 全てのドキュメントは、将来的なAI検索（Vector Search / RAG）が正確に文脈を抽出できるよう、Style Guideに沿った厳格な構造（見出し、タグ付け）を持たなければならない。