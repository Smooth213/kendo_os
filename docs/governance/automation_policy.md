# Automation Policy (ガバナンス自動化方針)

定義された統治ルールが遵守されているかを、自動テストおよび CI プロセスによって監視・保証する仕組みを定義します。

## 1. Documentation Lint & Link Validation
- **ADR Link Integrity:** `adr/index.md` から各 ADR ファイルへのリンク、および ADR 間の依存関係（Dependency Map）が有効であることをチェックします。
- **Taxonomy Check:** ドキュメントが `Constitution` で定義されたディレクトリ構造に正しく配置されているかを確認します。

## 2. Rule & Replay CI (継続的整合性保証)
- **Replay Regression CI:** PR（プルリクエスト）作成時に、過去の全大会ゴールデンデータに対するリプレイテストを自動実行します。勝敗判定に 1 bit でも変化があれば、マージをブロックします。
- **Rule Determinism Check:** 静的解析およびプロパティベーステストにより、ルール内に `DateTime.now()` や `Random()` などの非決定論的な命令が混入していないか自動検知します。

## 3. Governance Drift Detection
- ドキュメントの最終更新から一定期間が経過した、あるいは実装コードのみが更新されて対応するドキュメント（Architecture/ADR）が更新されていない「ガバナンスの乖離（Drift）」を検知・警告します。