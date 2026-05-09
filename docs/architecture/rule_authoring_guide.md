# Rule Authoring Guide (ルール作成ガイド)

本システムに新しいルールモジュールを追加する際の手順と制約を定義します。

## 1. 実装の原則
新しいルールクラスを作成する際は、`adr-001` の制約に基づき以下を厳守してください。

- **Stateless:** クラス内部に変数を持たない。
- **Pure Function:** `apply(RuleContext)` の戻り値は引数のみに依存する。
- **No IO:** DBアクセスやネットワーク通信を行わない。
- **Deterministic:** 評価順序や時刻（DateTime.now()）に依存しない。

## 2. 追加のステップ
1. **インターフェースの選択:** `ScoringRule`, `VictoryRule`, `TimeRule`, `HansokuRule` のいずれかを実装する。
2. **RuleModule の作成:** `lib/domain/rules/` 内に独立したクラスとして実装する。
3. **Resolver への登録:** `RuleResolver` に構築ロジックを追加する。
4. **テストの記述:** ユニットテストおよび `Chaos Test` への組み込み。

## 3. 禁止事項
- `MatchModel` のプロパティを直接書き換えること。
- ルール内部で `Random` クラスを使用すること。
- UIの表示（色やテキスト）に依存したロジックを含めること。