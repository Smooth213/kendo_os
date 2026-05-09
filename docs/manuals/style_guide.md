# Documentation Style Guide

ドキュメントを「AI検索基盤」および「自動PDF生成」に最適化するための厳格な執筆ルール。

## 1. 見出しルール (Heading Rules)
- `#` (H1): 画面名または大項目にのみ使用（1ファイル1つのみ）。
- `##` (H2): 「概要」「使用タイミング」「手順」「注意事項」などのセクション分割に使用。
- 見出しの中にリンクや画像を埋め込まないこと。

## 2. スクリーンショット命名規則 (Screenshot Naming)
- 保存先: `docs/manuals/images/`
- 命名フォーマット: `[画面名]_[連番]_[状態].png`
- ⭕️ 良い例: `create_tournament_01_initial.png`
- ❌ 悪い例: `IMG_1234.png`, `スクリーンショット.png`

## 3. 用語統一 (Terminology)
- 「記録係」「スコアラー」など揺れやすい用語は `docs/domain/glossary.md` に従い統一する。
- 観客向け画面は「Viewerモード」と呼称する。

## 4. 禁止表現 (Prohibited Expressions)
- ❌ 「たぶん」「〜だと思います」「〜するはずです」等の推測表現。
- ❌ プラットフォーム依存の操作（例: 「ホームボタンを押して」等。端末によって異なるため）。

## 5. AI検索最適化規則 (AI Search Optimization)
- 各Markdownファイルの先頭に、AIが文脈を解釈するためのメタデータ（Frontmatter）を記述すること。
- 手順（Step）は必ず番号付きリスト `1. 2. 3.` を使用し、操作の因果関係を明確にすること。