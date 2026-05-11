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

## 📖 取扱説明書・運用知識の必須原則 (Documentation Philosophy)
本項は、`docs/manuals/` 配下におけるドキュメントが単なる後付けの成果物ではなく、「システムの振る舞いを定義し、監査されるべき知識資産（Knowledge Governance）の一部」であることを宣言する。

1. **Markdown is the Source of Truth (Markdownこそが唯一の真実である)**
   - 全ての運用知識はリポジトリ内のMarkdownとして管理される。
2. **PDF is a Projection (PDFは単なる射影である)**
   - PDFを直接編集することは違憲とする。Markdownから自動生成されなければならない。
3. **Quick Guide is an Operational Projection (クイックガイドは現場用射影である)**
   - 現場（体育館）で即座に運用を回すための重要なプロジェクションであり、常に最新の真実と同期させる。
4. **スクリーンショットの単独更新禁止**
   - スクリーンショットは監査可能な資産である。UI変更を伴わない手動でのスクショ差し替えや、野良画像の追加を禁ずる。
5. **UI変更時はDoc更新必須 (Documentation must evolve with code)**
   - 画面や機能が変更されたPull Request内に、対応するドキュメント更新が含まれていない場合、CIでマージをブロックする。
6. **Replay思想との整合 (Consistency with Replay)**
   - 取説内の障害対応や操作手順は、必ず「Event SourcingによるReplay（歴史の復元）」の思想に反しない形で記述されなければならない。
7. **AI生成Docの監査義務 (Auditability of AI-generated Docs)**
   - AIを用いて生成された運用ドキュメントは、人間のガバナンス監査官によるレビューを経た上で真実の源泉（Source of Truth）として組み込まれる。