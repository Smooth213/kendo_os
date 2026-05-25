# 🛡️ Governance & Replay Dashboard

`kendo_os` AI Governance Runtime の運用状況をリアルタイムに可視化する。

## 🚦 現在のステータス: **LOCKED (v1.0.0)**
- **最終検証日時 (UTC):** 2026-05-09
- **Replay Safety:** 100% (126件のテスト全件合格)
- **Governance Drift:** 0% (Baseline Hash 一致)

## ⚖️ AI Change Risk Metrics
| メトリクス | 数値 / 状態 | 判定 |
| :--- | :--- | :--- |
| 最新リスクスコア | 0 / 100 | ✅ LOW |
| 歴史的整合性 (Replay) | Stable | ✅ PASS |
| 人間による承認率 | 100% | ✅ PASS |

## 📑 Governance Decision Ledger (Step 5-5: Traceability)
AIによる意思決定の履歴。すべての変更は `governance/ledger/decision_ledger.jsonl` に不変のログとして刻まれる。

| Timestamp | Task | Risk | Replay Risk | Status |
| :--- | :--- | :--- | :--- | :--- |
| (Auto-updated) | (See Ledger) | (Score) | (Safe/Risk) | ✅ Audited |

> **Audit Linkage:** 各エントリは Git Commit ID および ADR と紐付けられ、人間による承認の証跡を含む。

## 📜 監査ログ (Violation History)
- **憲法違反:** 0件
- **不変条件違反:** 0件
- **禁止API検知:** 0件

> **注意:** 本ダッシュボードは `scripts/generate_replay_dashboard.dart` によって自動更新される。直接の編集は原則禁止とする。