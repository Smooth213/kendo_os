# Screen ↔ Manual Mapping (画面・マニュアル対応表)

本ドキュメントは、アプリ内のUI画面（`.dart`）と、それを説明するマニュアルの識別子（`Manual ID`）、および対象となるユーザー層（`Audience`）の1対1の紐付けを定義する。

## 絶対不変ルール (Step 1-3)
Manual ID は将来の検索インデックス、アプリ内ルーティング、AI参照の「静的なキー」となるため、一度定義したID（例: `operate_match`）は変更してはならない（例: `match_manual_v2_final` 等のバージョン表記は厳禁）。

| Screen File | Manual ID | Audience |
| :--- | :--- | :--- |
| `viewer_home_screen.dart` | `viewer_home` | spectator |
| `viewer_match_screen.dart` | `viewer_match` | spectator |
| `home_screen.dart` | `operate_home` | operator |
| `create_tournament_screen.dart` | `operate_create` | operator_admin |
| `match_screen.dart` | `operate_match` | operator_recorder |
| `official_record_screen.dart` | `operate_record` | operator_admin |
| `audit_log_screen.dart` | `operate_audit` | governance |
| (システム・ネットワーク障害時) | `operate_recovery` | operator / admin |