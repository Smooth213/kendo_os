# Documentation Runtime Architecture (ドキュメント実行基盤)

**制定日: 2026年5月10日**

本ドキュメントは、Kendo Syncにおける「取扱説明書」および「運用知識」のアーキテクチャを定義する。

## 1. 最重要思想 (Core Philosophy)
**「取説を後付け成果物にしない」**
Kendo Syncにおいて、Documentation（ドキュメント）は単なる解説書ではなく、**Operational Runtime（運用実行環境）の一部**である。
我々は「取説を書く」のではなく、**「運用知識を実装する」**。

## 2. The Single Source of Truth Pipeline
システムは以下のパイプラインを通じて、単一の真実（Markdown）からすべての運用知識を派生させる。

1. **Code (実装)**: Flutter UI / Domain Rulesの変更。
2. **Governance (CI統制)**: `doc_sync_validator.dart` がコード変更に伴うMarkdownの更新を強制（未更新はマージブロック）。
3. **Markdown Truth (真実の源泉)**: `docs/manuals/` に記述されたプレーンテキスト。
4. **PDF Projection (射影出力)**: MkDocsにより `generated/pdf/` へ自動コンパイルされ、現場（体育館）の紙として配備される。
5. **Flutter Help (組み込みヘルプ)**: アプリ内に同梱され、オフライン環境でも `flutter_markdown` 経由で検索・閲覧が可能。
6. **AI Search (エージェント)**: チャンク分割とベクトル化を経て、自然言語による問い合わせに回答する基盤。
7. **Operational Recovery (現場復旧)**: カオステスト（Wi-Fi断・電源喪失）に裏付けられた紙運用からのReplay手順。

## 3. 運用不変条件 (Operational Invariants)
- **UIが変われば、ドキュメントも変わる。** (CI保証)
- **ルールが変われば、ガバナンスも変わる。** (CI保証)
- **いかなるトラブル時も、マニュアルの指示（Replay）により歴史は1 bitも失われない。**