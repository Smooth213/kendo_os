# 🛡️ Stage 2 β Release Checklist (最終ガバナンス監査仕様)

本ドキュメントは、Kendo Sync（kendo_os）の Stage2 βリリース前に確認・執行すべき最終チェックリストです。

## 最終テスト要件

リリース前に必ず以下のコマンドを実行し、すべてのテスト（合計227件の防衛網）がエラーおよび警告数「0」で完全にパスすることを確認してください。

- [x] `flutter test` (227件の全自動テスト要塞の通過確認)
- [x] `flutter test --coverage`
- [x] `flutter test test/integration/` (Chaos & Fuzzing suite)
- [x] `test/widget/internal_metrics_hidden_test.dart` (安心日本語表現の検証)
- [x] `test/widget/ai_feature_hidden_test.dart` (AI機能封鎖の検証)
- [x] `test/integration/stage2_rule_lock_test.dart` (Rule DSL編集UIの隠蔽および外部インポート拒否の検証)

## 最終公開条件 (Release Gates)

以下の条件がすべて満たされている場合のみ、Stage 2 β の公開が可能となります。

| 条件 | 必須 | 状態 |
| :--- | :---: | :---: |
| replay deterministic (10,000回ファジング耐性) | YES | ✅ |
| DateTime.now 0件 (TimeSource一元化) | YES | ✅ |
| corrupted state安全化 (自動フォールバックレジリエンス) | YES | ✅ |
| timeline replay保証 | YES | ✅ |
| AI CI enforcement (AI Runtime完全封鎖) | YES | ✅ |
| showRuleDslEditor == false (編集UI完全隠蔽) | YES | ✅ |
| chaos pass | YES | ✅ |

上記のすべてのテストと条件がクリアされた時点で、Stage 2 β公開の手続きに進むことができます。