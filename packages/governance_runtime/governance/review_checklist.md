# Governance-aware Code Review Checklist

「コードが動くか」ではなく「ドメイン哲学に違反していないか」を監査するためのチェックリストです。

## 1. 致命的な哲学違反の確認 (Fatal Governance Violations)
以下のいずれかに該当する場合、PRは直ちにリジェクトされます。
- [ ] **Replay Drift:** 過去のイベント履歴から導出される結果が 1 bit でも変わる変更（歴史破壊）を含んでいないか。
- [ ] **Hidden Mutable State:** `RuleModule` やドメイン層に暗黙のキャッシュや `static` な可変状態が隠されていないか。
- [ ] **Projection Truth化:** UIの表示用ロジック（Projection）が、ドメインの「真実（Truth）」を上書き・再定義していないか。
- [ ] **Silent Correction:** ユーザーの明示的承認なしに、システムが勝手にドメインイベントを補正・修正していないか。

## 2. Risk Classification (リスク分類)
PRの性質に応じて、以下のリスクレベルをラベリングしてください。
- **Critical:** `ruleVersion` の変更、コアエンジン（`RuleResolver`等）の改修、イベント構造の変更。
  - *要求:* 厳格な Replay Regression Test の通過と Architect の承認。
- **Medium:** 新しい `RuleModule` の追加、緊急復旧フローの追加。
  - *要求:* 新規ルールの単体テスト、既存ルールへの非干渉の証明。
- **Low:** UIコンポーネントのみの修正、リファクタリング（ロジック変更なし）。
  - *要求:* 標準的な CI の通過。