# Screen Inventory & Metadata Table (画面棚卸しとメタデータ)

本ドキュメントは、Kendo OSの全画面（Screen）を棚卸しし、運用知識（マニュアル）としての作成優先順位とアクセス対象者を定義する。

## 1. ドキュメント作成優先順位 (Documentation Tiers)
* **Tier 1 (最優先)**: 試合進行・記録・閲覧の根幹画面。競技の進行に直結するため、最も高い精度でのドキュメント化が求められる。
* **Tier 2 (重要)**: ルール設定、チーム状況、プログラム、ドック、部内戦、公式記録出力などの主要機能画面。
* **Tier 3 (管理・監査)**: システム設定、選手マスタ管理、監査ログ、緊急時復旧に関する管理画面。

## 2. Screen Metadata Table

| Screen Name (dart) | Tier | 用途権限 | Operator対象 | Viewer対象 | 対応マニュアル |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **【Tier 1: 最優先】** | | | | | |
| `match_screen` | Tier 1 | 記録係 | ✅ | - | `operator/match.md` |
| `viewer_match_screen` | Tier 1 | 観客・保護者 | - | ✅ | `viewer/viewer_match.md` |
| `home_screen` | Tier 1 | 全員 | ✅ | - | `operator/home_guide.md` |
| `viewer_home_screen` | Tier 1 | 観客・保護者 | - | ✅ | `viewer/viewer_home.md` |
| `create_tournament_screen` | Tier 1 | 大会管理者 | ✅ | - | `operator/create_tournament.md` |
| `official_record_screen` | Tier 1 | 大会管理者・記録係 | ✅ | - | `operator/official_record.md` |
| **【Tier 2: 重要】** | | | | | |
| `rule_config_panel` (CategoryRules) | Tier 2 | 大会管理者 | ✅ | - | `operator/category_rules.md` |
| `setup_match_format_screen` / `new_match_screen` | Tier 2 | 大会管理者・記録係 | ✅ | - | `operator/setup_match.md` |
| `bulk_rule_edit_dialog` | Tier 2 | 大会管理者 | ✅ | - | `operator/bulk_rule_edit.md` |
| `team_match_status_screen` | Tier 2 | 全員 | ✅ | - | `operator/team_match_status.md` |
| `viewer_team_match_status_screen` | Tier 2 | 観客・保護者 | - | ✅ | `viewer/viewer_team_match_status.md` |
| `floating_match_dock` (Dock) | Tier 2 | 記録係・管理者 | ✅ | - | `operator/dock_guide.md` |
| `program_management_screen` | Tier 2 | 大会管理者 | ✅ | - | `operator/program_management.md` |
| `program_viewer_screen` | Tier 2 | 観客・保護者 | - | ✅ | `viewer/viewer_program.md` |
| `standings_screen` | Tier 2 | 大会管理者・記録係 | ✅ | - | `operator/standings.md` |
| `team_registration_screen` | Tier 2 | 大会管理者 | ✅ | - | `operator/team_registration.md` |
| `bunaiksen_home_screen` / `bunaiksen_setup_screen` | Tier 2 | 記録係・指導者 | ✅ | - | `operator/bunaiksen.md` |
| `viewer_bunaiksen_screen` | Tier 2 | 部員・保護者 | - | ✅ | `viewer/viewer_bunaiksen.md` |
| `team_scoreboard_screen` | Tier 2 | 全員 | ✅ | - | `operator/team_match_status.md` |
| `viewer_team_scoreboard_screen` | Tier 2 | 観客 | - | ✅ | `viewer/viewer_team_scoreboard.md` |
| `viewer_kachinuki_scoreboard_screen` | Tier 2 | 観客 | - | ✅ | `viewer/viewer_kachinuki_scoreboard.md` |
| `viewer_official_record_screen` | Tier 2 | 観客・保護者 | - | ✅ | `viewer/viewer_official_record.md` |
| **【Tier 3: 管理・監査・復旧】** | | | | | |
| `master_management_screen` | Tier 3 | 道場・部活動管理者 | ✅ | - | `operator/master_management.md` |
| `settings_screen` | Tier 3 | 大会管理者 | ✅ | - | `operator/settings.md` |
| `audit_log_screen` | Tier 3 | 監査係・管理者 | ✅ | - | `operator/audit_log.md` |
| `observability_dashboard_screen` | Tier 3 | システム管理者 | ✅ | - | `recovery/observability_dashboard.md` |
| (緊急復旧フロー) | Tier 3 | 現場記録係・管理者 | ✅ | - | `recovery/failure_catalog.md` |