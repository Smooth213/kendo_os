# Testing Index

品質保証の基準、自動テストの運用、およびリプレイの整合性チェックに関するドキュメントです。

## ✅ 品質統治 (Testing Governance)
- **[Rule Testing Standard](./rule_testing_standard.md)** - ルール追加時に必須となるテスト項目（Unit, Replay, Property-based, Chaos）と品質基準
- **[Operational Validation Protocol](./operational_validation_protocol.md)** - 現場運用検証（体育館テスト、高齢者UIテスト、耐障害カオステスト）プロトコル

## 🛡 自動監査パイプライン (Automated Governance Pipeline)
- **ガバナンス全自動監査**: `python3 scripts/run_all_governance.py` による全40条項の完全適合監査
- **局所回帰テスト**: `flutter test <対象テストファイルパス>` による高速・局所検証