# 📸 画面キャプチャ・図解対応表 (Image Mapping)

本ドキュメントは、Kendo Sync のすべてのスクリーンショットに対する命名規約と、画像内に必須となる注釈（赤枠・矢印）の要件を定義するものである。
画像を更新する際は、この表の要件を満たした上で、統一されたパス（例: `images/operator/...`）に配置すること。

## 運営・記録画面 (Operate)

| 画像 (パス/ファイル名) | 対応画面 (.dart) | 必須注釈（赤枠・矢印・番号等） |
| :--- | :--- | :--- |
| `images/operator/team_registration/add_team_button.png` | `team_registration_screen.dart` | ①【＋ チーム追加】ボタン位置（青枠）、②入力欄 |
| `images/operator/match/operate_match_main.png` | `match_screen.dart` | ①タイマー、②得点ボタン、③【↩️ Undo】ボタン位置 |
| `images/operator/match/operate_match_danger.png` | `match_screen.dart` | 危険操作：【確定】長押しボタン（赤枠） |
| `images/operator/create/create_tournament.png` | `create_tournament_screen.dart` | ①大会名入力欄、②ルール設定、③保存ボタン |
| `images/operator/record/official_record_main.png` | `official_record_screen.dart` | ①勝敗表示、②【PDF出力】ボタン、③【記録の修正】への導線 |
| `images/operator/audit/audit_log_view.png` | `audit_log_screen.dart` | ①変更時間、②操作した人、③変更内容のリスト |
| `images/recovery/dashboard/sync_status_alert.png` | `observability_dashboard_screen.dart` | 同期状態の異常（赤文字・未送信データ）に目立つ赤枠 |

## 観客・閲覧画面 (Viewer)

| 画像 (パス/ファイル名) | 対応画面 (.dart) | 必須注釈（赤枠・矢印・番号等） |
| :--- | :--- | :--- |
| `images/viewer/home/viewer_home_main.png` | `viewer_home_screen.dart` | ①進行中の試合、②大会結果ボタン |
| `images/viewer/match/viewer_match_view.png` | `viewer_match_screen.dart` | ①残り時間、②選手名、③得点、④反則、⑤勝敗マーク |
| `images/viewer/team/viewer_team_score.png` | `viewer_team_scoreboard_screen.dart` | ①チーム名、②各選手の得点、③現在の勝敗数 |
| `images/viewer/kachinuki/viewer_kachinuki_score.png` | `viewer_kachinuki_scoreboard_screen.dart` | ①対戦中の選手、②連勝数、③残りの控え選手 |

## 注釈ルール再確認 (Step 3-3)
- **青枠**: 通常のボタン位置、入力欄
- **赤枠**: 危険操作（確定、削除）、同期エラー等の異常状態
- すべての枠のそばには「丸数字（①、②...）」を必ず添えること。