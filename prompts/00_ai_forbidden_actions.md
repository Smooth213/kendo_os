# AI Forbidden Actions (システム絶対制約)

AIアシスタントがコードを生成・修正する際は、以下の制約を**必ず**守ってください。違反したコードを出力することは固く禁じられます。

- 🚫 **No `DateTime.now()`**: 時刻依存の処理は、代わりに `RuleContext` 経由の `TimeSource` を使用すること。
- 🚫 **No IO**: `RuleModule` 内でのファイル、ネットワーク、データベースへのアクセスは一切禁止。
- 🚫 **Replay compatibility required**: 既存のイベント履歴（ゴールデンデータ）から導出される結果を 1 bit も変えないこと。
- 🚫 **No Global Mutable State**: `static mutable` や暗黙のシングルトンを作成しないこと。
- 🚫 **No Silent Correction**: ユーザーの明示的な確認なしに、システムが勝手にドメインイベントを補正する処理を書かないこと。