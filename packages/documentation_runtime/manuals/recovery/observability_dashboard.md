---
ai_metadata:
  screen: observability_dashboard_screen
  role: operator_admin
  risk: high
  governance_level: L3
  offline_supported: true
---
[総合ホーム](../manual_index.md) &gt; [緊急復旧ガイド](failure_catalog.md) &gt; 監視ダッシュボード

# 監視ダッシュボード (Observability)

システム全体の健康状態を監視し、異常を早期に発見するための管理者専用画面です。

## 同期遅延とは {#what-is-sync-delay}
あるタブレットで入力した点数が、本部や観客席の画面に反映されるまでの遅れのことです。これが長くなっている場合は、会場のWi-Fiルーターに問題が発生している可能性があります。

## Event Queue（同期待ち）とは {#what-is-event-queue}
オフライン時に端末内に溜まっている「まだ送信できていない記録の数」です。これが0になれば、すべてのデータが安全に本部へ届いたことを意味します。

## 試合履歴の再構築（Replay）とは {#what-is-replay}
過去の操作履歴から、現在の正しい点数を計算し直す機能です。データがおかしくなった場合の最終的な復旧手段です。（※ビデオ判定のことではありません）

## 異常検知とは {#anomaly-detection}
システムが「通常ではあり得ない操作」を自動で見つける機能です。

## 何が赤なら危険か {#red-alert}
画面上の **「未送信データ数」** が赤く表示され続けている場合は危険です。端末が完全にネットワークから切り離されており、そのままタブレットの電源が切れると記録が失われるリスクがあります。速やかに紙の記録と併用してください。