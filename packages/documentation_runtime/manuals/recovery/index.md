---
ai_metadata:
  screen: all_screens
  role: operator_recorder
  risk: high
  governance_level: L3
  offline_supported: true
---
[総合ホーム](../manual_index.md) > 障害復旧・監査マニュアル

# 障害復旧・監査マニュアル (Recovery & Audit Manual)

体育館現場での通信遮断、端末トラブル、操作ミス、または不正・疑義発生時の対応手順と復旧カタログです。

---

## 現場障害復旧カタログ
- [🚨 現場障害対応・復旧カタログ (Failure Catalog)](./failure_catalog.md)
  - ネットワーク完全断絶（オフライン継続入力と自動再送）
  - 端末熱暴走・バッテリー枯渇（別端末での即時引き継ぎ）
  - 誤確定・誤入力のUndo/再開手順
  - WebSocket/Live切断と再接続

---

## 監査とデータ整合性
- [📋 監査ログ・操作履歴マニュアル](../operator/audit_log.md)
  - 打突・反則・Undo全イベントのタイムスタンプ照合
  - 改ざん防止と疑義発生時の事実確認
- [🛡️ 現場チェックリストと運用ガイド](../quickstart/operator_1pager.md)