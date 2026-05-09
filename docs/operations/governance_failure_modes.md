# Governance Failure Modes & Continuity (障害モードと運用継続)

本ドキュメントは、システム障害やガバナンス違反検知時における、競技運営の継続優先順位と動作モードを定義する。

## 1. 優先順位 (Priority Order) (Step 4-1)
いかなる状況下でも、以下の順位で意思決定を行う。

1. **Tournament Continuity (大会継続)**: 試合の記録と進行を止めない。
2. **Human Authority (人間主権)**: システムが不明な場合は人間の審判に仰ぐ。
3. **Replay Preservation (歴史保護)**: 最低限、イベントログだけは物理的に保存する。
4. **Synchronization (同期)**: サーバーとの同期成功は、記録の成功より優先されない。
5. **UI Freshness (表示鮮度)**: スコアボードの更新遅延は、記録の遅延より許容される。

## 2. 縮退運転マトリクス (Degradation Matrix) (Step 4-2)

| 障害事象 | 動作モード | アクション |
| :--- | :--- | :--- |
| **ネットワーク断** | **Fail-open** | ローカルDBにイベントを蓄積。同期エラーを無視して進行。 |
| **Replay Drift 検知** | **Fail-closed** | 自動判定を停止。人間の手動入力モードへ強制移行。 |
| **Snapshot 破損** | **Recovery** | スナップショットを破棄し、イベントログから状態を再構築。 |
| **Governance 違反** | **Alert & Log** | 管理者へ通知。記録は継続するが、該当箇所を監査対象とする。 |

## 3. 部分的失敗の許容 (Partial Failure Rules) (Step 4-3)
- **Projection Failure ≠ Match Stop**: 観客用表示が止まっても、記録係の入力が可能なら試合を続行する。
- **Audit Persistence Prioritized**: 監査ログの書き込み失敗は、競技イベントの書き込みを妨げてはならない。