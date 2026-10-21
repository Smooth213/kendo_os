# Architecture Index

システム設計、データフロー、およびコンポーネント間の依存関係に関するドキュメントです。

## 📖 ルール統治 (Rule Governance)
- **[Rule Authoring Guide](./rule_authoring_guide.md)** - 新しいルールを追加するための開発者向けガイド
- **[Conflict Resolution Policy](./conflict_resolution_policy.md)** - ルール間の競合解決ルール

## ⏪ 履歴統治 (Replay Governance)
- **[Replay Compatibility Policy](./replay_compatibility_policy.md)** - 歴史的再現性を維持するためのバージョン管理ルール

## 🌐 データ同期・クラウド連携 (Sync & Cloud Governance)
- **[Sync Conflict Policy](./sync_conflict_policy.md)** - オフライン/オンライン間のデータ競合調停方針
- **[Sync Scope Definition](./sync_scope_definition.md)** - クラウド同期対象とローカル閉塞データの境界定義
- **[Firestore Public Schema](./firestore_public_schema.md)** - 公開配信用 Firestore スキーマ定義

## 🏗 状態管理・構造統治 (State & Structure Governance)
- **[Provider Dependency Map](./provider_dependency_map.md)** - Riverpod Provider の単方向依存階層と循環参照禁止ルール
- **[Documentation Runtime](./documentation_runtime.md)** - ドキュメントと実行時知識（マニュアル・AI検索）の統合基盤
- **[Rule Package Spec](./rule_package_spec.md)** - 将来の外部ルール配信・DSL化に向けた互換性と安全性の定義