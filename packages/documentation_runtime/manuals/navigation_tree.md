# Documentation Navigation Tree (閲覧導線ツリー)

本ドキュメントは、Kendo OSの「観客・閲覧系（Viewer）」と「運営・記録系（Operate）」のマニュアル導線を厳格に分離し、アプリ内連携および目次構造を固定するものである。

---

## 📱 Viewer (観客・閲覧系)
一般の観客・保護者・選手がスマートフォン等からアクセスする導線。運営専用の操作やリカバリ手順は含めない。

```text
Viewer Home (観客ホーム)
 ├─ リアルタイム試合画面 (viewer_match)
 ├─ 団体戦チーム試合状況 (viewer_team_match_status)
 ├─ 大会プログラム・個人メモ (viewer_program)
 ├─ 試合結果・公式記録 (viewer_official_record)
 ├─ 部内戦・練習試合結果 (viewer_bunaiksen)
 ├─ 団体戦スコアボード (viewer_team_scoreboard)
 ├─ 勝ち抜き戦スコアボード (viewer_kachinuki_scoreboard)
 └─ よくある質問・FAQ (viewer_faq)
```

---

## 📋 Operate (運営・記録系)
大会運営者、記録係、審判向けの実務・管理・緊急対応導線。

```text
Operate Home (大会ホーム)
 ├─ 大会作成 (operate_create)
 ├─ チーム・選手登録 (operate_team)
 ├─ 部門ルール設定 (operate_rules)
 ├─ 試合作成 (operate_setup_match)
 ├─ 試合記録・タイマー操作 (operate_match)
 ├─ 一括ルール編集 (operate_bulk_rules)
 ├─ チーム試合状況 (operate_team_status)
 ├─ 成績表・順位表 (operate_standings)
 ├─ 大会記録・公式記録PDF/CSV出力 (operate_record)
 ├─ ドック機能・常設パネル (operate_dock)
 ├─ 大会プログラム管理 (operate_program)
 ├─ 部内戦管理 (operate_bunaiksen)
 ├─ 選手マスタ管理・新年度進級 (operate_master)
 ├─ システム設定 (operate_settings)
 ├─ 監査ログ・操作履歴 (operate_audit)
 ├─ 緊急復旧カタログ (operate_recovery)
 └─ よくある質問・FAQ (operator_faq)
```