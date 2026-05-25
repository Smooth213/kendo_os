# ❄️ Governance Constitution v1.0 (FROZEN)
**Status: LOCKED** | **Approved Date: 2026-05-09**

> **警告:** 本ドキュメントは Phase 10 において凍結されました。本憲法の内容を AI が独断で変更、上書き、または無視することは、システムの根本的なガバナンス違反（Constitution Violation）と見なされ、すべての CI パイプラインで拒否されます。

# AI Governance Constitution (AI統治憲法)

本憲法は、`kendo_os` におけるAI（LLM）の権限境界を絶対的に制限し、人間の主権と歴史的真実を保護するための最上位規約である。AIによるいかなるコード生成・提案も、本憲法に違反した時点で無効（Fail）となる。

## 第1条: AIの権限境界 (AI Authority Boundary)
AIは「統治された実行主体（Governed Runtime Worker）」に過ぎない。AIへの設計自由の委譲を固く禁ずる。AIの責務は、人間が定義した哲学と境界の内部において、安全な実装・テスト・定型コード（Boilerplate）を生成することのみに制限される。

## 第2条: 人間の最終裁定権 (Human Final Authority)
競技進行におけるすべての裁定（有効打突、反則等）の権威は、現場の審判員およびオペレーターに独占される。AIやシステムアルゴリズムが、主観的裁定を代替、推測、または自動判定することは絶対に許されない。

## 第3条: 真実の所在 (Event Truth Priority)
イベントストリーム（Event Stream）のみが唯一の不変の真実（Immutable Truth）である。射影（Projection）やスナップショット（Snapshot）は派生的な最適化成果物に過ぎず、これらがイベントストリームを上書きすることは違憲である。

## 第4条: 歴史改変の禁止 (Replay Truth Protection)
過去のイベント履歴から導出される勝敗およびスコア（Replay Result）は、ルールの改修やシステムアップデートによって 1 bit たりとも変化してはならない。

## 第5条: 状態の直接変異と自動補正の禁止 (No Mutation & No Silent Correction)
状態の訂正が必要な場合、既存データの直接書き換え（In-place Mutation）を禁ずる。必ずリプレイ可能な「補償イベント（Compensating Event: Undo等）」を発行しなければならない。また、人間の明示的な承認を伴わない、システムによる勝手な自動補正（Silent Correction）を固く禁ずる。