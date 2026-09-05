# Screen ↔ Manual Mapping (画面・マニュアル対応表)

本ドキュメントは、アプリ内のUI画面（`.dart`）と、それを説明するマニュアルの識別子（`Manual ID`）、および対象となるユーザー層（`Audience`）の1対1の紐付けを定義する。

## 絶対不変ルール (Step 1-3)
Manual ID は将来の検索インデックス、アプリ内ルーティング、AI参照の「静的なキー」となるため、一度定義したID（例: `operate_match`）は変更してはならない（例: `match_manual_v2_final` 等のバージョン表記は厳禁）。

| Screen File | Manual ID | Audience | 対応ファイル |
| :--- | :--- | :--- | :--- |
| `viewer_home_screen.dart` | `viewer_home` | spectator | `viewer/viewer_home.md` |
| `viewer_match_screen.dart` | `viewer_match` | spectator | `viewer/viewer_match.md` |
| `viewer_team_match_status_screen.dart` | `viewer_team_status` | spectator | `viewer/viewer_team_match_status.md` |
| `program_viewer_screen.dart` | `viewer_program` | spectator | `viewer/viewer_program.md` |
| `viewer_official_record_screen.dart` | `viewer_official_record` | spectator | `viewer/viewer_official_record.md` |
| `viewer_bunaiksen_screen.dart` | `viewer_bunaiksen` | spectator | `viewer/viewer_bunaiksen.md` |
| `viewer_team_scoreboard_screen.dart` | `viewer_team_scoreboard` | spectator | `viewer/viewer_team_scoreboard.md` |
| `viewer_kachinuki_scoreboard_screen.dart` | `viewer_kachinuki` | spectator | `viewer/viewer_kachinuki_scoreboard.md` |
| `home_screen.dart` | `operate_home` | operator | `operator/home_guide.md` |
| `create_tournament_screen.dart` | `operate_create` | operator_admin | `operator/create_tournament.md` |
| `team_registration_screen.dart` | `operate_team` | operator_admin | `operator/team_registration.md` |
| `rule_config_panel.dart` | `operate_rules` | operator_admin | `operator/category_rules.md` |
| `setup_match_format_screen.dart` | `operate_setup_match` | operator_admin | `operator/setup_match.md` |
| `match_screen.dart` | `operate_match` | operator_recorder | `operator/match.md` |
| `bulk_rule_edit_dialog.dart` | `operate_bulk_rules` | operator_admin | `operator/bulk_rule_edit.md` |
| `team_match_status_screen.dart` | `operate_team_status` | operator | `operator/team_match_status.md` |
| `standings_screen.dart` | `operate_standings` | operator | `operator/standings.md` |
| `official_record_screen.dart` | `operate_record` | operator_admin | `operator/official_record.md` |
| `floating_match_dock.dart` | `operate_dock` | operator_recorder | `operator/dock_guide.md` |
| `program_management_screen.dart` | `operate_program` | operator_admin | `operator/program_management.md` |
| `bunaiksen_home_screen.dart` | `operate_bunaiksen` | operator | `operator/bunaiksen.md` |
| `master_management_screen.dart` | `operate_master` | operator_admin | `operator/master_management.md` |
| `settings_screen.dart` | `operate_settings` | operator_admin | `operator/settings.md` |
| `audit_log_screen.dart` | `operate_audit` | governance | `operator/audit_log.md` |
| `observability_dashboard_screen.dart`| `operate_observability`| system_admin | `recovery/observability_dashboard.md`|
| (現場トラブル・緊急時) | `operate_recovery` | operator / admin | `recovery/failure_catalog.md` |