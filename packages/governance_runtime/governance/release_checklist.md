# 本番リリース 承認チェックリスト (Production Release Checklist)

Kendo Syncの新しいバージョンを実際の大会や稽古に投入（リリース）する際は、以下の要件をすべて満たしていることをガバナンス監査官として確認すること。

## 1. CI / 自動監査 (Automated Audits)
- [ ] 全てのUnit / Widget / Integration Test (126件以上) がPASSしている。
- [ ] `Phase 0`: Documentation Validator がPASSし、Markdownの構造に欠損がない。
- [ ] `Phase 7`: Doc Sync Validator がPASSし、未ドキュメントのコード変更が存在しない。

## 2. ドキュメントの射影 (Documentation Projection)
- [ ] `Phase 4`: MkDocsによる最新のPDFマニュアルが `generated/pdf/` に出力されている。
- [ ] 出力された「クイックガイド」を印刷し、当日現場に持参する準備ができている。
- [ ] `Phase 6`: AI Search用のインデックス（チャンクデータ）が最新状態に更新されている。

## 3. 運用検証 (Operational Validation)
- [ ] `docs/testing/operational_validation_protocol.md` に基づく「体育館テスト」「高齢者テスト」「カオステスト」を直近1ヶ月以内に実施し、致命的な問題がないことを確認した。

---
※ すべてのチェックが完了した場合のみ、本番環境での稼働を許可する。