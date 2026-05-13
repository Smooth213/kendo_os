# 🔄 Match Lifecycle FSM (状態遷移定義)

**Status: LOCKED (Phase 1)**
本ドキュメントは `MatchStateMachine` の唯一の真実（Source of Truth）です。これ以外の状態遷移は「Impossible State（状態破綻）」とみなされ、システムによって拒絶（`InvalidStateException`）されます。

## 状態遷移マトリクス

| 現在の状態 (Current State) | 発生イベント (Event) | 次の状態 (Next State) | 備考 |
| :--- | :--- | :--- | :--- |
| `notStarted` | `playersReady` | `ready` | 両選手がコートに入場 |
| `notStarted` | `startMatch` | `inProgress` | (強制開始用) |
| `waitingForPlayers`| `playersReady` | `ready` | |
| `ready` | `startMatch` | `inProgress` | 「はじめ」の宣告 |
| `inProgress` | `pause` | `paused` | 「やめ」の宣告 |
| `inProgress` | `timeUp` | `completed` / `encho` | 規定時間終了（同点の場合は延長へ） |
| `inProgress` | `decideWinner` | `completed` | 2本先取などで決着 |
| `paused` | `resume` | `inProgress` | 試合再開 |
| `encho` | `addScore` | `completed` | 延長戦での一本（サドンデス決着） |
| `encho` | `pause` | `paused` | 延長中の「やめ」 |
| `hanteiPending` | `approve` | `completed` | 判定結果の確定 |
| `completed` | `undo` | `inProgress` | 勝敗の取り消し（再開） |
| `fusen` | `undo` | `inProgress` | 不戦勝の取り消し |

## 禁止事項 (Forbidden Mutations)
- `completed` 状態からの `addScore`（スコア追加）は無効。
- `String status = "finished"` のような文字列への直接代入は禁止。必ず `transition()` を介すこと。