## 概要
## 変更影響分析 (Impact Analysis)
- [ ] Replay 互換性の維持 (Event Schema に変更はないか)
- [ ] UI / プレゼンテーション層の変更
- [ ] ドメインルールの変更

## 🛡️ Documentation Governance Checklist (Phase 7 必須要件)
> **⚠ 警告:** UIやルールを変更した場合、以下の更新がないPRはCIによって強制Fail（ブロック）されます。

- [ ] マニュアルのMarkdown（`docs/manuals/**/*.md`）を更新した
- [ ] スクリーンショット（`assets/manual_images/*.png`）を更新した
- [ ] リンク先（Manual IDや相互参照）に変更・リンク切れがないことを確認した
- [ ] （必要に応じて）`dart run tools/governance_lint/manual_indexer.dart` で検索インデックスを再生成した
- [ ] （必要に応じて）`dart run tools/manual_pdf_export/export_pipeline.dart` でPDFを再生成した

## 特記事項