# ADR 001: 剣道ルールエンジンのプラグイン化と階層型Configの導入

## Status
Accepted (2026-05)

## Context
剣道大会のルールはグローバルに完全標準化されておらず、同一カテゴリ内でも大会ごとにルールが極端に異なる。**「ルールが曖昧であり、大会ごとに変化すること」自体が剣道という競技のドメイン特性**である。
本システムではルールの差異を静的な設定ではなく、拡張可能なドメイン制約として正面から受け入れるアーキテクチャが必要とされた。また、イベントソーシング（Event Sourcing）による試合再構築において、歴史的再現性と決定論的な挙動はシステムの信頼性の核心である。

## Decision

**1. Rule System as Domain Boundary & Philosophy (ドメイン境界と哲学):**
Rule System は単なる設定機構ではなく、競技文化と試合進行制約を隔離・表現する。本システムは大会運営と情報の流れを支援するために設計されており、人間の審判員の裁定が常に最終的な権威（Authoritative）である。**有効打突の判定や主観的裁定をアルゴリズムで置き換えるものではない。**

**2. Behavior Injection & Idempotent Pure Function (振る舞いの注入と冪等性):**
Ruleを純粋な「振る舞い（Behavior）」としてモデル化し、実行時に注入する。評価は `RuleContext` と `RuleVersion` に対する**冪等な純粋関数 (Idempotent Pure Function)** でなければならない。同一入力に対しては何度評価しても、隠れた副作用を蓄積せずに同一の結果を返却する。

**3. Semantic Ownership & Isolation (責務の明確化と隔離):**
各 RuleModule は、単一かつ明確に境界付けられた意味論的責務（Semantic Responsibility）を持つ。「God Rule」化を避け、モジュール間の双方向依存（Bidirectional Dependency）は厳禁とする。

**4. External IO & Time Source (外部入出力と時間の隔離):**
評価中のネットワーク、DB、ファイルシステム、プラットフォームチャンネルへのアクセスを一切禁ずる。システムクロック（`DateTime.now()`）に直接依存せず、`RuleContext` 経由で注入された明示的な TimeSource のみを使用する。

**5. Rule Failure Isolation & Policy (失敗の隔離とポリシー):**
単一モジュールの評価失敗が、試合全体の状態破壊やReplay停止を引き起こしてはならない。失敗は例外（Exception）ではなく、決定論的な `FailureResult` として制御フロー内で扱う。また、ルールカテゴリごとに**障害時の振る舞い（Fail-closed: 試合停止 / Fail-open: 継続許可）を明示的に定義**しなければならない。

**6. Evaluation Order & Conflict Resolution (評価順序と競合解決):**
評価順序は決定論的に固定される。順序依存の副作用を禁止し、複数ルールが競合する場合の最終裁定権（Conflict Resolution Authority）は、RuleResolver の実行パイプラインが独占的に所有する。

**7. Event Stream, Snapshot & Replay Over Mutation (真実の所在と補償イベント):**
**イベントストリームこそがドメインの不変の真実（Immutable Truth）である。** 状態の訂正が必要な場合は、直接的な状態変更（State Mutation）ではなく、リプレイ可能な補償イベント（Compensating Events: Undo/Restore等）の発行を優先する。スナップショットは単なる最適化（Optimization）のための成果物であり、真実を置き換えるものではない。

**8. Projection & Distributed Eventual Consistency (射影と分散結果整合性):**
分散環境下のUI表示（Projection）は一時的に乖離（Diverge）する可能性があるが、権威あるイベントストリームは最終的に決定論的かつ一貫した状態に収束（Converge）しなければならない。射影の結果がドメインの真実を再定義してはならない。

**9. Human Override, Emergency Recovery & Continuity (緊急復旧と継続性優先):**
システムは人間のオペレーターによる裁定の上書きを常にサポートし、自動ルール評価から独立した**「人間のための緊急復旧機能（Emergency Recovery）」**を保持する。運用環境の劣化（ネットワーク切断、端末フリーズ等）が発生した場合、厳密な同期やUIの鮮度よりも**「大会の継続性（Tournament Continuity）」を最優先**とする。

**10. No Silent Correction & Auditability (自動補正禁止と監査可能性):**
**オペレーターの明示的な承認なしに、システムがドメインイベントを勝手に自動補正（Silent Correction）することは固く禁ずる。** すべてのドメイン上の重要な決定は、後日のクレームや監査（Audit）に備え、歴史的に説明可能（Explainable）でなければならない。

**11. Pre-execution Validation & Trust Boundary (事前検証と境界):**
ルールの整合性検証はMatch開始前に完了させる。外部から供給されるリモートルールパッケージやDSLは、検証が完了するまで「信頼できない入力（Untrusted Input）」として扱う。

**12. Observability Must Not Alter Behavior (観測の独立性):**
計装（Instrumentation）、ロギング、および観測（Observability）パイプラインは、副作用を持たず、ルール評価の意味論を決して変更してはならない。

## Architecture Invariants (アーキテクチャ不変条件)
以下は、将来のいかなる最適化においても変更を禁止する絶対的アーキテクチャ制約とする。
- **Rule evaluation must remain deterministic and idempotent.**
- **Rule evaluation should remain monotonic:** 後続のルールが先行ルールの正当性を破壊してはならない。
- **RuleModule must remain stateless and side-effect free:** 内部キャッシュや評価履歴の保持を禁止する。
- **Hidden global mutable state is prohibited.**
- **Rule evaluation must complete within bounded and predictable cost:** 評価コストを予測可能に保つ。
- **State correction must prefer replayable compensating events over direct mutation.**
- **Automatic correction without explicit human acknowledgment is prohibited.**
- **During operational degradation, tournament continuity takes precedence over synchronization.**
- **Authoritative control ownership must remain explicit during concurrent operations.**
- **Observability pipelines must never alter rule evaluation semantics.**
- **Human referee authority is the final source of truth.**

## Considered Options (不採用案)
- **巨大switchベース RuleEngine:** 拡張性がなく、条件分岐爆発リスクが高いため。
- **カテゴリ固定Preset方式:** 大会ごとの微細なローカルルールに対応できないため。
- **DB上のboolean matrix管理:** 設定と振る舞いが密結合し、決定論的保証が困難になるため。

## Consequences
* **Positive:**
  * 「ルールが揺らぐ世界」を壊さずに扱える強固な構造を確立した。
  * 現場運用に即した明確な Failure Policy と Emergency Recovery の指針が示された。
* **Negative:**
  * **Rule Interaction Complexity:** 個別には正しいモジュール同士でも、組み合わせによる予期しない競合の可能性があるため、継続的な包括的テストが必須となる。

## Future Direction
- **GUI-based Rule Builder / DSL (Domain-Specific Language)** による定義
- **Remote Rule Package Distribution:** エンジンバージョンとの互換性契約（Compatibility Contract）を明示したリモートパッケージの配信
- 大会ごとの Validation Policy の動的適用