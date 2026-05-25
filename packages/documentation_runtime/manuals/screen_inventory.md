# Screen Inventory & Metadata Table (画面棚卸しとメタデータ)

本ドキュメントは、Kendo Syncの全画面（Screen）を棚卸しし、運用知識（マニュアル）としての作成優先順位とアクセス対象者を定義する。

## 1. ドキュメント作成優先順位 (Documentation Tiers)
* **Tier 1 (最優先)**: 大会進行と記録の根幹。競技の進行に直結するため、最も高い精度でのドキュメント化が求められる。
* **Tier 2 (重要)**: 結果の集計や表示に関する画面。保護者や観客の満足度、およびスムーズな大会運営に寄与する。
* **Tier 3 (管理・監査)**: システムの根幹設定や、緊急時の監査・復旧に関する画面。

## 2. Screen Metadata Table

| Screen Name (dart) | Tier | 用途権限 | Operator対象 | Viewer対象 |
| :--- | :--- | :--- | :--- | :--- |
| **【Tier 1: 最優先】** | | | | |
| `match_screen` | Tier 1 | 記録係 | ✅ | - |
| `official_record_screen` | Tier 1 | 管理者・記録係 | ✅ | - |
| `create_tournament_screen` | Tier 1 | 管理者 | ✅ | - |
| `viewer_match_screen` | Tier 1 | 観客 | - | ✅ |
| **【Tier 2: 重要】** | | | | |
| `standings_screen` | Tier 2 | 管理者・記録係 | ✅ | - |
| `program_viewer_screen` | Tier 2 | 全員 | ✅ | ✅ |
| `program_management_screen`| Tier 2 | 管理者 | ✅ | - |
| `team_scoreboard_screen` | Tier 2 | 全員 | ✅ | - |
| `kachinuki_scoreboard_screen` | Tier 2 | 全員 | ✅ | - |
| `viewer_team_scoreboard_screen`| Tier 2 | 観客 | - | ✅ |
| `viewer_kachinuki_scoreboard_screen`| Tier 2 | 観客 | - | ✅ |
| **【Tier 3: 管理・監査】** | | | | |
| `observability_dashboard_screen`| Tier 3 | システム管理者 | ✅ | - |
| `audit_log_screen` | Tier 3 | システム管理者 | ✅ | - |
| `settings_screen` | Tier 3 | 管理者 | ✅ | - |
| **【その他・基盤機能】** | | | | |
| `start_screen` / `login_screen`| - | 全員 | ✅ | ✅ |
| `home_screen` | - | 全員 | ✅ | - |
| `bunaiksen_home_screen` | - | 記録係 | ✅ | - |
| `bunaiksen_setup_screen` | - | 管理者 | ✅ | - |
| `bunaiksen_official_record_screen`| - | 全員 | ✅ | - |
| `team_registration_screen` | - | 管理者 | ✅ | - |
| `setup_match_format_screen` | - | 管理者 | ✅ | - |
| `order_setup_screen` | - | 管理者 | ✅ | - |
| `master_management_screen` | - | 管理者 | ✅ | - |
| `rule_config_panel` | - | 管理者 | ✅ | - |
| `tournament_list_screen` | - | 管理者 | ✅ | - |
| `new_match_screen` | - | 管理者 | ✅ | - |
| `viewer_home_screen` | - | 観客 | - | ✅ |
| `viewer_official_record_screen`| - | 観客 | - | ✅ |