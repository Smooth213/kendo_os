# Kendo OS マニュアル改訂・スクリーンショット撮影台帳（v1.1.0 準拠）

本ドキュメントは、アプリのFlutterソースコードを直接精査し、**バージョン 1.1.0（`pubspec.yaml`: `1.1.0+2` / `AppLegalTexts.appVersion`: `v1.1.0`）** の最新仕様に基づいたマニュアル原稿（Markdown）の修正点および配布用PDFの改訂指示（UI要素、差分、必要スクショと差し替え先）を記録する公式台帳です。

---

## 📌 最新仕様アップデート履歴（v1.1.0 改訂反映 / 2026/11/12）
* **【道場別PIN・セキュリティ＆引き継ぎ基盤（v1.1.0 新機能）】**:
  - **道場入室PIN（合言葉）**: 新規道場作成時・既存未保護道場参加時の入室PIN設定、および既存道場入室時のPIN認証ボトムシート（`RoomJoinPinDialog`）を追加
  - **道場別カスタムロールPIN**: 初期PIN（Admin: `9999` / Operator: `2468` / Recorder: `1357` / Viewer: 不要）に加え、管理者による道場ごとの4桁PIN個別変更に対応
  - **道場セキュリティ・PIN管理（設定画面・管理者限定）**: Admin本人確認後の現在PIN確認（初期マスク表示＋目アイコンで切替）・変更、および代表者Googleアカウント登録・代替わり引き継ぎ（最大5名：`DojoOwnerAccountsCard`）を実装
  - **PIN初期化・復旧**: PIN忘れ時に登録済み代表者Googleアカウントの本人確認で初期化・再設定できるボトムシート（`DojoPinRecoverySheet`）を追加
* **【1大会限定 観戦QR共有の有効期限制御（v1.1.0 新機能）】**:
  - 大会ごとのトークン付き観戦共有リンクと、有効期限（24時間 / 7日間 / 無期限 / 停止）を即座に切り替えられる制御UI（`ViewerShareExpirySelector`）を追加
* **【選手マスタ管理の年度更新＆卒業・OB/OG名簿（v1.1.0 新機能）】**:
  - 卒業ライン選択・例外残留設定・卒業生アーカイブを備えた「新年度の一括進級シート」（`MasterAnnualPromotionSheet`）へ刷新
  - 管理メニュー（`...`）内に「卒業・OB/OG名簿」（`MasterGraduatedPlayersSheet`：閲覧・現役復帰）を専用シートとして新設し、選手登録の在籍区分（現役 / 卒業・OB/OG）や「卒業生を含める」フィルターを追加
* **【剣道公式スコア表示・記録仕様の正本化（v1.1.0）】**:
  - `docs/domain/kendo_score_display_spec.md` に準拠し、3本勝負1本目（先取）の反則取得への丸囲み（`◯反`）、不戦勝の通常丸（`◯`）統一（二重丸 `◎` 是正）、反則警告（`△`）の左下独立・最大4個累積表示を反映
* **【UI・デザインシステム最新化（v1.1.0 継続反映）】**:
  - 全画面のボタン・入力フォームのカプセル型（Stadium/Pill形状）完全統一、iOSメモ風 浮遊カプセル型スワイプアクション（`AppSlidableAction`）
  - スタート画面の 19.5:9 画面での非スクロール全体表示調整、および大会ホーム・部内戦ホームのAppBar観戦プレビューアイコンを `Icons.preview_rounded` へ変更
  - 設定画面・スタート画面「サポート・規約・情報」セクション（オフライン規約ダイアログ・Googleフォーム外部起動）、プログラムPDF自動軽量化（3MB以上・検索性維持）、公式記録PDFのルール要約印字（`PdfRuleFormatter`）、検索キーワード黄色ハイライト（`AppHighlightText`）、全画面Pull-to-Refresh耐障害導線を網羅

---

## 進捗サマリー
* 対象バージョン: **v1.1.0（`1.1.0+2`）**
* 全ステップ数: 27ステップ（うち総合取扱説明書掲載対象: **25ステップ** ※Step 18「監査ログ」・Step 20「監視ダッシュボード」は Stage 2 β 非表示仕様のため総合取扱説明書から除外）
* 完了ステップ: **27 / 27 (全8フェーズ・全27ステップ v1.1.0 実コード照合・改訂反映済み 100% 完了 🎉)**
* 達成状況:
  - Phase 0: 基本概念・初期設定・権限 (Step 1/27) 🟢 v1.1.0反映済
  - Phase 1: 事前準備・選手マスタ・大会作成 (Step 2〜5/27) 🟢 v1.1.0反映済
  - Phase 2: 試合作成・オーダー・ホーム (Step 6〜8/27) 🟢 v1.1.0反映済
  - Phase 3: 試合進行・スコア記録・通常ドック (Step 9〜11/27) 🟢 v1.1.0反映済
  - Phase 4: 部内戦・練習試合・部内戦ドック (Step 12〜13/27) 🟢 v1.1.0反映済
  - Phase 5: 結果集計・公式記録・PDF出力 (Step 14〜16/27) 🟢 v1.1.0反映済
  - Phase 6: システム設定・障害復旧 (Step 17, 19/27 ※Step 18, 20 は Stage 2 β 非表示につき取説除外) 🟢 v1.1.0反映済
  - Phase 7: 観客・保護者用 Viewer マニュアル (Step 21〜24/27) 🟢 v1.1.0反映済
  - Phase 8: クイックガイド・FAQ・最終総点検 (Step 25〜27/27) 🟢 v1.1.0反映済

---

## 🗺️ 総合取扱説明書（Google スライド）章・ページ再構成マップ（方針B：v1.1.0 準拠）
既存の Google スライド「Kendo_Sync 総合取扱説明書（全42枚）」をベースに、未掲載ページの追加・Stage 2 β 非表示機能の除外・旧称（`Kendo OS` → `Kendo Sync` / `KendoSync`）および FAQ 参照ページ番号の整合を行う再構成案です。

| 再構成後の章 | 収録内容（対応 Step） | 現行スライドとの対応・改訂方針 |
| :--- | :--- | :--- |
| **表紙・目次** | 表紙（`v1.1.0` 明記）、目次 1〜3 | 現行 Slide 1〜4 を新章構成・新ページ番号に合わせて全面更新 |
| **第1章：基本概念・初期設定・権限** | Kendo Sync とは、二重保存・Pull-to-Refresh、道場ID・入室PIN、4つの権限・PIN復旧（Step 1） | 現行 Slide 5〜8 を更新＋「道場入室PIN」「PIN初期化・復旧」を追加 |
| **第2章：選手マスタ管理** | 一覧・スワイプ/長押し、選手登録・在籍区分、新年度一括進級シート、卒業・OB/OG名簿、バックアップ（Step 2） | 現行 Slide 9〜12 を更新＋「新年度一括進級シート」「卒業・OB/OG名簿」を追加 |
| **第3章：通常試合モードの運営準備** | 新規大会作成、チーム登録、部門ルール設定、試合作成・オーダー、一括ルール変更、大会ホーム・観戦QR有効期限（Step 3〜8） | 現行 Slide 13〜21 を更新＋「部門ルール設定」「一括ルール変更」「観戦QR有効期限」を追加 |
| **第4章：通常試合の進行・ドック・結果出力** | 試合記録・タイマー・Undo・終了、団体戦状況/スコアボード、通常大会ドック、リーグ集計・公式記録・PDF/LINE共有、順位表、プログラム管理・手書き（Step 9〜11, 14〜16） | 現行 Slide 22〜28 を更新＋「団体戦状況/スコアボード」「通常大会ドック」「順位表」「プログラム管理・手書き」を追加 |
| **第5章：部内戦モードの運営** | カレンダー・4大モード・待機列・無限勝ち抜き、部内戦専用ドック・試合数計算・ジグル並び替え（Step 12〜13） | 現行 Slide 29〜33 を更新＋「部内戦専用ドック・試合数計算・ジグル」を追加 |
| **第6章：共有・通信復旧・設定・通知** | QR共有・有効期限、オフライン/破損隔離復旧・YES/NO診断、システム設定・道場PIN管理・代表者引き継ぎ、プッシュ通知・アプリ内お知らせ（Step 17, 19 ＋ 現行 Slide 41〜42 編入） | 現行 Slide 34〜37 ＋ Slide 41〜42 を統合更新＋「道場PIN管理・代表者引き継ぎ」「破損データ隔離/診断チャート」を追加（※Step 18 監査ログ・Step 20 監視ダッシュボードは **Stage 2 β 非表示のため除外**） |
| **第7章：観客・保護者用 Viewer ガイド** | 観客ホーム・1大会限定QR、リアルタイムスコアボード（縦/横）・団体戦、チーム進捗・プログラム個人ペン・検索、公式記録・部内戦・勝ち抜き戦速報（Step 21〜24） | **新規独立章として追加** |
| **第8章：クイックガイド・FAQ・付録** | 机上クイックガイド、FAQ（新設Q&A＋参照ページ番号是正）、当日運営タイムライン、タイムライン仕様・免責事項・KendoSync 窓口（Step 25〜27） | 現行 Slide 38〜40 を更新＋「机上クイックガイド」を追加し、`Kendo OS` / `dojo-support@kendo-os.org` を現行表記へ統一 |

---

## 【Phase 0: 基本概念・初期設定・権限】（PDF第1章 P5〜P8）

### 【Step 1/27】基本概念・初期設定・道場ID・入室PIN・4つの権限
* **対象マニュアル**: `packages/documentation_runtime/manuals/operator/index.md`（または新設 `operator/initial_setup.md`）
* **コード根拠**:
  * 役割選択画面: [`lib/features/auth/presentation/screens/role_select_screen.dart:L20-L418`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/auth/presentation/screens/role_select_screen.dart#L20-L418)
  * PIN認証画面: [`lib/features/auth/presentation/screens/pin_auth_screen.dart:L26-L481`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/auth/presentation/screens/pin_auth_screen.dart#L26-L481)
  * マスターPIN・道場別PIN検証: [`lib/security/pin_guard.dart:L9-L44`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/security/pin_guard.dart#L9-L44)
  * 道場ID入力シート: [`lib/shared/widgets/room_join_qr_dialog.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/shared/widgets/room_join_qr_dialog.dart)
  * 道場入室PIN設定・認証シート: [`lib/shared/widgets/room_join_pin_dialog.dart:L18-L413`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/shared/widgets/room_join_pin_dialog.dart#L18-L413)
  * 入室フロー制御: [`lib/shared/widgets/room_join_flow_coordinator.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/shared/widgets/room_join_flow_coordinator.dart)
  * 代表者GoogleによるPIN初期化シート: [`lib/features/auth/presentation/widgets/dojo_pin_recovery_sheet.dart:L35-L446`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/auth/presentation/widgets/dojo_pin_recovery_sheet.dart#L35-L446)
  * ユーザーロール定義: [`lib/shared/domain/entities/user_role.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/shared/domain/entities/user_role.dart)

* **UI全要素リスト**:
  - [x] **ヘッダーエリア**:
    - アプリアイコン（剣道面ロゴ）
    - タイトル「Kendo Sync」
    - サブタイトル「Stage2 β：利用権限を選択してください」
  - [x] **接続中の道場ID (ルーム) バー**:
    - シールドアイコン
    - 「接続中の道場ID (ルーム)」ラベル ＆ 現在のID（未設定時は「未設定」）
    - タップで `RoomJoinQrDialog` ボトムシートが開く
  - [x] **道場ルーム参加ボトムシート (`RoomJoinQrDialog`) ＆ 道場入室PINシート (`RoomJoinPinDialog`)**:
    - タイトル「道場ルームへの参加」
    - QRスキャン起動ボタン / 手動入力テキストフィールド（英数字）
    - 重複検知アラート（すでに存在する道場IDの場合は合流確認ダイアログ発火）
    - **道場入室PIN（合言葉）フロー**:
      - 新規道場作成時: 「新規道場ルームのPIN設定」画面で入室PINを設定
      - 未保護の既存道場参加時: 「初回入室PINの設定（既存ルーム保護）」画面で設定
      - 既存道場入室時: 「道場入室PINの入力」画面で合言葉を入力（忘れた場合は代表者Google本人確認へ誘導）
  - [x] **4つの権限ボタン（カラーコード・遷移先）**:
    1. **代表・管理者 (Admin)**（紫色 / `AppKendoColors.purple`）➔ タップで `/pin-auth?role=admin` へ遷移
    2. **監督・引率責任者 (Operator)**（青緑色 / `AppKendoColors.teal`）➔ タップで `/pin-auth?role=operator` へ遷移
    3. **スコア・記録係 (Recorder)**（濃紺色 / `AppKendoColors.indigo`）➔ タップで `/pin-auth?role=recorder` へ遷移
    4. **応援・保護者・選手 (Viewer)**（青灰色 / `AppKendoColors.blueGrey`）➔ **PIN不要**（匿名認証を同期確立し、即座にトップ `/` へ遷移）
  - [x] **セキュアPIN認証画面 (`PinAuthScreen`)**:
    - ヘッダー（戻るボタン、選択中ロール表示）
    - 4桁PIN入力インジケータ（伏字ドット表示、4桁入力完了時に即時自動検証）
    - 独自テンキー（0〜9ボタン、クリア、1文字削除 `⌫` ボタン）
    - **「PINを忘れた場合（代表者Googleで初期化）」ボタン**: タップで `DojoPinRecoverySheet` が起動し、登録済み代表者Googleアカウントで本人確認後にPINを初期化・再設定可能
    - **初回 Admin ログイン時の初期ロールPIN変更案内 (`InitialRolePinPromptDialog`)**: クラウド接続済み道場で初期PINのまま Admin ログインした場合、道場別カスタムPINへの変更を促す案内ダイアログを表示

* **現行マニュアル（PDF P7〜P8, P13 / v1.0.0）との重大な差分**:
  1. **【最重要】初期PINコードと道場別カスタムPIN**:
     * 旧PDF（P13等）: 「記録員は 0000、運営者は 1234」
     * **現行実装（`PinGuard`）**:
       * 初期PINは **Admin: `9999` / Operator: `2468` / Recorder: `1357` / Viewer: PIN不要**。
       * **v1.1.0新仕様**: クラウド接続された道場では設定画面から道場ごとに4桁PINを個別変更でき、変更後は道場別カスタムPINが優先検証される。
  2. **【v1.1.0新機能】道場入室PIN（合言葉）による他道場誤接続・なりすまし防止**:
     * 新規道場作成時・既存道場参加時に「道場入室PIN（合言葉）」の設定・入力が必須となり、道場IDが推測されても第三者が勝手に入室できない。
  3. **【v1.1.0新機能】PIN忘れ時の代表者Google本人確認による初期化**:
     * PIN認証画面および入室PINシートの下部に「PINを忘れた場合（代表者Googleで初期化）」導線を追加。
  4. **ロール表示名称のアップデート**:
     * 旧PDF: 「管理者 (Admin)」「運営者 (Operator)」「記録者 (Recorder)」「閲覧者 (Viewer)」
     * **現行UI**: **「代表・管理者 (Admin)」「監督・引率責任者 (Operator)」「スコア・記録係 (Recorder)」「応援・保護者・選手 (Viewer)」**

* **PDF・マニュアル用スクショ撮影・差し替え指示リスト（全5枚）**:
  * `[SS-01-1]` **差し替え**｜**画面**: 役割選択画面（`RoleSelectScreen`）｜**撮影状態**: 接続中の道場IDバーと4つのカラフルな権限ボタンが一覧で見えている状態｜**差し替え先**: 配布用PDF 第1章 P5〜P8「権限選択」／`operator/index.md`
  * `[SS-01-2]` **差し替え**｜**画面**: 道場ルーム参加ボトムシート（`RoomJoinQrDialog`）｜**撮影状態**: 道場ID入力欄とQRスキャン・接続開始ボタンが表示されている状態｜**差し替え先**: 配布用PDF 第1章 P5〜P8「道場ID接続」／`operator/index.md`
  * `[SS-01-3]` **差し替え**｜**画面**: PIN認証画面（`PinAuthScreen`）｜**撮影状態**: 4桁テンキー、ドットインジケータ、下部「PINを忘れた場合（代表者Googleで初期化）」ボタンが見えている状態｜**差し替え先**: 配布用PDF 第1章 P7〜P8「PIN認証」／`operator/index.md`
  * `[SS-01-4]` **新規追加**｜**画面**: 道場入室PIN設定・認証ボトムシート（`RoomJoinPinDialog`）｜**撮影状態**: 「新規道場ルームのPIN設定」または「道場入室PINの入力」フォームが開いている状態｜**差し替え先**: 配布用PDF 第1章 P5〜P8「道場入室PIN（合言葉）」セクション新設／`operator/index.md`
  * `[SS-01-5]` **新規追加**｜**画面**: PIN初期化・復旧ボトムシート（`DojoPinRecoverySheet`）｜**撮影状態**: 代表者Googleアカウントでの本人確認と新PIN入力フォームが表示されている状態｜**差し替え先**: 配布用PDF 第1章 P7〜P8「PINを忘れた場合」／`operator/index.md` & `faq/operator_faq.md`

---

## 【Phase 1: 事前準備・選手マスタ・大会作成】（PDF第2章 P9〜P12）

### 【Step 2/27】選手マスタ管理・新年度一括進級・卒業/OB・OG名簿・バックアップ
* **対象マニュアル**: [`packages/documentation_runtime/manuals/operator/master_management.md`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/packages/documentation_runtime/manuals/operator/master_management.md)
* **コード根拠**:
  * 選手マスタ管理画面: [`lib/admin/presentation/screens/master_management_screen.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/admin/presentation/screens/master_management_screen.dart)
  * 選手登録・編集シート: [`lib/admin/presentation/components/master_player_edit_bottom_sheet.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/admin/presentation/components/master_player_edit_bottom_sheet.dart)
  * 在籍区分セレクタ: [`lib/admin/presentation/components/master_player_status_selector.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/admin/presentation/components/master_player_status_selector.dart)
  * 管理メニューシート: [`lib/admin/presentation/components/master_menu_bottom_sheet.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/admin/presentation/components/master_menu_bottom_sheet.dart)
  * 新年度一括進級シート: [`lib/admin/presentation/components/master_annual_promotion_sheet.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/admin/presentation/components/master_annual_promotion_sheet.dart)
  * 卒業・OB/OG名簿シート: [`lib/admin/presentation/components/master_graduated_players_sheet.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/admin/presentation/components/master_graduated_players_sheet.dart)
  * データ管理ダイアログ: [`lib/admin/presentation/components/master_data_cleanup_dialog.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/admin/presentation/components/master_data_cleanup_dialog.dart)
  * 一括進級ロジック: [`lib/shared/infrastructure/repository/player_repository.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/shared/infrastructure/repository/player_repository.dart)

* **UI全要素リスト**:
  - [x] **ヘッダーバー & 所属道場バー**:
    - 道場名表示・現役所属人数カウント（※卒業・OB/OGは専用名簿へ自動分離）
    - 表示切り替えタブ: 「学年別」 / 「カテゴリ別」
    - 右上メニューボタン（`...`）
  - [x] **選手一覧リスト**:
    - 学年・カテゴリ別グループヘッダー
    - 選手タイル（氏名、学年、性別バッジ、初心者バッジ）
    - 操作アクション:
      - **タップ**: 選手情報の編集ボトムシートを開く
      - **長押し**: 「一括選択モード」へ移行（ヘッダーにゴミ箱アイコンが出現し一括削除可能）
      - **スワイプ**: 個別編集・削除メニュー（浮遊カプセル型スワイプ `AppSlidableAction`）
  - [x] **選手追加・編集ボトムシート (`MasterPlayerEditBottomSheet`)**:
    - 苗字・名前入力欄（漢字入力時に `AutoKanaHelper` によりフリガナ自動推測入力）
    - フリガナ手動修正欄
    - 性別選択ボタン（男子 / 女子）
    - 学年カテゴリドロップダウン（未就学、小1〜小6、中1〜中3、高1〜高3、大1〜大4、一般）
    - **在籍区分セレクタ (`MasterPlayerStatusSelector`)**: 「現役」 / 「卒業・OB/OG」（卒業選択時は卒業年度を指定可能）
    - 「初心者の印をつける」トグルスイッチ
    - 「保存して登録」ボタン（カプセル型）
  - [x] **マスタ管理メニュー（`...` タップ時 / `MasterMenuBottomSheet`）**:
    1. **データとストレージ管理 (`MasterDataCleanupDialog`)**:
       - 「一時キャッシュをクリア」ボタン（メモリ解放）
       - 「全データをJSONでバックアップ」ボタン（端末ファイル保存・共有）
       - 「1年以上前の大会を削除」ボタン
    2. **新年度の一括進級 (`MasterAnnualPromotionSheet`)**:
       - 卒業ライン選択（小学校卒業 / 中学校卒業 / 高校卒業 / 大学卒業 等 `OrganizationGraduationType`）
       - 例外残留設定（留年・在籍継続する選手を個別チェックで残留指定）
       - 実行前プレビュー（進級人数・卒業OB/OG人数・一般維持）および最終確認ダイアログ
    3. **卒業・OB/OG名簿（`MasterGraduatedPlayersSheet`）**:
       - アーカイブされた卒業生・OB/OGの件数バッジ付き一覧表示
       - 個別選手の閲覧・編集・削除、および**「現役への復帰」**ダイアログ（進級学年または「一般」として現役名簿へ戻す機能）

* **現行マニュアル（PDF P9〜P12 / v1.0.0）との差分**:
  1. **【v1.1.0新機能】卒業ライン選択・例外残留付き「新年度の一括進級シート」**:
     * 単純な確認アラートから、道場・学校種別に応じた卒業ライン選択、例外残留チェック、進級・卒業人数の事前プレビューができる専用シートへ進化。
  2. **【v1.1.0新機能】「卒業・OB/OG名簿」の専用シート分離＆現役復帰機能**:
     * 管理メニュー（`...`）から卒業生を別名簿として管理でき、必要な選手をワンタップで現役名簿へ復帰可能。
  3. **【v1.1.0新機能】選手登録の「在籍区分（現役 / 卒業・OB/OG）」**:
     * 個別選手編集画面で現役・卒業・OB/OGと卒業年度を切り替え可能。
  4. **長押し選択モード & 初心者トグル**:
     * 長押しによる複数選択一括削除、およびオーダー時の目印となる初心者トグルを明記。

* **PDF・マニュアル用スクショ撮影・差し替え指示リスト（全5枚）**:
  * `[SS-02-1]` **差し替え**｜**画面**: 選手マスタ画面（`MasterManagementScreen`）｜**撮影状態**: 学年別タブで現役選手がグループ分けされて並んでいる状態｜**差し替え先**: 配布用PDF 第2章 P9〜P10「選手マスタ一覧」／`operator/master_management.md`
  * `[SS-02-2]` **差し替え**｜**画面**: 選手登録ボトムシート（`MasterPlayerEditBottomSheet`）｜**撮影状態**: フリガナ自動入力、「在籍区分（現役 / 卒業・OB/OG）」セレクタ、初心者トグルが見えている状態｜**差し替え先**: 配布用PDF 第2章 P10〜P11「選手の追加・編集」／`operator/master_management.md`
  * `[SS-02-3]` **差し替え**｜**画面**: 新年度の一括進級シート（`MasterAnnualPromotionSheet`）｜**撮影状態**: 卒業ライン選択・進級/卒業プレビュー・例外残留リストが見えている状態｜**差し替え先**: 配布用PDF 第2章 P11〜P12「新年度の一括進級」／`operator/master_management.md`
  * `[SS-02-4]` **差し替え**｜**画面**: データとストレージ管理ダイアログ（`MasterDataCleanupDialog`）｜**撮影状態**: キャッシュクリア・JSONバックアップ・古い大会削除ボタンが見えている状態｜**差し替え先**: 配布用PDF 第2章 P12「バックアップ・整理」／`operator/master_management.md`
  * `[SS-02-5]` **新規追加**｜**画面**: 卒業・OB/OG名簿シート（`MasterGraduatedPlayersSheet`）｜**撮影状態**: 卒業生一覧と「現役への復帰」確認ダイアログが見えている状態｜**差し替え先**: 配布用PDF 第2章 P12「卒業・OB/OG名簿と現役復帰」セクション新設／`operator/master_management.md`

---

### 【Step 3/27】新規大会の作成（スタート画面含む）
* **対象マニュアル**: [`packages/documentation_runtime/manuals/operator/create_tournament.md`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/packages/documentation_runtime/manuals/operator/create_tournament.md)
* **コード根拠**:
  * スタート画面の導線: [`lib/features/tournament/presentation/operate/screens/start_screen.dart:L118-L370`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/operate/screens/start_screen.dart#L118-L370)
  * 大会作成ウィザード: [`lib/features/tournament/presentation/operate/screens/create_tournament_screen.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/operate/screens/create_tournament_screen.dart)
  * チーム自動登録サービス: [`lib/features/tournament/domain/share_import/tournament_team_auto_register_service.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/domain/share_import/tournament_team_auto_register_service.dart)

* **UI全要素リスト**:
  - [x] **スタート画面（入口 / `StartScreen`）**:
    - 19.5:9 標準画面でスクロールなしに全体が収まるレイアウト最適化（v1.1.0）
    - 「新しい大会を作る」カード（プラス丸アイコン `Icons.add_circle`、サブタイトル「大会・錬成会」）
    - ※ ViewerやRecorderなど権限のない端末ではカード自体が非表示
    - **フッターエリア（バージョン＆サポート・規約リンク）**:
      - ロゴ＆バージョン表記「`Kendo Sync v1.1.0`」
      - 「利用規約」「プライバシーポリシー」「お問い合わせ」リンク（タップで共通スクロールダイアログ `LegalDocumentDialog` が起動、完全オフライン閲覧可能）
  - [x] **大会新規作成ウィザード（動的ヘッダー & プログレスバー）**:
    - ヘッダー文言: 「大会を新規作成」「魔法のウィザードに従って、2つのステップで設定を完了しましょう」
    - プログレスインジケータ（Step 1/2）
  - [x] **ステップ ❶：大会名と日付 (`CreateTournamentPage1`)**:
    - 「大会の名前と日付を教えてください」見出し
    - 大会名入力欄（例: 第10回 道場対抗剣道大会、必須バリデーション、カプセル型）
    - 開催年月日ピッカー（カレンダーアイコン、日本語ロケールダイアログ）
    - クリップボードからのインポート（共有データがある場合の自動解析カード）
    - 【次へ進む】ボタン（カプセル型）
  - [x] **ステップ ❷：会場・住所とメモ (`CreateTournamentPage2`)**:
    - 「開催場所とメモを入力してください」見出し
    - 会場・住所入力欄（右側にGoogleマップ連携アイコンがあり、タップでマップアプリ外部起動）
    - 大会メモ入力欄（任意）
    - 下部固定アクションバー: 【戻る】ボタン ＆ 【保存してチーム登録へ】ボタン
  - [x] **保存後の自動画面遷移**:
    - 保存成功後、自動的に `/team-registration/$newId`（チーム・選手登録画面）へ遷移

* **現行マニュアル（PDF P13 / v1.0.0）との差分**:
  1. **【v1.1.0 UI改善】スタート画面の19.5:9全画面収容＆バージョン表記**:
     * 縦長スマホ画面でスクロールせずに全カード・バージョン（`v1.1.0`）・規約リンクが見切れないレイアウトへ最適化。
  2. **Googleマップ連携ボタン & クリップボードインポート対応**:
     * 会場入力欄のマップ連携アイコンと、LINE等で共有された大会テキストの自動解析取り込み機能を明記。
  3. **権限ガード**:
     * 「新しい大会を作る」ボタンはAdmin・Operatorのみ表示され、誤操作が防止されている点を明記。

* **PDF・マニュアル用スクショ撮影・差し替え指示リスト（全3枚）**:
  * `[SS-03-1]` **差し替え**｜**画面**: スタート画面（`StartScreen`）｜**撮影状態**: 「新しい大会を作る」カードと下部フッター（「Kendo Sync v1.1.0」・規約リンク）が1画面に収まっている状態｜**差し替え先**: 配布用PDF 第2章 P13「スタート画面」／`operator/create_tournament.md`
  * `[SS-03-2]` **差し替え**｜**画面**: 新規大会作成 Step 1（`CreateTournamentPage1`）｜**撮影状態**: 大会名・開催日入力とカプセル型の「次へ進む」ボタンが見えている状態｜**差し替え先**: 配布用PDF 第2章 P13「Step 1 大会名と日付」／`operator/create_tournament.md`
  * `[SS-03-3]` **差し替え**｜**画面**: 新規大会作成 Step 2（`CreateTournamentPage2`）｜**撮影状態**: 会場名・マップアイコン・メモと「保存してチーム登録へ」ボタンが見えている状態｜**差し替え先**: 配布用PDF 第2章 P13「Step 2 会場と保存」／`operator/create_tournament.md`

---

### 【Step 4/27】チーム・選手登録（基本オーダー）
* **対象マニュアル**: [`packages/documentation_runtime/manuals/operator/team_registration.md`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/packages/documentation_runtime/manuals/operator/team_registration.md)
* **コード根拠**:
  * チーム登録メイン画面: [`lib/features/tournament/presentation/operate/screens/team_registration_screen.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/operate/screens/team_registration_screen.dart)
  * ステップ❶ カテゴリ選択: [`team_registration_category_step.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/operate/components/team_registration/team_registration_category_step.dart)
  * ステップ❷ オーダー配置: [`team_registration_page_two_view.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/operate/components/team_registration/team_registration_page_two_view.dart)
  * ステップ❸ 登録チーム一覧: [`team_registration_page_three_view.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/operate/components/team_registration/team_registration_page_three_view.dart)
  * 選手選択ボトムシート: [`team_registration_player_select_bottom_sheet.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/operate/components/team_registration/team_registration_player_select_bottom_sheet.dart)
  * 卒業生フィルターチップ: [`lib/shared/widgets/include_graduated_filter_chip.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/shared/widgets/include_graduated_filter_chip.dart)

* **UI全要素リスト**:
  - [x] **ヘッダー & 動的ステップバー (`TeamRegistrationDynamicHeader`)**:
    - 登録済みチーム数カウンター
    - 「ステップ ❶ 部門・形式」➔「ステップ ❷ オーダー」➔「ステップ ❸ 登録チーム一覧」の3ページ構成
  - [x] **ステップ ❶：部門（カテゴリ）と試合形式**:
    - **大カテゴリ**: 小学生、中学生、高校生、一般、その他
    - **小カテゴリ**: 低学年、高学年、男子、女子、混成、全体など
    - **カスタム部門名（登録済みチップ自動表示）**: 「その他」選択時に自由入力欄が出現（「〇〇の部」自動成形）。さらに過去に登録済みのカスタム部門が一覧チップとして自動表示されワンタップ選択可能
    - **試合形式**: 団体戦（5人制）、団体戦（3人制）、個人戦、日本剣道形、木刀基本技稽古法、それ以上（カスタムスロット）
    - プリセット選択チップ
    - 【次へ進む】ボタン
  - [x] **ステップ ❷：チーム名入力とオーダー配置**:
    - チーム名テキスト入力欄（過去履歴のオートコンプリート提案あり）
    - ポジション別スロットカード（先鋒、次鋒、中堅、副将、大将 / 3人制時は先鋒、中堅、大将）
    - 選手選択ボトムシート:
      - 選択中カテゴリに合致する現役マスタ選手を上位抽出
      - **「卒業生・OB/OGを含める」フィルターチップ (`IncludeGraduatedFilterChip`)**: OB/OG参加の大会等で卒業生を候補へ追加表示可能（v1.1.0）
      - 重複選択時のポジション自動スワップ（入れ替え）
      - マスタにない選手の名前直接入力
    - 補欠スロットの追加（【＋ 補欠を追加】）・削除
    - 【次へ進む】ボタン（または【登録して一覧へ】）
  - [x] **ステップ ❸：登録済みチーム一覧・管理**:
    - 部門別アコーディオンに整理された登録チームカード（チーム名、メンバー一覧、試合形式）
    - 各カードの【編集】（オーダー再呼び出し）および【削除】（ゴミ箱）
    - 【＋ 続けてチームを登録】ボタン（Step 1へ戻る）
    - 【完了して部門ルール設定へ】ボタン（`/category-rules/$id` へ遷移）

* **現行マニュアル（PDF P14 / v1.0.0）との差分**:
  1. **【v1.1.0新機能】「卒業生を含める」フィルターチップ**:
     * 通常は現役選手のみ候補表示し、OB/OG戦や一般大会ではワンタップで卒業生も選択候補に含められる仕様を追記。
  2. **3ステップウィザード構造 & 2段階カテゴリ選択**:
     * 「部門選択」➔「オーダー配置」➔「登録チーム確認」の3段階進行と、カスタム部門チップ自動サジェストを明記。
  3. **自動スワップと形競技の自動補完**:
     * 選手選択時の自動ポジション入れ替え、日本剣道形でのチーム名自動補完を明記。

* **PDF・マニュアル用スクショ撮影・差し替え指示リスト（全3枚）**:
  * `[SS-04-1]` **差し替え**｜**画面**: チーム登録 Step 1（`TeamRegistrationCategoryStep`）｜**撮影状態**: 大カテゴリ・小カテゴリ・試合形式のカプセルチップ選択画面｜**差し替え先**: 配布用PDF 第2章 P14「部門・形式選択」／`operator/team_registration.md`
  * `[SS-04-2]` **差し替え**｜**画面**: チーム登録 Step 2（`TeamRegistrationPageTwoView` + 選手選択シート）｜**撮影状態**: 先鋒〜大将スロットと、選手選択シート（「卒業生を含める」チップ含む）が開いている状態｜**差し替え先**: 配布用PDF 第2章 P14「オーダー配置・選手選択」／`operator/team_registration.md`
  * `[SS-04-3]` **差し替え**｜**画面**: チーム登録 Step 3（`TeamRegistrationPageThreeView`）｜**撮影状態**: 登録チームカード一覧と「完了して部門ルール設定へ」ボタンが見えている状態｜**差し替え先**: 配布用PDF 第2章 P14「登録チーム一覧」／`operator/team_registration.md`

---

### 【Step 5/27】部門ルール設定
* **対象マニュアル**: [`packages/documentation_runtime/manuals/operator/category_rules.md`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/packages/documentation_runtime/manuals/operator/category_rules.md)
* **コード根拠**:
  * 部門ルール画面: [`lib/features/tournament/presentation/operate/screens/category_rules_screen.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/operate/screens/category_rules_screen.dart)
  * ルールデータ構造: [`lib/features/match/domain/rules/category_rule_set.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/match/domain/rules/category_rule_set.dart)
  * 詳細確認ボトムシート: [`lib/features/tournament/presentation/operate/components/category_rules/category_rule_detail_bottom_sheet.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/operate/components/category_rules/category_rule_detail_bottom_sheet.dart)

* **UI全要素リスト**:
  - [x] **ヘッダー & 大会ホーム遷移ボタン**:
    - 大会名・部門一覧
    - 初期セットアップ時（`isFromSetup=true`）: 下部に「設定を完了して大会ホームへ」ボタン
  - [x] **部門カード一覧**:
    - 大会に登録されている部門名ごとのルールサマリーカード
    - 「編集」ボタン（ルール設定フォームの展開）
    - 「詳細」ボタン（`CategoryRuleDetailBottomSheet` の展開）
  - [x] **設定可能なルール項目**:
    - **基本設定**: 試合時間（分・秒）、ランニングタイム（流し計時）、勝負形式（三本/一本）
    - **延長戦**: 延長有無、延長時間、延長回数（無制限 / 1回 / サドンデス）
    - **判定・代表戦**: 判定有無、代表戦の有無、代表戦の形式（一本勝負/三本勝負、延長無制限）
    - **アドバンスド・ルール（決勝・準決勝特例）**:
      - 「準決勝」「決勝」「final」「3決」などのキーワードに合致する試合へ、自動的に延長無制限や時間延長を切り替える自動ルール機能
    - **マルチシーン（本戦・錬成・申し合わせ）**:
      - 錬成会や申し合わせ試合用の特別プリセット切り替え
  - [x] **既存試合への一括適用（Bulk Apply）ダイアログ**:
    - ルール保存時、該当部門の未実施試合がある場合に「未実施の〇件の試合に新ルールを一括適用しますか？」と確認ポップアップ

* **現行マニュアル（PDF P15〜P17）との差分**:
  1. **決勝・準決勝アドバンスド・ルールの明記**:
     * 試合名に「決勝」「準決勝」と入るだけで自動で時間延長や延長無制限へ切り替わる強力な自動化機能を追記。
  2. **初期セットアップ完了フロー**:
     * チーム登録完了から自動遷移し、本画面の保存をもって大会セットアップが完了して「大会ホーム」へ進む全体フローを明確化。

* **PDF・マニュアル用スクショ撮影・差し替え指示リスト（全3枚）**:
  * `[SS-05-1]` **差し替え**｜**画面**: 部門ルール設定画面（`CategoryRulesScreen`）｜**撮影状態**: 大会内の部門カードが並び、「編集」ボタンが見えている状態｜**差し替え先**: 配布用PDF 第2章 P15〜P16「部門ルール一覧」／`operator/category_rules.md`
  * `[SS-05-2]` **差し替え**｜**画面**: ルール詳細・編集シート（`CategoryRuleDetailBottomSheet`）｜**撮影状態**: 試合時間・延長戦・代表戦・アドバンスドトグルが見えている状態｜**差し替え先**: 配布用PDF 第2章 P16「ルール詳細編集」／`operator/category_rules.md`
  * `[SS-05-3]` **差し替え**｜**画面**: 一括適用ダイアログ｜**撮影状態**: 「未実施の〇件の試合に新ルールを一括適用しますか？」の確認ポップアップが表示された状態｜**差し替え先**: 配布用PDF 第2章 P17「一括適用」／`operator/category_rules.md`

---

## 【Phase 2: 試合作成・オーダー・ホーム】（PDF第3章後半 P15〜P21）

### 【Step 6/27】試合作成（新フロー）・オーダー編成
* **対象マニュアル**: [`packages/documentation_runtime/manuals/operator/setup_match.md`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/packages/documentation_runtime/manuals/operator/setup_match.md)
* **コード根拠**:
  * 試合作成フォーマット画面: [`lib/features/tournament/presentation/operate/screens/setup_match_format_screen.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/operate/screens/setup_match_format_screen.dart)
  * オーダー編成画面: [`lib/features/tournament/presentation/operate/screens/order_setup_screen.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/operate/screens/order_setup_screen.dart)
  * オーダー確定実行ヘルパー: [`order_setup_execution_helper.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/operate/components/order_setup/order_setup_execution_helper.dart)
  * 選手選択ボトムシート・卒業生フィルター: [`order_setup_player_select_bottom_sheet.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/operate/components/order_setup/order_setup_player_select_bottom_sheet.dart) / [`lib/shared/widgets/include_graduated_filter_chip.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/shared/widgets/include_graduated_filter_chip.dart)

* **UI全要素リスト**:
  - [x] **試合作成フォーマット画面 (`SetupMatchFormatScreen`)**:
    - **Page 1（部門・自チーム選択）**:
      - 大カテゴリ・小カテゴリ選択チップ（「その他」選択時は登録済みカスタム部門一覧チップが自動表示されワンタップ選択可能）
      - 登録済みチーム一覧カード（タップで出場する自チームを選択）
      - ※ チーム選択時に前回のコート番号・試合順（+1）が自動入力される
    - **Page 2（ルール・試合場設定）**:
      - 試合場（コート番号）入力欄 ＆ プリセットトグル
      - 試合メモ入力欄（「準決勝」「決勝」等を入れるとアドバンスドルールが自動連動）
      - 試合時間、延長、判定、勝敗ポイント（勝点・分点・敗点）
      - 【次へ進む】ボタン ➔ オーダー編成画面へ
  - [x] **オーダー編成画面 (`OrderSetupScreen`)**:
    - **赤白トグルスイッチ**: 自チームが赤（先攻・上段）か白（後攻・下段）かをワンタップ切替
    - **相手チーム名入力欄**: 過去に入力した対戦相手の履歴サジェスト付き
    - **基本オーダー操作バー**:
      - 【現在のオーダーを基本オーダーとして記憶】ボタン
      - 【基本オーダーを呼び出し】ボタン
    - **ポジション別対戦スロット（先鋒〜大将）**:
      - 自チーム選手: タップでマスタ選択（「卒業生を含める」フィルターチップ対応）、ドラッグ＆ドロップで選手の位置を自由にスワップ（入れ替え）
      - 相手チーム選手: 名前直接入力、または **【欠員】ボタン（ワンタップで「欠員」がセットされ不戦勝処理）**
    - **【追加枠】ボタン**: 6人制以上の枠追加
    - **【オーダーを確定して試合一覧へ】ボタン**: 試合を生成し、大会ホームへ遷移

* **現行マニュアル（PDF P15, P18〜P19 / v1.0.0）との差分**:
  1. **フォーマット設定の2ページ構成**:
     * 自チーム選択 ➔ コート・ルール設定の流れを明記。
  2. **基本オーダーの記憶・呼出ボタン**:
     * 登録した基本順番をワンタップで復元、または現在の配置を記憶できる実務機能を明記。
  3. **相手選手の【欠員】ボタン**:
     * 相手が4人以下の場合に、ワンタップで「欠員（不戦勝）」を設定できる便利ボタンを明記。
  4. **コート・試合順（+1）の自動提案 & 卒業生フィルター**:
     * 前回同じチームが出場したコート番号と次試合番号が自動で引き継がれる時短仕様、およびオーダー選手選択時の「卒業生を含める」フィルター（v1.1.0）を明記。

* **PDF・マニュアル用スクショ撮影・差し替え指示リスト（全3枚）**:
  * `[SS-06-1]` **差し替え**｜**画面**: 試合作成フォーマット画面（`SetupMatchFormatScreen`）｜**撮影状態**: 自チーム選択とコート・ルール設定が見えている画面｜**差し替え先**: 配布用PDF 第3章 P15, P18「試合作成フォーマット」／`operator/setup_match.md`
  * `[SS-06-2]` **差し替え**｜**画面**: オーダー編成画面（`OrderSetupScreen` 通常状態）｜**撮影状態**: 赤白トグル、自チーム選手ドラッグ、相手チーム名入力が見えている画面｜**差し替え先**: 配布用PDF 第3章 P18〜P19「オーダー編成」／`operator/setup_match.md`
  * `[SS-06-3]` **差し替え**｜**画面**: オーダー編成画面（欠員設定状態）｜**撮影状態**: 相手選手の「欠員」ボタンを押して「欠員」が表示されている状態｜**差し替え先**: 配布用PDF 第3章 P19「欠員・不戦勝設定」／`operator/setup_match.md`

---

### 【Step 7/27】一括ルール編集（進行中の緊急ルール変更）
* **対象マニュアル**: [`packages/documentation_runtime/manuals/operator/bulk_rule_edit.md`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/packages/documentation_runtime/manuals/operator/bulk_rule_edit.md)
* **コード根拠**:
  * 一括ルール変更シート: [`lib/features/tournament/presentation/operate/components/bulk_rule_edit_sheet.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/operate/components/bulk_rule_edit_sheet.dart)
  * フォームセクション: [`bulk_rule_form_section.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/operate/components/bulk_rule_form_section.dart)
  * 対象選択セクション: [`bulk_rule_target_select_section.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/operate/components/bulk_rule_target_select_section.dart)

* **UI全要素リスト**:
  - [x] **呼び出し導線**:
    - 大会ホーム（通常大会）や部内戦ホームのタイムライン操作バーにある【⚡ 一括ルール変更】アイコン
  - [x] **STEP 1：対象試合の絞り込みと選択 (`BulkRuleTargetSelectSection`)**:
    - 部門ドロップダウンフィルター（すべて、登録部門一覧）
    - 試合形式フィルター（すべて、団体戦、個人戦）
    - 対象試合のリスト（チェックボックスで個別に選択・解除、または【全選択 / 全解除】ボタン）
    - ※ 終了・確定済みの試合は自動的に対象外となる安全設計
  - [x] **STEP 2：新ルールの設定 (`BulkRuleFormSection`)**:
    - ルール不一致警告バナー（選択中の試合でルールが異なる場合に注意喚起）
    - 部門ルールプリセットからのワンタップ読み込み
    - 試合時間（分・秒）、ランニングタイム（流し計時）トグル
    - 勝負形式（三本勝負 / 一本勝負）、反則リミット、一本リミット
    - 延長戦（あり/なし、延長時間、無制限/回数指定）
    - 判定（あり/なし）
    - 代表戦設定（団体戦時: 代表戦あり/なし、一本勝負、延長無制限）
  - [x] **STEP 3：一括適用の実行 (`BulkRuleBottomBar`)**:
    - 画面下部【選択した〇件の試合に適用する】ボタン（カプセル型）
    - 承認後、全対象試合のルールが瞬時に更新される

* **現行マニュアルとの差分**:
  1. **プリセット読み込み機能の明記**:
     * 手動で各項目を変えるだけでなく、登録済み部門ルールや錬成会プリセットからワンタップで呼び出せる機能を明記。
  2. **混在警告バナーの存在**:
     * 複数試合のルールがバラバラな場合に警告が出る安全仕様を明記。
  3. **部内戦モード対応**:
     * 通常大会だけでなく部内戦でも急な時間短縮等に利用可能な点を明記。

* **PDF・マニュアル用スクショ撮影・差し替え指示リスト（全2枚）**:
  * `[SS-07-1]` **新規追加**｜**画面**: 一括ルール変更シート Step 1（`BulkRuleTargetSelectSection`）｜**撮影状態**: 部門・形式フィルターと試合チェックボックスが見えている状態｜**差し替え先**: 配布用PDF 第3章「一括ルール変更（対象選択）」／`operator/bulk_rule_edit.md`
  * `[SS-07-2]` **新規追加**｜**画面**: 一括ルール変更シート Step 2（`BulkRuleFormSection`）｜**撮影状態**: 試合時間・延長戦トグルと下部「選択した〇件の試合に適用する」ボタンが見えている状態｜**差し替え先**: 配布用PDF 第3章「一括ルール変更（新ルール適用）」／`operator/bulk_rule_edit.md`

---

### 【Step 8/27】大会ホーム画面ガイド（一覧・タブ・観戦QR有効期限・対戦サマリー）
* **対象マニュアル**: [`packages/documentation_runtime/manuals/operator/home_guide.md`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/packages/documentation_runtime/manuals/operator/home_guide.md)
* **コード根拠**:
  * 大会ホーム画面: [`lib/features/tournament/presentation/operate/screens/home_screen.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/operate/screens/home_screen.dart)
  * コールバナー: [`home_screen_call_banner.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/operate/components/home/home_screen_call_banner.dart)
  * タイムラインリスト: [`match_timeline_list.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/operate/components/home/match_timeline_list.dart)
  * 初期チェックリスト: [`home_screen_setup_checklist_card.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/operate/components/home/home_screen_setup_checklist_card.dart)
  * 1大会限定QR共有＆有効期限: [`lib/shared/widgets/qr_share_dialog.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/shared/widgets/qr_share_dialog.dart) / [`lib/shared/widgets/viewer_share_expiry_selector.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/shared/widgets/viewer_share_expiry_selector.dart)

* **UI全要素リスト**:
  - [x] **オフライン・同期バナー**:
    - 電波断時: 「⚠️ 体育館オフライン運営モード：ローカルDB（Isar）へ即時保存中」（アンバー）
    - 同期中: 「☁️ クラウドから大会データを同期中...」（ブルー）
  - [x] **ヘッダーバー & ナビゲーション**:
    - 大会ホームタイトル ＆ 戻るボタン（`/tournament-list` へ）
    - 🔍 検索アイコン（インクリメンタル検索バー展開、キーワードの蛍光黄色ハイライト連動）
    - **観戦プレビューアイコン (`Icons.preview_rounded`)**: 「観客の画面を確認」ボタン（v1.1.0で視認性・外部出力識別のためアイコン刷新）
    - 📲 **「大会を共有する」ボタン**: `HomeScreenQrDialog` 経由でトークン付き1大会限定QRコード・観客用URL共有ダイアログ（`QrShareDialog`）を表示
      - **観戦リンクの有効期限セレクター (`ViewerShareExpirySelector`)**: 24時間 / 7日間 / 無期限 / 停止（公開即時終了）をワンタップ切替（v1.1.0）
  - [x] **下スワイプ強制同期 (Pull-to-Refresh)**:
    - タイムラインを下スワイプしてローカル・クラウド間の全データを即座に強制再同期
  - [x] **初期準備チェックリストカード (`HomeScreenSetupChecklistCard`)**:
    - 試合未登録時に出現し、「チーム登録」「部門ルール」「試合作成」へのクイックリンクを提供
  - [x] **呼び出しバナーエリア (`HomeScreenCallBanner`)**:
    - **進行中の試合（オレンジ文字「進行中」）**: コートで現在戦っている対戦カード
    - **次の試合・待機（「次試合」／2件目以降「次々試合」白文字）**: 次に呼び出す対戦カード（読み取り専用表示であり、バナー自体のタップ遷移機能はなし）
  - [x] **運営アクションボタンバー (`OperatorActionButtons`)**:
    - 全ボタンがカプセル型（Stadium/Pill形状）に統一
    - 【＋ 試合作成】（対戦カード追加）
    - 【⚙️ 部門ルール】（ルール確認・変更）
    - 【⚡ 一括ルール変更】（緊急ルール調整）
  - [x] **試合タイムライン (`MatchTimelineList`)**:
    - 部門別フィルターチップ（「すべて」「小学生」「中学生」など）
    - 昇順/降順ソート ＆ 全カード一括開閉トグル
    - 試合カード（赤チーム vs 白チーム、スコア、コート名、ステータス）
    - カードタップでアコーディオン開閉（先鋒〜大将の個別スコア表示）
    - **浮遊カプセル型スワイプアクション (`AppSlidableAction`)**: iOSメモ風の角丸余白を持つ浮遊ピル型メニュー（個別削除・編集）
  - [x] **常設フローティングドック (`FloatingProgramDockButton`)**:
    - 画面右下に常駐（プログラム・チーム状況・サブタイマー呼び出し）

* **現行マニュアル（PDF P20〜P21 / v1.0.0）との差分**:
  1. **【v1.1.0新機能】1大会限定 観戦リンクの有効期限・停止制御 (`ViewerShareExpirySelector`)**:
     * 大会共有QRダイアログ内で「24時間 / 7日間 / 無期限 / 停止」を切り替えられ、大会終了後に観戦URLを安全に閉じられる仕様を明記。
  2. **【v1.1.0 UI変更】観戦プレビューアイコンの刷新 (`Icons.preview_rounded`)**:
     * AppBarの観戦プレビューボタンを、PINマスク切替の目アイコンと明確に区別できるプレビュー専用アイコンへ変更。
  3. **初期チェックリストカード & スワイプカード操作**:
     * セットアップチェックリストと浮遊カプセル型スワイプ削除・編集操作を明記。

* **PDF・マニュアル用スクショ撮影・差し替え指示リスト（全4枚）**:
  * `[SS-08-1]` **差し替え**｜**画面**: 大会ホーム画面全体（`HomeScreen`）｜**撮影状態**: AppBarの観戦プレビュー新アイコン（`preview_rounded`）、コールバナー、タイムライン、右下ドックが見えている状態｜**差し替え先**: 配布用PDF 第3章 P20「大会ホーム画面」／`operator/home_guide.md`
  * `[SS-08-2]` **差し替え**｜**画面**: 大会ホーム（検索・フィルター適用中）｜**撮影状態**: 検索バー展開（黄色ハイライト）または部門チップで絞り込まれた状態｜**差し替え先**: 配布用PDF 第3章 P21「検索・フィルター」／`operator/home_guide.md`
  * `[SS-08-3]` **差し替え**｜**画面**: 大会ホーム（オフライン警告バナー表示中）｜**撮影状態**: 最上部にアンバー色のオフライン防衛バナーが出ている状態｜**差し替え先**: 配布用PDF 第3章 P21「オフライン時の表示」／`operator/home_guide.md`
  * `[SS-08-4]` **新規追加**｜**画面**: 大会共有QRダイアログ（`QrShareDialog` + `ViewerShareExpirySelector`）｜**撮影状態**: QRコードと「観戦リンクの有効期限（24時間 / 7日間 / 無期限 / 停止）」選択チップが表示されている状態｜**差し替え先**: 配布用PDF 第3章 P21「観戦QR共有と公開期限」セクション新設／`operator/home_guide.md`

---

## 【Phase 3: 試合進行・スコア記録・通常ドック】（PDF第3章 P13〜P18）

### 【Step 9/27】試合記録（タイマー・得点・反則・Undo・終了確定）
* **対象マニュアル**: [`packages/documentation_runtime/manuals/operator/match.md`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/packages/documentation_runtime/manuals/operator/match.md)
* **コード根拠**:
  * 試合画面ルート: [`lib/features/tournament/presentation/operate/match_screen.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/operate/match_screen.dart)
  * 試合画面本体構造: [`match_screen_body_content.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/operate/components/match_screen/match_screen_body_content.dart)
  * タイマーウィジェット: [`lib/shared/widgets/timer_widget.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/shared/widgets/timer_widget.dart)
  * スコアアクションセクション: [`match_score_action_section.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/operate/components/match_screen/match_score_action_section.dart)
  * スマートUndoフローティングバー: [`smart_undo_floating_bar.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/operate/components/match_screen/smart_undo_floating_bar.dart)
  * 直近操作ミニログ＆Undo: [`match_mini_log_undo_section.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/operate/components/match_screen/match_mini_log_undo_section.dart)
  * 試合終了確定ボタン行: [`match_action_button_row.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/operate/components/match_screen/match_action_button_row.dart)
  * 画面最下部アクションセクション: [`match_bottom_action_section.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/operate/components/match_screen/match_bottom_action_section.dart)
  * 公式スコア表示仕様書: [`docs/domain/kendo_score_display_spec.md`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/docs/domain/kendo_score_display_spec.md)

* **UI全要素リスト**:
  - [x] **タイマーエリア (`TimerWidget`)**:
    - タップで開始／一時停止（トグル動作、ハプティクスフィードバック連動）
    - 待機中（青/インディゴ枠線）から計測動作中は**全面レッド背景・赤枠線・白文字**へ劇的変化
    - 長押しで**「時間修正」ダイアログ**が起動し、分（m）と秒（s）の直接数値入力が可能
  - [x] **赤白打突・反則アクションパネル (`MatchScoreActionSection`)**:
    - 赤サイド（左）・白サイド（右）の2分割レイアウト
    - 技ボタン: 【メ（面）】【コ（小手）】【ド（胴）】【ツ（突き）】（有効打突即座反映）
    - 反則ボタン: 【反則】（タップで左下に `△` を累積表示（最大4個、相手へ `反` 付与後も消去せず保持）。2回累積で相手選手へ `反` 一本を自動付与。3本勝負の先取時は `◯反` として丸囲み表示）
    - 【判定】ボタン（判定ルール時） / 【途中棄権】（アクシデント処理）
  - [x] **視点反転ボタン (`Icons.swap_horiz_rounded`)**:
    - 画面中央上部のピル型トグルボタン
    - 「正面視点」「逆サイド視点」を瞬時に切り替え（審判席と記録席の物理配置に合わせて赤白パネルを左右反転）
  - [x] **5秒カウントダウン付きスマートUndoフローティングバー (`SmartUndoFloatingBar`)**:
    - 打突や反則の記録直後に画面下部へスライド出現（5秒間限定表示）
    - イベント内容（例:【赤・面】）と残り時間プログレスバー、直感的な「取り消す」ボタン
  - [x] **直近操作ミニログ＆Undoボタン (`MatchMiniLogUndoSection`)**:
    - 直近3件のスコア・反則履歴をタイムスタンプ付きで常時リスト表示
    - 【１つ前の操作を取り消す】ボタン：タップで1手巻き戻し（タイマーは一時停止状態をキープ）
  - [x] **試合終了・確定ボタン (`MatchActionButtonRow` / `MatchBottomActionSection`)**:
    - 試合中は「試合終了」、勝敗成立後は「記録確定して次へ」などの動的ラベル
    - 誤操作防止ガード：設定に応じて**「1.5秒長押し」または「ダブルタップ」**が必須（単発タップ時はスナックバーで操作案内）

* **現行マニュアル（PDF P13〜P15 / v1.0.0）との差分**:
  1. **【最重要】タイマーの色変化と時間修正**:
     * 計時開始で背景が赤点灯し白文字化する視覚的フィードバック、およびタイマー長押しによる分・秒直接編集ダイアログ機能を明記。
  2. **【v1.1.0是正】剣道公式スコア表示仕様（`◯反`・`△` 累積・不戦勝 `◯`）**:
     * 3本勝負の先取（1本目）が反則による一本だった場合も `◯反` と丸囲みする仕様、および反則警告 `△` は消去せず左下に最大4個まで累積保持する公式記録準拠仕様を明記。
  3. **視点反転機能・スマートUndoバー・誤終了防止長押し**:
     * 審判席との左右反転トグル、5秒カウントダウン付きUndoバー、試合終了ボタンの1.5秒長押し（またはダブルタップ）仕様を明記。

* **PDF・マニュアル用スクショ撮影・差し替え指示リスト（全3枚）**:
  * `[SS-09-1]` **差し替え**｜**画面**: 試合記録メイン画面（`MatchScreen`）｜**撮影状態**: タイマー計時中（赤背景点灯）、先取 `◯`（または `◯反`）と左下 `△` 累積が表示された状態｜**差し替え先**: 配布用PDF 第3章 P13〜P14「試合記録とタイマー」／`operator/match.md`
  * `[SS-09-2]` **差し替え**｜**画面**: 試合記録メイン画面（スマートUndoバー出現中）｜**撮影状態**: 一本取得直後、画面下部に5秒カウントダウン付き「取り消す」バーが出現している状態｜**差し替え先**: 配布用PDF 第3章 P14「スコア修正・Undo」／`operator/match.md`
  * `[SS-09-3]` **差し替え**｜**画面**: タイマー長押し時間修正ダイアログ｜**撮影状態**: 分（m）と秒（s）の数値入力フォームが開いている状態｜**差し替え先**: 配布用PDF 第3章 P15「タイマー時間修正」／`operator/match.md`

---

### 【Step 10/27】チーム試合状況（団体戦リアルタイム勝敗）
* **対象マニュアル**: [`packages/documentation_runtime/manuals/operator/team_match_status.md`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/packages/documentation_runtime/manuals/operator/team_match_status.md)
* **コード根拠**:
  * チーム試合状況画面: [`lib/features/tournament/presentation/operate/screens/team_match_status_screen.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/operate/screens/team_match_status_screen.dart)
  * チーム進捗カード: [`lib/features/tournament/presentation/operate/components/court_status/team_status_card.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/operate/components/court_status/team_status_card.dart)
  * 団体戦スコアボード画面: [`lib/features/tournament/presentation/operate/team_scoreboard_screen.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/operate/team_scoreboard_screen.dart)
  * スコアボードテーブル生成: [`team_scoreboard_table_builder.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/operate/components/team_scoreboard/team_scoreboard_table_builder.dart)
  * 代表戦生成ハンドラー: [`team_scoreboard_daihyo_handler.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/operate/components/team_scoreboard/team_scoreboard_daihyo_handler.dart)
  * 団体戦勝敗計算ロジック: [`lib/features/match/domain/services/team_match_calculator.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/match/domain/services/team_match_calculator.dart)

* **UI全要素リスト**:
  - [x] **チーム試合状況画面 (`TeamMatchStatusScreen` / `/court-status`)**:
    - **サマリー進行バナー**:
      - 🔴 試合中（Live）: 現在進行中のチーム数
      - 🟡 待機中（Waiting）: 次・招集待ちのチーム数
    - **状態フィルターチップ**: 【すべて】【試合中のみ】【待機中のみ】
    - **部門・コート切り替えタブ & 横スワイプ (`PageView`)**:
      - 「すべて」「小学生の部」「中学生男子」等のタブ。画面左右スワイプで切り替え
    - **チーム進捗カード (`TeamStatusCard`)**:
      - チーム名、ステータスバッジ（🔴 試合中、🟡 待機中、⚪ 終了）
      - 現在の対戦相手、コート名、試合順、進行中ポジション（例: 中堅戦進行中）
      - **BAND共有ボタン**: チームの現在進行状況を外部チャットへ共有
      - **タップ遷移**: 団体戦は「団体戦スコアボード」、個人戦は「試合記録画面」へジャンプ
  - [x] **団体戦スコアボード (`TeamScoreboardScreen` / `/team-scoreboard/:groupName`)**:
    - **対戦ヘッダー**: 赤チーム vs 白チーム、対戦名（例: 準決勝 第1試合）
    - **スコアボードテーブル**:
      - ポジション行: 先鋒・次鋒・中堅・副将・大将（・代表戦）
      - 赤選手名、赤打突記号、白打突記号、白選手名（先取 `◯反`・不戦勝 `◯`・左下 `△` 累積準拠）
      - 行タップで当該ポジションの試合記録画面へジャンプ
    - **合計集計行 (`buildTotalRow`)**:
      - **勝者数（勝数）** ＆ **取得総本数（本数）** の自動リアルタイム集計表示（例: 3(5) - 1(2) ※代表戦スコアは団体合計に加算しない）
    - **代表戦ボタン (`TeamScoreboardDaihyoHandler`)**:
      - 勝数・本数が同点（引き分け）かつ代表戦許可設定時、最下部に**「代表戦を追加する」**ボタンが自動出現
      - タップで `$redTeam : 代表選手` / `$whiteTeam : 代表選手` の仮名で代表戦カードを即時生成し、試合記録画面への遷移確認ダイアログを表示（選手名は試合側で変更可能、一本勝負設定は `isDaihyoIpponShobu` に準拠）

* **現行マニュアル（PDF P26〜P28）との差分**:
  1. **カードタップ時の遷移先の明確化**:
     * 団体戦は勝敗一覧が分かる「団体戦スコアボード」へ、個人戦は「試合画面」へ自動分岐する仕様を明記。
  2. **団体戦スコアボードの勝者数・取得本数自動集計 & 代表戦非加算**:
     * 先鋒〜大将の試合結果から勝数と総本数を自動計算（代表戦のスコアは団体合計に加算しない公式規約準拠）する仕組みを明記。
  3. **代表戦の自動判定ボタン & BAND共有機能**:
     * 同点時に最下部へ自動出現する「代表戦を追加する」ボタンと、外部チャットへ状況をシェアできるBAND共有ボタンの役割を追記。

* **PDF・マニュアル用スクショ撮影・差し替え指示リスト（全3枚）**:
  * `[SS-10-1]` **差し替え**｜**画面**: チーム試合状況画面（`TeamMatchStatusScreen`）｜**撮影状態**: サマリーバッジ、状態フィルター、チーム進捗カード一覧が見えている状態｜**差し替え先**: 配布用PDF 第4章 P26「チーム試合状況」／`operator/team_match_status.md`
  * `[SS-10-2]` **差し替え**｜**画面**: 団体戦スコアボード画面（`TeamScoreboardScreen`）｜**撮影状態**: 先鋒〜大将の星取表と合計行（勝者数・本数）が表示された状態｜**差し替え先**: 配布用PDF 第4章 P27「団体戦スコアボード」／`operator/team_match_status.md`
  * `[SS-10-3]` **差し替え**｜**画面**: 団体戦スコアボード画面（代表戦ボタン出現時）｜**撮影状態**: 同点時に最下部に赤い「代表戦を追加する」ボタンが出ている状態｜**差し替え先**: 配布用PDF 第4章 P28「代表戦の追加」／`operator/team_match_status.md`

---

### 【Step 11/27】通常大会ドック（プログラム・チーム状況・サブタイマー・背面操作）
* **対象マニュアル**: [`packages/documentation_runtime/manuals/operator/dock_guide.md`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/packages/documentation_runtime/manuals/operator/dock_guide.md)
* **コード根拠**:
  * フローティングドック親ボタン: [`lib/features/tournament/presentation/components/program_management/floating_program_dock_button.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/components/program_management/floating_program_dock_button.dart)
  * スピードダイヤル項目生成（全9機能）: [`floating_dock_items_builder.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/components/program_management/floating_dock_items_builder.dart)
  * ドック可動ボトムシート: [`dock_draggable_sheet.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/components/program_management/dock_draggable_sheet.dart)
  * 背面操作可能オーバーレイマネージャー: [`floating_dock_sheet_manager.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/components/program_management/floating_dock_sheet_manager.dart)
  * サブタイマーボトムシート: [`dock_timer_bottom_sheet.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/components/program_management/dock_timer_bottom_sheet.dart)
  * ジグル並び替えシート: [`dock_items_reorder_bottom_sheet.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/components/program_management/dock_items_reorder_bottom_sheet.dart)

* **UI全要素リスト**:
  - [x] **フローティングドックボタン (`FloatingProgramDockButton`)**:
    - 画面右下常駐の円形FABボタン（剣道面ロゴ）
    - タップで「L字型スピードダイヤル」がアニメーション展開
  - [x] **全9つのスピードダイヤル機能項目 (`FloatingDockItemsBuilder`)**:
    1. **📄 プログラム**: 大会プログラム（PDF/画像・手書きペン・ズーム対応）
    2. **🥋 試合状況**: チーム試合状況（進行中・待機中サマリー、全画面切り替え対応）
    3. **📊 対戦表**: 公式記録・成績サマリー・全試合結果
    4. **🖌️ クイックメモ**: 手書きキャンバス＆テキスト入力の即席メモ
    5. **⏱️ タイマー**: ドック専用サブタイマー（プリセット2/3/4/5分・ホイールピッカー）
    6. **📲 観戦QR**: 観客・保護者用リアルタイム共有QRコード表示
    7. **🔔 お知らせ**: 運営本部からのアナウンス履歴（未読バッジ付き）
    8. **❓ ヘルプ**: 操作マニュアルボトムシート
    9. **⚙️ 設定**: 試合設定・表示モード変更
  - [x] **ジグル（Jiggle）並び替え機能 (`DockItemsReorderBottomSheet`)**:
    - 任意のドックアイコンを長押しすると、アイコンが揺れるジグルモードへ移行
    - ドラッグ＆ドロップで好みの配置順にカスタマイズ可能
  - [x] **Googleマップ型可動ボトムシート (`DockDraggableSheet`)**:
    - 3段階の高さ制御:
      - 最小化 / 下部フリックで閉じる（0.25）
      - 中間（0.58）: 上半分で背面画面を見通しながら下半分で作業
      - 全開（0.95）: 画面全体で閲覧
    - ヘッダーバーの全画面アイコン（⤢）で通常ページへ移行可能
  - [x] **背面操作可能アーキテクチャ (`FloatingDockSheetManager`)**:
    - `OverlayEntry` 直接描画によりモーダルブロックを完全排除
    - シートを開いたまま背面のスコア入力やタイマー操作を同時実行可能

* **現行マニュアル（PDF P22〜P25）との差分**:
  1. **全9機能の完全網羅**:
     * 旧マニュアル記載の4機能から、クイックメモ、サブタイマー、観戦QR、お知らせ、ヘルプを含む全9機能へ拡充。
  2. **ジグル並び替え機能の記載**:
     * ドックアイコン長押しによるカスタマイズ配置機能を追加。
  3. **背面操作可能UIの明記**:
     * パネルを開いたまま背後の試合記録やスコアボードを直接タップできる現場特化仕様を解説。
  4. **ドック専用サブタイマーの仕様**:
     * プリセット時間選択やカウントダウン通知の仕組みを明記。

* **PDF・マニュアル用スクショ撮影・差し替え指示リスト（全3枚）**:
  * `[SS-11-1]` **差し替え**｜**画面**: フローティングドック展開状態（`FloatingProgramDockButton`）｜**撮影状態**: 右下にL字型で9個のアイコンが展開した状態｜**差し替え先**: 配布用PDF 第3章 P22「通常大会ドックメニュー」／`operator/dock_guide.md`
  * `[SS-11-2]` **差し替え**｜**画面**: ドックシート展開中の背面操作状態（`DockDraggableSheet`）｜**撮影状態**: 上半分で試合記録、下半分でプログラムシートが出ている状態｜**差し替え先**: 配布用PDF 第3章 P23〜P24「背面操作と3段階シート」／`operator/dock_guide.md`
  * `[SS-11-3]` **新規追加**｜**画面**: ジグル並び替えシート（`DockItemsReorderBottomSheet`）｜**撮影状態**: ドックアイコン長押しでアイコンが揺れて並び替え可能な状態｜**差し替え先**: 配布用PDF 第3章 P25「アイコン並び替え」／`operator/dock_guide.md`

---

## 【Phase 4: 部内戦・練習試合・部内戦ドック】（PDF第5章 P29〜P33）

### 【Step 12/27】部内戦・練習試合の管理（カレンダー・4大モード・待機列・無限勝ち抜き）
* **対象マニュアル**: [`packages/documentation_runtime/manuals/operator/bunaiksen.md`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/packages/documentation_runtime/manuals/operator/bunaiksen.md)
* **コード根拠**:
  * 部内戦セットアップ画面: [`lib/features/tournament/presentation/operate/screens/bunaiksen_setup_screen.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/operate/screens/bunaiksen_setup_screen.dart)
  * 個人戦タブ: [`bunaiksen_individual_tab.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/operate/components/bunaiksen_setup/bunaiksen_individual_tab.dart)
  * 団体戦タブ: [`bunaiksen_team_tab.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/operate/components/bunaiksen_setup/bunaiksen_team_tab.dart)
  * リーグ戦タブ: [`bunaiksen_league_tab.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/operate/components/bunaiksen_setup/bunaiksen_league_tab.dart)
  * 無限勝ち抜きタブ: [`bunaiksen_infinite_tab.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/operate/components/bunaiksen_setup/bunaiksen_infinite_tab.dart)
  * 部内戦ホーム画面: [`lib/features/tournament/presentation/operate/screens/bunaiksen_home_screen.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/operate/screens/bunaiksen_home_screen.dart)
  * リーダーボードカード: [`bunaiksen_leaderboard_card.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/operate/components/bunaiksen/bunaiksen_leaderboard_card.dart)
  * クイック対戦シート: [`bunaiksen_quick_match_sheet.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/operate/components/bunaiksen/bunaiksen_quick_match_sheet.dart)
  * 日付選択アクション: [`bunaiksen_home_action_helper.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/operate/components/bunaiksen/bunaiksen_home_action_helper.dart)

* **UI全要素リスト**:
  - [x] **部内戦セットアップ画面 (`BunaiksenSetupScreen`)**:
    - **ルール設定カード (`BunaiksenRuleSettingsCard`)**:
      - 試合時間（デフォルト2.0分）、一本勝負/二本先取、延長時間・無制限トグル
    - **4つの対戦セットアップタブ**:
      1. **個人戦 (即スタート)**: 赤・白選手入力（マスタ自動サジェスト・卒業生フィルター対応）、即時試合開始
      2. **団体戦 (紅白戦)**: 道場生マスタから赤組・白組へ選手をタップ配置
      3. **リーグ戦 (総当たり)**: 参加選手を選択し総当たり星取表を一括自動生成
      4. **無限戦 (勝ち残り)**:
         - 待機列（Queue）一括選択
         - ドラッグ＆ドロップ並び替え (`ReorderableListView`)
         - 「シャッフル」ボタンによる順番ランダム化
         - 勝者残留＆敗者最後尾循環システム
  - [x] **部内戦ホーム画面 (`BunaiksenHomeScreen`)**:
    - **ヘッダーバー**:
      - 日付表示「yyyy/MM/dd 部内戦」
      - 📅 **日付選択カレンダーアイコン**: 過去の部内戦記録（試合が存在する日）を瞬時にロード
      - **観戦プレビューアイコン (`Icons.preview_rounded`)**: 観客・保護者用画面をワンタップで確認（v1.1.0アイコン刷新）
      - 📊 **成績一覧アイコン**: 部内戦公式記録（`/bunaiksen-record`）へジャンプ
    - **下スワイプ強制同期 (Pull-to-Refresh)**:
      - 画面を下スワイプして本日の部内戦スコアを即座に強制再同期
    - **無限勝ち抜きリーダーボードカード (`BunaiksenLeaderboardCard`)**:
      - 現在の王座、連勝数ランキング、取得本数上位者をリアルタイム表示
    - **対戦タイムライン ＆ 浮遊カプセル型スワイプ (`AppSlidableAction`)**:
      - 紅白戦・個人戦・リーグ戦・無限戦の対戦カード（不戦勝は通常丸 `◯` 表示に統一）
      - iOSメモ風の浮遊カプセル型スワイプ（編集・削除）
    - **クイック対戦シート呼出ボタン (`BunaiksenQuickMatchSheet`)**:
      - カプセル型デザイン、練習途中の飛び入り対戦を即座に割り込み作成
    - **部内戦専用ドックボタン (`BunaiksenDockButton`)**:
      - 画面右下に常駐（部内戦専用機能群を呼び出し）

* **現行マニュアル（PDF P29〜P31 / v1.0.0）との差分**:
  1. **【v1.1.0是正】部内戦不戦勝表示の統一（`◯`）＆ 観戦プレビューアイコン刷新（`Icons.preview_rounded`）**:
     * 不戦勝時の二重丸（`◎`）を廃止し通常丸（`◯`）へ統一した点、およびAppBarの観戦プレビューアイコンが刷新された点を反映。
  2. **無限戦の待機列管理（ドラッグ並び替え＆シャッフル）の明記**:
     * 選手を直感的に並び替えたりシャッフルして勝ち抜き戦を行える詳細仕様を追加。
  3. **カレンダー機能・リーダーボード・クイック対戦シート**:
     * 過去部内戦の即時閲覧、連勝王座ランキング、飛び入り対戦割り込み作成の仕様を明記。

* **PDF・マニュアル用スクショ撮影・差し替え指示リスト（全3枚）**:
  * `[SS-12-1]` **差し替え**｜**画面**: 部内戦セットアップ画面（`BunaiksenSetupScreen`）｜**撮影状態**: 4つのタブと無限戦の待機列（シャッフルボタン・Reorderリスト）が見えている状態｜**差し替え先**: 配布用PDF 第5章 P29「部内戦セットアップ」／`operator/bunaiksen.md`
  * `[SS-12-2]` **差し替え**｜**画面**: 部内戦ホーム画面（`BunaiksenHomeScreen`）｜**撮影状態**: ヘッダーの日付・新観戦プレビューアイコン（`preview_rounded`）、連勝リーダーボード、対戦カード一覧が出ている状態｜**差し替え先**: 配布用PDF 第5章 P30「部内戦ホーム画面」／`operator/bunaiksen.md`
  * `[SS-12-3]` **差し替え**｜**画面**: 日付選択カレンダーダイアログ｜**撮影状態**: 過去の部内戦開催日を選択するピッカーが出ている状態｜**差し替え先**: 配布用PDF 第5章 P31「過去部内戦の参照」／`operator/bunaiksen.md`

---

### 【Step 13/27】部内戦専用ドック（カレンダー・試合一覧・連勝・電卓・ジグル並び替え）
* **対象マニュアル**: 新設 [`packages/documentation_runtime/manuals/operator/bunaiksen_dock_guide.md`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/packages/documentation_runtime/manuals/operator/bunaiksen_dock_guide.md)
* **コード根拠**:
  * 部内戦専用ドック親ボタン: [`lib/features/tournament/presentation/components/bunaiksen/bunaiksen_dock_button.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/components/bunaiksen/bunaiksen_dock_button.dart)
  * カレンダーシート: [`bunaiksen_dock_calendar_sheet.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/components/bunaiksen/bunaiksen_dock_calendar_sheet.dart)
  * 試合一覧シート: [`bunaiksen_dock_matches_sheet.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/components/bunaiksen/bunaiksen_dock_matches_sheet.dart)
  * 順位・連勝表シート: [`bunaiksen_dock_standings_sheet.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/components/bunaiksen/bunaiksen_dock_standings_sheet.dart)
  * 試合数計算シミュレーター（電卓）: [`bunaiksen_dock_calculator_sheet.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/components/bunaiksen/calculator/bunaiksen_dock_calculator_sheet.dart)
  * 部内戦ドック並び順プロバイダ: [`bunaiksen_dock_items_order_provider.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/providers/bunaiksen_dock_items_order_provider.dart)

* **UI全要素リスト**:
  - [x] **部内戦専用ドックボタン (`BunaiksenDockButton`)**:
    - 画面右下常駐のFABボタン
    - 画面端（左右）への**マグネット吸着・自動格納（幅20px）**機能
  - [x] **部内戦特化の全8大スピードダイヤル項目（`BunaiksenDockItemTypeExtension.label` 準拠）**:
    1. **📋 対戦一覧 (`matches`)**: 本日の全試合カード・スコア確認
    2. **🏆 成績・星取表 (`standings`)**: 個人勝率ランキング・王座連勝記録
    3. **📅 カレンダー (`calendar`)**: 過去の稽古日部内戦の即時ロード
    4. **🧮 試合数計算 (`calculator`)**: 残り稽古時間・人数・コート配分シミュレーション
    5. **🖌️ クイックメモ (`quickMemo`)**: 手書き＆テキストメモ
    6. **⏱️ タイマー (`timer`)**: 稽古・合議・休憩用サブタイマー
    7. **📲 観戦QR (`viewerQr`)**: 保護者向け速報QRコード
    8. **⚙️ 設定 (`settings`)**: システム設定
  - [x] **iOS風画面上ジグル（Jiggle）並び替え機能**:
    - アイコン長押しで直接画面上の全アイコンが小刻みに揺れ始め、ドラッグ＆ドロップでスロット順序を直感的に入れ替え可能
  - [x] **Googleマップ型可動ボトムシート ＆ 背面操作可能UI**:
    - `OverlayEntry` により、シートを開いたまま手元の部内戦スコアを連続記録可能

* **現行マニュアル（PDF P32〜P33）との差分**:
  1. **通常ドックと部内戦ドックの明確な機能差の体系化**:
     * 通常大会用（プログラム等）と部内戦用（カレンダー・電卓・連勝）の違いを対比表で明確化。
  2. **試合数計算機（電卓）の存在**:
     * 稽古時間内に何試合消化できるかを瞬時に試算できる独自電卓機能を追加。
  3. **画面上直接ジグル並び替えの操作法 & 左右壁面マグネット吸着**:
     * アイコンが揺れるドラッグ＆ドロップ機能と、画面端へ小さく吸着させる仕様を明記。

* **PDF・マニュアル用スクショ撮影・差し替え指示リスト（全3枚）**:
  * `[SS-13-1]` **差し替え**｜**画面**: 部内戦専用ドック展開状態（`BunaiksenDockButton`）｜**撮影状態**: スピードダイヤルが展開され、カレンダー・電卓・連勝アイコンが見えている状態｜**差し替え先**: 配布用PDF 第5章 P32「部内戦ドック機能一覧」／`operator/bunaiksen_dock_guide.md`
  * `[SS-13-2]` **新規追加**｜**画面**: 試合数計算機（電卓）シート（`BunaiksenDockCalculatorSheet`）｜**撮影状態**: 稽古時間やコート配分シミュレーションが表示された状態｜**差し替え先**: 配布用PDF 第5章 P33「試合数計算シミュレーター」／`operator/bunaiksen_dock_guide.md`
  * `[SS-13-3]` **新規追加**｜**画面**: 画面上ジグル並び替え中の画面｜**撮影状態**: アイコンが揺れてドラッグ移動している状態｜**差し替え先**: 配布用PDF 第5章 P33「ドック並び替え」／`operator/bunaiksen_dock_guide.md`

---

## 【Phase 5: 結果集計・公式記録・PDF出力】（PDF第4章後半 P26〜P28, 第5章後半 P34）

### 【Step 14/27】成績管理・公式記録・PDF/CSV出力
* **対象マニュアル**: [`packages/documentation_runtime/manuals/operator/official_record.md`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/packages/documentation_runtime/manuals/operator/official_record.md)
* **コード根拠**:
  * 公式記録画面: [`lib/features/tournament/presentation/operate/official_record_screen.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/operate/official_record_screen.dart)
  * エクスポートアクションバー: [`official_record_export_bar.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/components/official_record/official_record_export_bar.dart)
  * カテゴリ別タブビュー: [`official_record_category_tab_view.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/components/official_record/official_record_category_tab_view.dart)
  * 遠征成績集計サマリーカード: [`official_record_expedition_summary_card.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/components/official_record/official_record_expedition_summary_card.dart)
  * エクスポートヘルパー: [`official_record_export_helper.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/components/official_record/official_record_export_helper.dart)
  * PDFルール要約フォーマッター: [`lib/features/pdf/helpers/pdf_rule_formatter.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/pdf/helpers/pdf_rule_formatter.dart)
  * PDFサービス: [`lib/features/pdf/pdf_service.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/pdf/pdf_service.dart)
  * 公式スコア表示仕様書: [`docs/domain/kendo_score_display_spec.md`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/docs/domain/kendo_score_display_spec.md)

* **UI全要素リスト**:
  - [x] **ヘッダーバー & 検索バー**:
    - タイトル「大会 公式記録」（閲覧者モード時は「全試合スコア」へ自動切り替え）
    - 🔍 **試合・選手名インクリメンタル検索バー**: 選手名・チーム名でリアルタイム絞り込み＆キーワードの蛍光黄色ハイライト（`AppHighlightText`）
    - ❓ ヘルプボタン
  - [x] **下スワイプ強制同期 (Pull-to-Refresh)**:
    - 画面を下スワイプして最新の全試合スコアを即時強制同期
  - [x] **遠征・戦績集計サマリーカード (`OfficialRecordExpeditionSummaryCard`)**:
    - **全体 / チーム別切り替えタブ**: 道場全体または各チーム別の勝率・勝数・本数
    - **個人別戦績アコーディオン**: 選手の勝敗、技内訳（面・小手・胴・突き・反則）、引き分け数一覧
    - **📲 LINE用にコピーボタン**: 保護者連絡網・LINEグループ用に美しく整形されたテキストを一瞬でコピー
    - ※ 観客（Viewer）画面では情報保護・公平性のため自動非表示（Parity規約）
  - [x] **部門別タブ切り替え (`TabBar` / `OfficialRecordCategoryTabView`)**:
    - 「小学生低学年」「中学生男子」等、部門ごとの独立タブ
  - [x] **エクスポートアクションバー (`OfficialRecordExportBar`)**:
    - **「全カテゴリを一括出力」トグルスイッチ (`AppSwitch`)**:
      - OFF: 表示中の部のみ出力
      - ON: 全カテゴリ・全対戦を一括出力
    - **📄 PDF出力ボタン (`Icons.print`)**:
      - A4高コントラスト組版（日本剣道連盟書式準拠）、ブラウザ自動ダウンロード、モバイルAirPrint・共有シート対応
      - **基本ルール要約の自動印字 (`PdfRuleFormatter`)**: 試合時間・勝負形式・延長・判定・代表戦などの適用ルールをPDFヘッダー/フッターに自動出力
    - **🖼️ 画像出力ボタン (`Icons.ios_share`)**:
      - LINEグリーン（#06C755）カラー、SNS/LINE用画像共有に特化
    - **📊 CSV出力ボタン (`Icons.table_chart`)**:
      - Excel/スプレッドシート用生データ出力
  - [x] **対戦別スコアカード (`OfficialRecordScoreTableBuilder`)**:
    - 団体戦（先鋒〜大将・代表戦、勝者数・取得本数、勝利判定マーク、代表戦非加算）
    - 個人戦・勝ち抜き戦・リーグ戦（星取表：勝ち `◯` / 負け `▲` / 引き分け `□` / 対角斜線）
    - 公式記録表示準拠（先取 `◯反`、不戦勝 `◯`、延長戦縦書き表記、反則警告 `△` 左下累積最大4個）
  - [x] **フローティングドック統合**:
    - ドックからの呼び出し時は Googleマップ型可動ボトムシート（全画面切り替え対応）として展開

* **現行マニュアル（PDF P34 / v1.0.0）との差分**:
  1. **【v1.1.0正本化】剣道公式スコア・星取表・PDF描画規約 (`kendo_score_display_spec.md`)**:
     * 3本勝負1本目（先取）の反則 `◯反`、不戦勝 `◯`（二重丸廃止）、延長戦縦書き「延長」、反則警告 `△` 左下独立累積、リーグ表記号（`◯`/`▲`/`□`）の公式準拠仕様を明記。
  2. **基本ルール要約のPDF自動印字 (`PdfRuleFormatter`) & 3大出力形式（PDF・画像・CSV）**:
     * 適用ルールの自動印字、LINE用画像出力ボタン（#06C755）、「全カテゴリを一括出力」トグルスイッチ仕様を明記。
  3. **インクリメンタル検索（黄色ハイライト）& 遠征サマリーの観客非表示（Parity規約）**:
     * 選手・チーム名検索と、保護者報告用LINEコピー（観客画面では自動非表示）を明記。

* **PDF・マニュアル用スクショ撮影・差し替え指示リスト（全3枚）**:
  * `[SS-14-1]` **差し替え**｜**画面**: 公式記録画面全体（`OfficialRecordScreen`）｜**撮影状態**: エクスポートバー、遠征サマリーカード、部門タブ、公式表記スコアカードが表示された状態｜**差し替え先**: 配布用PDF 第5章 P34「公式記録画面」／`operator/official_record.md`
  * `[SS-14-2]` **差し替え**｜**画面**: エクスポートバー（全カテゴリ一括スイッチON）｜**撮影状態**: トグルがONになり、各ボタンが「PDF（全）」「CSV（全）」に変化した状態｜**差し替え先**: 配布用PDF 第5章 P34「一括エクスポート」／`operator/official_record.md`
  * `[SS-14-3]` **差し替え**｜**画面**: 公式記録画面（インクリメンタル検索中）｜**撮影状態**: 検索バーに選手名が入力され、該当箇所が蛍光黄色ハイライトされた状態｜**差し替え先**: 配布用PDF 第5章 P34「選手・チーム検索」／`operator/official_record.md`

---

### 【Step 15/27】順位表・戦績ランキング（リーグ勝ち点・日本伝統勝率表記）
* **対象マニュアル**: [`packages/documentation_runtime/manuals/operator/standings.md`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/packages/documentation_runtime/manuals/operator/standings.md)
* **コード根拠**:
  * 順位表画面: [`lib/features/tournament/presentation/screens/standings_screen.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/screens/standings_screen.dart)

* **UI全要素リスト**:
  - [x] **ヘッダーバー & ナビゲーション**:
    - 戻るボタン、タイトル「成績・順位表」、フローティングドックボタン
  - [x] **順位決定ロジック（厳格な4段階ソート優先順位）**:
    1. **勝ち点（Match Points）**: リーグ戦設定の勝敗ポイント（最優先）
    2. **勝利数（Wins）**: 勝ち数が多い順
    3. **敗戦数（Losses）**: 負け数が少ない順
    4. **総取得本数（Points Scored）**: 獲得した一本の総数が多い順
  - [x] **完全同点（Tie）検出ロジック（`tieGroups`）**:
    - 内部ロジックでは勝ち点・勝敗数・総本数が並んだグループ（`tieGroups`）を算出（※v1.1.0 現行 UI 上には同点アラートバナーは未描画）
  - [x] **日本伝統の勝率表記（三桁形式）**:
    - 全勝: `10割`
    - 勝率例: `8割5分7厘`、`7割5分`、`0割`
  - [x] **ランキングカードUI**:
    - 金・銀・銅メダルアイコン（1位〜3位を表彰カラーでハイライト）
    - 所属名接頭辞を除去したクリーンな選手名
    - 「勝率: 〇割〇分〇厘」バッジ
    - 詳細成績サブタイトル: 「X試合: Y勝 Z敗 W分 / 取得: N本」（※勝ち点はソート基準として使用し、カード詳細行には未表示）

* **現行マニュアルとの差分**:
  1. **順位決定の4段階優先順位（勝ち点 ➔ 勝利数 ➔ 敗戦数 ➔ 取得本数）の明記**:
     * 剣道公式ルールに即した順位決定の正確なロジックを解説。
  2. **金銀銅メダルバッジ ＆ 日本伝統勝率表記（〇割〇分〇厘）**:
     * 1位〜3位の視覚的ハイライト仕様と三桁勝率表記を追記。

* **PDF・マニュアル用スクショ撮影・差し替え指示リスト（全2枚）**:
  * `[SS-15-1]` **新規追加**｜**画面**: 順位表画面全体（`StandingsScreen`）｜**撮影状態**: 1位〜3位のメダルバッジ、勝率「〇割〇分〇厘」、詳細行が表示された状態｜**差し替え先**: 配布用PDF 第4章「成績・順位表」／`operator/standings.md`
  * `[SS-15-2]` **新規追加**｜**画面**: 順位表ランキングカード詳細｜**撮影状態**: 「X試合: Y勝 Z敗 W分 / 取得: N本」のサブタイトルが見えている状態｜**差し替え先**: 配布用PDF 第4章「成績・取得本数集計」／`operator/standings.md`

---

### 【Step 16/27】大会プログラム管理・手書きビューワー（共有ペン・個人ペン・ズーム排他・検索）
* **対象マニュアル**: [`packages/documentation_runtime/manuals/operator/program_management.md`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/packages/documentation_runtime/manuals/operator/program_management.md)
* **コード根拠**:
  * プログラム管理画面: [`lib/features/tournament/presentation/operate/screens/program_management_screen.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/operate/screens/program_management_screen.dart)
  * PDF自動軽量化ユーティリティ: [`lib/shared/utils/pdf_compressor.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/shared/utils/pdf_compressor.dart)
  * プログラムビューワー画面: [`lib/features/tournament/presentation/operate/screens/program_viewer_screen.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/operate/screens/program_viewer_screen.dart)
  * 手書き描画ツールバー: [`lib/features/tournament/presentation/components/program_viewer/program_viewer_drawing_toolbar.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/components/program_viewer/program_viewer_drawing_toolbar.dart)
  * タイトル・並び替えダイアログ: [`program_title_preview_dialog.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/components/program_management/program_title_preview_dialog.dart)
  * クリップボード貼り付けヘルパー: [`clipboard_program_helper.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/operate/helpers/clipboard_program_helper.dart)
  * ドック連携ボトムシート: [`program_bottom_sheet.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/components/program_management/program_bottom_sheet.dart)

* **UI全要素リスト**:
  - [x] **プログラム管理画面 (`ProgramManagementScreen` / `/program-management`)**:
    - **ヘッダーバー**:
      - 戻るボタン、タイトル「プログラム管理」
      - グリッド/リスト切り替えアイコン (`_isGridView`)
      - 複数選択時の「ゴミ箱」一括削除アイコン (`confirmBulkDelete`)
    - **下スワイプ強制同期 (Pull-to-Refresh)**:
      - 画面を下スワイプしてクラウド上の最新プログラム一覧を即時再取得
    - **アップロードFAB＆追加ボトムシート (`_showPickerMenu`)**:
      - 📷 **写真ライブラリから選ぶ (複数可)**: JPEG/PNG画像を複数選択
      - 📄 **ファイルから選ぶ (複数可)**: PDF/画像ファイルを複数選択
      - 📋 **クリップボードから貼り付け (`ClipboardProgramHelper`)**: コピーした画像やURLから即座に追加
    - **検索性を維持したPDF自動軽量化 (`PdfCompressor`) ＆ 削減量トースト**:
      - 3MB以上の大容量PDFを対象にバックグラウンド（Isolate）で自動最適化を実行
      - テキストレイヤー・OCR検索性を100%保護しながらファイルサイズを大幅削減
      - アップロード完了トーストに削減量（例: `PDF軽量化: 3.2 MB削減 (3.5秒)`）を表示
    - **タイトル・並び替えプレビューダイアログ (`ProgramTitlePreviewDialog`)**:
      - 選択した複数ファイルの順序をドラッグ並び替え
      - ベースタイトル入力（複数時は自動で「タイトル (1/N)」とナンバリング付与）
    - **プログラムカード一覧**:
      - サムネイル、タイトル、ページ数バッジ、OCRテキスト化バッジ
      - 浮遊カプセル型スワイプアクション（個別編集・削除）
      - 長押しで複数選択モード突入、タップでビューワー起動
  - [x] **プログラムビューワー画面 (`ProgramViewerScreen` / `/program-viewer`)**:
    - **直交ナビゲーション（直感的な2軸スクロール）**:
      - **縦スクロール**: 同一PDF内のページめくり
      - **横スワイプ (`PageView`)**: ファイル間切り替え（例: 進行表 ➔ 第1試合場 ➔ 第2試合場）
      - **ピンチズーム排他制御**: 拡大中（scale > 1.01）は横スワイプを完全ロックし、手書き中の誤ファイル切替を防止
    - **アプリバー**:
      - ファイルタイトル、ページ番号表示（P.X / Y）
      - 🔍 **PDFテキスト全文検索ボタン**: インクリメンタル検索バー展開、前へ/次へ、マッチ件数表示
      - ✏️ **描画モード切替ボタン**: 手書きツールバーの展開/格納
      - ⤢ 全画面表示 / 閉じるボタン
    - **手書き描画ツールバー (`ProgramViewerDrawingToolbar`)**:
      - **📢 共有ペン（ピンク・イエロー）**: 運営者専用、Firestore経由で全端末（観客含む）へリアルタイム同期
      - **👤 個人ペン（ブルー・ブラック）**: 全員利用可能、端末ローカル（Isar）のみ保存（他端末には非公開）
      - **🖍️ 蛍光マーカー**: 半透明乗算合成によるハイライト
      - **🧹 ストローク消しゴム** / **↩️ Undo** / **🗑️ 全消去**（観客端末では本部の共有ペン消去を保護ガード）
  - [x] **フローティングドック連携 (`ProgramBottomSheet`)**:
    - 試合中やドックから開くクイック確認シートから、画面上部の⤢アイコンで全画面ビューワーへワンタップ展開

* **現行マニュアルとの差分**:
  1. **文字検索を維持したPDF自動軽量化と削減量トースト表示**:
     * 3MB以上の重いプログラムPDFでもOCR検索性を失わずに自動最適化し、トーストで削減量（MB）を可視化する仕様を明記。
  2. **クリップボード直接貼り付け＆タイトル自動ナンバリング**:
     * コピー画像・URLの即座登録と複数ファイル並び替え＋`(1/N)`ナンバリングを解説。
  3. **共有ペン（ピンク・黄）と個人ペン（青・黒）の分離 ＆ ピンチズーム排他制御**:
     * 権限・同期先の違いと、拡大観察中の誤スワイプロック仕様を明記。

* **PDF・マニュアル用スクショ撮影・差し替え指示リスト（全3枚）**:
  * `[SS-16-1]` **新規追加**｜**画面**: プログラム管理画面（`ProgramManagementScreen` + アップロードメニュー）｜**撮影状態**: リスト/グリッド表示と追加ボトムシート（写真・ファイル・クリップボード）が出ている状態｜**差し替え先**: 配布用PDF 第3〜5章「プログラム登録・軽量化」／`operator/program_management.md`
  * `[SS-16-2]` **差し替え**｜**画面**: プログラムビューワー手書き描画モード（`ProgramViewerScreen`）｜**撮影状態**: 上部に手書きツールバーが開き、共有ペン・個人ペン・消しゴムが選択可能な状態｜**差し替え先**: 配布用PDF 第3〜5章「プログラム手書きメモ」／`operator/program_management.md`
  * `[SS-16-3]` **新規追加**｜**画面**: プログラムビューワー（PDFテキスト全文検索中）｜**撮影状態**: 上部検索バーに文字が入力され、該当箇所がハイライトされた状態｜**差し替え先**: 配布用PDF 第3〜5章「PDF全文検索」／`operator/program_management.md`

---

## 【Phase 6: システム設定・監視・監査・障害復旧】（PDF第6章 P35〜P37）

### 【Step 17/27】システム設定（サンシャインモード・サーマル冷却・道場PIN管理・サポート）
* **対象マニュアル**: [`packages/documentation_runtime/manuals/operator/settings.md`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/packages/documentation_runtime/manuals/operator/settings.md)
* **コード根拠**:
  * 設定画面本体: [`lib/features/tournament/presentation/operate/settings_screen.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/operate/settings_screen.dart)
  * 設定セクション群: [`settings_sections.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/operate/components/settings/settings_sections.dart)
  * 道場セキュリティ・PIN管理セクション: [`dojo_security_settings_tile.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/operate/components/settings/dojo_security_settings_tile.dart) / [`dojo_security_settings_sheet.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/operate/components/settings/dojo_security_settings_sheet.dart) / [`dojo_owner_accounts_card.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/operate/components/settings/dojo_owner_accounts_card.dart)
  * サポート・規約セクション: [`settings_support_section.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/operate/components/settings/settings_support_section.dart)
  * アプリ内規約・情報定数: [`lib/shared/constants/legal_texts.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/shared/constants/legal_texts.dart)
  * サーマル冷却ガバナー: [`lib/shared/application/services/thermal_power_governor.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/shared/application/services/thermal_power_governor.dart)
  * サーマルバッジ・解説シート: [`lib/shared/widgets/thermal_status_badge.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/shared/widgets/thermal_status_badge.dart)
  * WebアプリQRダイアログ: [`web_app_qr_dialog.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/operate/components/settings/web_app_qr_dialog.dart)
  * BAND設定タイル: [`lib/features/band/presentation/components/band_settings_section.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/band/presentation/components/band_settings_section.dart)

* **UI全要素リスト**:
  - [x] **ヘッダーバー & ドック連携**:
    - 戻るボタン、タイトル「システム設定」、マニュアルヘルプボタン
    - ドックから呼び出し時はボトムシートとして開き、ヘッダーの全画面アイコンで `/settings` へ移行可能
  - [x] **表示と画面セクション (`SettingsDisplaySection`)**:
    - **外観テーマ (`themeMode`)**: 【端末連動】【ライト】【ダーク】【☀️ サンシャイン】
      - サンシャインモード: 体育館の直射日光・反射光対策。純白×漆黒の最高コントラスト比（21:1 WCAG AAA適合）
    - **文字サイズ (`textSizeMode`)**: 【標準】【大】【特大】
      - 体育館での遠距離視認や年長者・審判の先生方の操作性を向上
    - **スリープ(画面消灯)防止 (`sleepPrevent`)**: 長時間の試合記録中の画面ロックを防止
    - **省エネモード (`!enableLiquidGlass`)**: 背景の流体アニメーションを停止し省電力化
    - **サーマル冷却・省電力制御バッジ (`ThermalStatusBadge`)**:
      - 端末発熱やバッテリー状態をリアルタイム表示（⚡高速 / 🔋エコ冷却 / 🌿極限省電力）
      - タップで「サーマル制御詳細＆時間精度100%保証」解説シートを表示
  - [x] **音と振動・フィードバックセクション (`SettingsSoundHapticsSection`)**:
    - **音声・サウンド設定 (`audioFeedbackMode`)**: 【OFF】【効果音】【音声読み上げ】
    - **マナーモード時も強制的に鳴らす (`ignoreMannerMode`)**: 騒音下でも試合終了ブザーを確実に鳴動
    - **触覚フィードバック（階層化ハプティクス / `haptic`）**: 操作内容に応じた振動通知（タイマー:軽、一本:強、反則:2連、取消:長）
  - [x] **プッシュ通知設定セクション (`SettingsPushNotificationSection`)**:
    - 緊急連絡・本部アナウンスの通知 (`notifyOnEmergency`)
    - 新着試合追加の通知 (`notifyOnMatchAdded`)
    - 試合開始の通知 (`notifyOnMatchStarted`)
    - 試合結果・終了の通知 (`notifyOnResult`)
    - ※ iPhone/iPad/Web（PWAホーム画面追加）対応
  - [x] **外部連携・LIVE配信セクション (`BandSettingsTile`)**:
    - 低学年・高学年ごとのBANDグループURL登録
    - 試合カードからワンタップで対戦情報をコピーして配信起動、道場ID内全端末自動同期
  - [x] **道場セキュリティ・PIN管理（管理者限定 / `DojoSecuritySettingsSection`）** *(v1.1.0新設)*:
    - ※ `UserRole.admin` のみ表示
    - **道場入室PIN・ロールPINの変更 (`DojoSecuritySettingsSheet`)**:
      - 現在のAdmin PIN入力による本人確認（ロック解除）
      - 解除後、現在の入室PIN・Admin/Operator/Recorder PINを**初期マスク表示（`Icons.visibility_off`）**で表示し、目アイコンで個別表示切替
      - 入室PIN（合言葉）および各ロールPIN（4桁数字）の個別変更保存
    - **代表者Googleアカウント管理・引き継ぎ (`DojoOwnerAccountsCard`)**:
      - PIN初期化・代替わり引き継ぎ用の代表者Googleアカウントを**最大5名**まで登録・削除可能
      - 「現在ログイン中のGoogleを登録」またはメールアドレス直接追加
  - [x] **サポート・規約・情報セクション (`SettingsSupportSection`)**:
    - **お問い合わせ（Googleフォーム外部連携）**:
      - タップで直接外部ブラウザを起動（`https://forms.gle/rymMtJUyhWNtrD819`）※アプリ内でのQRコード表示はなし
    - **操作マニュアル**: 画面別・ロール別公式マニュアル一覧起動
    - **利用規約 (`LegalDocumentDialog.show`)**: オフライン完全対応・高速スクロールダイアログ
    - **プライバシーポリシー (`LegalDocumentDialog.show`)**: 個人情報・戦績データの保護方針
    - **KendoSync について (`LegalDocumentDialog.show`)**: アプリ名称、バージョン表記（`v1.1.0`）、開発理念
    - **オープンソースライセンス (`showLicensePage`)**: Flutterおよび各オープンソースライブラリの権利表記
    - **デザインシステム・ギャラリー (`/design-gallery`)**: 開発・検証用のUIコンポーネント一覧（同セクション内実装）
  - [x] **ローカル保存と保護**:
    - **記録確定後の修正ロック (`isLocked`)**: 確定スコアの誤操作・改ざん防止
  - [x] **Webアプリ版（他端末アクセス） (`WebAppQrDialog`)**:
    - 他端末のブラウザでkendo_os本体を開くQRコード表示
  - [x] **アカウント管理**:
    - Googleアカウント連携・ログイン状態表示、ログアウト

* **現行マニュアル（PDF P35〜P37 / v1.0.0）との差分**:
  1. **【v1.1.0新機能】管理者限定「道場セキュリティ・PIN管理」＆「代表者Google引き継ぎ」**:
     * 初期PINから道場固有の入室PIN・各ロールPINへ変更する手順、本人確認後のマスク表示仕様、代替わり時の代表者Googleアカウント（最大5名）引き継ぎ運用を明記。
  2. **サポート・規約・情報セクションの追加**:
     * お問い合わせフォーム（GoogleフォームURL外部起動）、操作マニュアル、オフライン閲覧可能な規約・ポリシー・アプリ情報（`v1.1.0`）の仕様を明記。
  3. **文字サイズ（標準・大・特大）設定、BAND設定、記録確定ロック、Web版QRコード、PWA通知要件**:
     * 現場の視認性・運用性・セキュリティを高める全設定項目の仕様を網羅。

* **PDF・マニュアル用スクショ撮影・差し替え指示リスト（全6枚）**:
  * `[SS-17-1]` **差し替え**｜**画面**: 設定画面（表示と画面セクション）｜**撮影状態**: サンシャインモード、文字サイズ（標準/大/特大）、サーマル冷却バッジが見えている状態｜**差し替え先**: 配布用PDF 第6章 P35「表示・省電力設定」／`operator/settings.md`
  * `[SS-17-2]` **差し替え**｜**画面**: 設定画面（音と振動＆プッシュ通知セクション）｜**撮影状態**: 音声設定アコーディオン、マナーモード強制鳴動、4つの通知スイッチが見えている状態｜**差し替え先**: 配布用PDF 第6章 P36「音声・通知設定」／`operator/settings.md`
  * `[SS-17-3]` **差し替え**｜**画面**: 設定画面（外部連携・保護・Web版QRダイアログ）｜**撮影状態**: BAND設定、記録修正ロック、Web版QRコードが表示された状態｜**差し替え先**: 配布用PDF 第6章 P36〜P37「外部連携・Web版」／`operator/settings.md`
  * `[SS-17-4]` **差し替え**｜**画面**: 設定画面（サポート・規約セクション）｜**撮影状態**: お問い合わせリンク、操作マニュアル、利用規約・ポリシー・アプリ情報（`v1.1.0`）が見えている状態｜**差し替え先**: 配布用PDF 第6章 P37「サポート・規約・アプリ情報」／`operator/settings.md`
  * `[SS-17-5]` **新規追加**｜**画面**: 道場セキュリティ・PIN管理シート（`DojoSecuritySettingsSheet`）｜**撮影状態**: Admin本人確認後、現在PINがマスク表示（`••••`＋目アイコン）され、新PIN変更欄が見えている状態｜**差し替え先**: 配布用PDF 第6章「道場PIN・ロールPINの変更（管理者限定）」セクション新設／`operator/settings.md`
  * `[SS-17-6]` **新規追加**｜**画面**: 代表者Googleアカウント管理カード（`DojoOwnerAccountsCard`）｜**撮影状態**: 代表者メールアドレス一覧（最大5名）と「現在ログイン中のGoogleを登録」ボタンが見えている状態｜**差し替え先**: 配布用PDF 第6章「代表者引き継ぎ・PIN復旧準備」セクション新設／`operator/settings.md`

---

### 【Step 18/27】監査ログ・操作履歴（ゼロトラスト電子署名・改ざん防止・第203条規約）⚠️ Stage 2 β 非表示（総合取扱説明書から除外）
> **【総合取扱説明書 除外対象】**: Stage 2 β 版の利用方針により UI 上非表示（遷移導線なし）のため、総合取扱説明書（Google スライド）には掲載しません（内部仕様・`operator/audit_log.md` 向けの記録として保持）。
* **対象マニュアル**: [`packages/documentation_runtime/manuals/operator/audit_log.md`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/packages/documentation_runtime/manuals/operator/audit_log.md)（※配布用総合取扱説明書は除外）
* **コード根拠**:
  * 監査ログ画面: [`lib/admin/presentation/screens/audit_log_screen.dart:L28-L207`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/admin/presentation/screens/audit_log_screen.dart#L28-L207)
  * 監査プロバイダー: [`lib/admin/providers/audit_provider.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/admin/providers/audit_provider.dart)
  * 第203条署名検証・改ざん遮断: [`lib/features/match/application/mappers/score_event_legacy_adapter.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/match/application/mappers/score_event_legacy_adapter.dart)
  * 署名検証サービス: [`lib/shared/infrastructure/repository/match_signature_verifier.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/shared/infrastructure/repository/match_signature_verifier.dart)
  * 隔離・セーフモード: [`lib/shared/infrastructure/repository/local_match_repository.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/shared/infrastructure/repository/local_match_repository.dart)

* **UI全要素リスト**:
  - [x] **ヘッダーバー & 緊急ガイド連携**:
    - 戻るボタン、タイトル「システム監査ログ」
    - ❓ **マニュアルヘルプボタン (`ManualHelpButton`)**: 異常ログを発見した際に「緊急トラブル復旧ガイド（`failure_catalog.md`）」へ直行
  - [x] **試合ID絞り込み検索バー (`_filterMatchId`)**:
    - 試合IDのインクリメンタル検索フィールド（入力と同時にリアルタイムフィルタリング）
  - [x] **監査ログタイムラインリスト (`auditLogsProvider`)**:
    - 最新100件の操作ログをFirestoreからリアルタイムストリーム受信
    - **アクション重要度に応じた3色カラーアイコン分類**:
      - 🔵 **青色 (`AppKendoColors.blue`)**: 通常のスコア追加（`score_added`）、試合開始・終了等
      - 🟠 **橙色 (`AppKendoColors.orange`)**: 取り消し操作（`undo`）、スコア再構築（`rebuild`）等の巻き戻し
      - 🔴 **赤色 (`AppKendoColors.red`)**: 手動修正（`manual_update`）、強制権限取得（`force_claim`）等の高リスク介入
    - **各ログカードの表示項目**:
      - アクション名（太字）
      - 操作詳細メッセージ（`details`）
      - 試合ID（`matchId`）＆ 操作者ID（`userId`）
      - 発生日時（`MM/dd HH:mm:ss` 秒単位タイムスタンプ）
  - [x] **第203条ゼロトラスト電子署名・改ざん防止アーキテクチャ**:
    - **HMAC-SHA256電子署名**: スコアイベント発生時に端末秘密鍵で署名を付与し、完全性を数学的に保証
    - **改ざん検知・遮断**: 署名不一致イベントを検知した場合、`TamperedEventException` を送出して即座に処理拒絶
    - **クランティン（隔離退避）モード (`allowQuarantine: true`)**: 不正疑義データを安全に隔離領域へ退避し、正常データの破壊を防止
    - **署名キャッシュメモリ保護**: 5,000件超過時の自動LRUクリアによる省メモリ保証

* **現行マニュアル（PDF P35〜P37）との差分**:
  1. **第203条ゼロトラスト電子署名（HMAC-SHA256）の仕様解説**:
     * 単なる履歴表示ではなく、暗号署名によってデータの完全性が保証されている仕組みを明記。
  2. **重要度別3色カラーバッジ（青・橙・赤）の分類体系**:
     * 通常操作、巻き戻し、手動介入が視覚的に一目で区別できるログ仕様を追加。
  3. **クランティン隔離モードによるデータ保護の解説**:
     * 不正データや競合データが混入した際に自動退避して試合進行を継続する仕組みを追記。
  4. **緊急トラブル復旧ガイドへの直接連携**:
     * 監査ログ画面のヘルプボタンから直接障害復旧カタログを呼び出せる導線を明記。

* **PDF・マニュアル用スクショ撮影・差し替え指示リスト（全3枚）**:
  * `[SS-18-1]` **新規追加**｜**画面**: システム監査ログ画面（`AuditLogScreen`）｜**撮影状態**: 通常のスコア記録ログ（青アイコン）がタイムライン表示された状態｜**差し替え先**: 配布用PDF 第6章「システム監査ログ」／`operator/audit_log.md`
  * `[SS-18-2]` **新規追加**｜**画面**: システム監査ログ画面（重要度別バッジ混在）｜**撮影状態**: `undo`（橙）や `manual_update`（赤）の介入ログがハイライトされた状態｜**差し替え先**: 配布用PDF 第6章「重要度別ログ分類」／`operator/audit_log.md`
  * `[SS-18-3]` **新規追加**｜**画面**: システム監査ログ画面（試合ID絞り込み中）｜**撮影状態**: 検索バーに試合IDが入力され、該当試合の全操作履歴のみが抽出された状態｜**差し替え先**: 配布用PDF 第6章「試合IDによる追跡」／`operator/audit_log.md`

---

### 【Step 19/27】現場障害カタログ（YES/NO診断・オフライン復旧・第503/504条規約）
* **対象マニュアル**: [`packages/documentation_runtime/manuals/recovery/failure_catalog.md`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/packages/documentation_runtime/manuals/recovery/failure_catalog.md)
* **コード根拠**:
  * 第503条ツインエンジン永続化: [`lib/shared/infrastructure/persistence/twin_match_persistence_helper.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/shared/infrastructure/persistence/twin_match_persistence_helper.dart)
  * クラッシュ退避＆起動復旧: [`lib/shared/errors/emergency_crash_preserver.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/shared/errors/emergency_crash_preserver.dart)
  * 第504条障害データ隔離: [`lib/shared/domain/entities/match_corrupted_state.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/shared/domain/entities/match_corrupted_state.dart)
  * 破損警告バナー: [`lib/shared/widgets/corrupted_match_banner.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/shared/widgets/corrupted_match_banner.dart)
  * べき等キューイング: [`lib/shared/sync/pending_sync_queue.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/shared/sync/pending_sync_queue.dart)
  * 物理離脱防止ガード: `match_screen.dart` 内 `PopScope`

* **UI全要素リスト**:
  - [x] **YES/NO即答現場診断チャート**:
    - Q1: 画面タップ可能か？（YES ➔ オフライン継続 / NO ➔ リロード復元）
    - Q2: 赤色「破損警告バナー」が出ているか？（二次破壊阻止ロック・生データ救済エクスポート）
    - Q3: 端末物理破損か？（紙記録への一時切り替え ➔ 予備端末で即時復旧）
  - [x] **「⚠️ 体育館オフライン運営モード」警告バナー（`main.dart` / `home_screen.dart` インライン実装）**:
    - 通信ゼロ時もIsarローカルDBへ即時書き込み継続
    - 電波復帰時にバックグラウンドキュー（`PendingSyncQueue`）から自動一括同期
  - [x] **赤色「データ破損・隔離退避」警告バナー (`CorruptedMatchBanner`)**:
    - 二次破壊完全阻止: 打突・タイマー・編集の完全ロック (`allowEdit == false`)
    - 観戦パニック防止: 観客Viewerは直前状態のリアルタイム閲覧継続 (`allowViewer == true`)
    - 生データ救済: 「生データテキスト書き出し（エクスポート）」ボタン出現 (`allowExport == true`)
  - [x] **第503条 ツインエンジン自己修復 ＆ 起動時復元**:
    - Isar破損時もJSONバックアップから瞬時に自動修復
    - アプリ異常終了・OS再起動時も `EmergencyCrashPreserver` により直前スコア・残り秒数を100%自動復元
  - [x] **誤操作防止ガード (`PopScope`)**:
    - 試合計時中やスコア入力中の誤スワイプ・誤戻るタップによる画面離脱を完全防止

* **現行マニュアル（PDF P35〜P37）との差分**:
  1. **第503条ツインエンジン自己修復とFatal Crash Trapの明記**:
     * アプリが強制終了しても直前の状態が100%復元される仕組みを解説。
  2. **第504条障害データ隔離（Quarantine）と生データ救済の追加**:
     * 破損データ検知時の二次破壊阻止ロックと、生データテキスト救済ボタンの操作手順を追加。
  3. **YES/NO即答診断チャートの近代化**:
     * 現場でパニックにならず、10秒で自己判断できる体系的フローチャートを刷新。
  4. **予備端末への安全な引き継ぎフローの具体化**:
     * 端末物理故障時に、別スマホのブラウザ等から同一道場IDへ入って引き継ぐ手順を追記。

* **PDF・マニュアル用スクショ撮影・差し替え指示リスト（全3枚）**:
  * `[SS-19-1]` **差し替え**｜**画面**: 試合記録画面（オフライン警告バナー表示中）｜**撮影状態**: 上部に黄色い「オフライン運営中」バナーが表示され、通常通り入力継続できる状態｜**差し替え先**: 配布用PDF 第6章 P35〜P36「オフライン継続運用」／`recovery/failure_catalog.md`
  * `[SS-19-2]` **新規追加**｜**画面**: 破損データ隔離警告画面（`CorruptedMatchBanner`）｜**撮影状態**: 赤色警告バナー・編集ロックがかかり、生データ救済エクスポートボタンが出ている状態｜**差し替え先**: 配布用PDF 第6章「異常データ隔離と救済」／`recovery/failure_catalog.md`
  * `[SS-19-3]` **図解（生成/作図）**｜**画面**: 現場復旧YES/NO診断フローチャート｜**撮影状態**: トラブル発生時の最短10秒復旧分岐図（PDF紙面・マニュアル用図解）｜**差し替え先**: 配布用PDF 第6章 P37「トラブル診断チャート」／`recovery/failure_catalog.md`

---

### 【Step 20/27】監視・同期ダッシュボード（Clock Skew・P2P・Isar・第501/502条規約）⚠️ Stage 2 β 非表示（総合取扱説明書から除外）
> **【総合取扱説明書 除外対象】**: Stage 2 β 版の利用方針により UI 上非表示（遷移導線なし）のため、総合取扱説明書（Google スライド）には掲載しません（内部仕様・`recovery/observability_dashboard.md` 向けの記録として保持）。なお、`ObservabilityDashboardScreen` 画面上には Clock Skew 補正値や P2P 接続状態の UI 表示はありません（内部サービスとして稼働）。
* **対象マニュアル**: [`packages/documentation_runtime/manuals/recovery/observability_dashboard.md`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/packages/documentation_runtime/manuals/recovery/observability_dashboard.md)（※配布用総合取扱説明書は除外）
* **コード根拠**:
  * 運用ダッシュボード画面: [`lib/admin/dashboard/observability_dashboard_screen.dart:L11-L132`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/admin/dashboard/observability_dashboard_screen.dart#L11-L132)
  * ダッシュボードメトリクス供給: [`lib/admin/providers/metrics_provider.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/admin/providers/metrics_provider.dart)
  * 第502条Clock Skew補正: [`lib/shared/time/server_clock_offset_service.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/shared/time/server_clock_offset_service.dart)
  * CRDT 3者マージ＆タイマー調停: [`lib/features/tournament/presentation/operate/providers/sync_crdt_merger.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/operate/providers/sync_crdt_merger.dart)
  * 第501条P2Pローカル配信: [`lib/features/p2p/infrastructure/local_p2p_broadcaster.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/p2p/infrastructure/local_p2p_broadcaster.dart)
  * Isarローカル永続化リポジトリ: [`lib/shared/infrastructure/repository/local_match_repository.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/shared/infrastructure/repository/local_match_repository.dart)

* **UI全要素リスト**:
  - [x] **ヘッダーバー & 緊急ガイド連携**:
    - 戻るボタン、タイトル「運用ダッシュボード (Observability)」
    - ❓ **マニュアルヘルプボタン (`ManualHelpButton`)**: 異常値検知時に「緊急復旧ガイド（`failure_catalog.md`）」へ直行
  - [x] **4大リアルタイム健康状態メトリクスカード**:
    1. **総イベント処理数 (`totalEvents`)**:
       - イベントソーシングにより処理された累計イベント数（青色アイコン）
    2. **システムエラー率 (直近) (`errorRate`)**:
       - 1.00%以下: 正常（緑色） / 1.00%超過: 異常警告（赤色）
    3. **同時書き込み競合率 (直近) (`conflictRate`)**:
       - 5.00%以下: 正常（緑色） / 5.00%超過: 競合多発注意（橙色）
    4. **Projection遅延 (直近) (`lastLagMs`)**:
       - 2,000ms（2秒）以下: 正常（緑色） / 2,000ms超過: 通信遅延警告（赤色）
  - [x] **第502条 Clock Skew（端末間時刻ズレ）自動補正**:
    - `ServerClockOffsetService` がNTP/クラウド時刻とのオフセットを常時ミリ秒計測
    - 端末側の時計が狂っていても、試合タイマー計時とイベント順序を正確に調停
  - [x] **CRDT 3者マージ ＆ ステータス不可逆ガード**:
    - ローカルイベント・リモートイベント・保留中キューの3者を自動調停
    - 終了した試合が勝手に未開始へ戻る「巻き戻りバグ」を数学的に完全遮断
  - [x] **第501条 P2P現場ローカル配信メッシュ**:
    - インターネット切断時も、同一体育館内Wi-Fi/LAN経由でサブ端末へ直接スコアを高速配信

* **現行マニュアル（旧PDF P35〜P37）との差分**:
  1. **4大メトリクスカード（総イベント・エラー率・競合率・遅延ms）の完全網羅**:
     * 旧マニュアルの概念説明から、実際の画面カード表示・閾値カラー判定（緑・橙・赤）の解説へ拡充。
  2. **第502条 Clock Skew補正の明記**:
     * 端末の時刻設定がずれていてもタイマーの整合性を100%保つ独自技術を解説。
  3. **CRDT 3者マージと不可逆ステータスガードの役割**:
     * 分散環境下での同時スコア入力競合と巻き戻りを防ぐ仕組みを追記。
  4. **P2Pローカル配信メッシュの仕様**:
     * クラウドを介さずに体育館内でダイレクト配信する第501条仕様を追加。

* **PDF・マニュアル用スクショ撮影・差し替え指示リスト（全3枚）**:
  * `[SS-20-1]` **新規追加**｜**画面**: 運用ダッシュボード画面（正常稼働時 / `ObservabilityDashboardScreen`）｜**撮影状態**: 4大メトリクスカードがすべて緑色正常値を示している状態｜**差し替え先**: 配布用PDF 第6章「運用監視ダッシュボード」／`recovery/observability_dashboard.md`
  * `[SS-20-2]` **新規追加**｜**画面**: 運用ダッシュボード画面（遅延・エラー警告時）｜**撮影状態**: エラー率やProjection遅延が閾値を超えて赤色・橙色に点灯した状態｜**差し替え先**: 配布用PDF 第6章「異常警告の見方」／`recovery/observability_dashboard.md`
  * `[SS-20-3]` **新規追加**｜**画面**: Clock Skew時刻補正＆P2P配信状態表示｜**撮影状態**: 時刻オフセット補正値やP2P接続状態が表示された状態｜**差し替え先**: 配布用PDF 第6章「時刻補正・P2P配信」／`recovery/observability_dashboard.md`

---

## 【Phase 7: 観客・保護者用 Viewer マニュアル】（PDF第7章 P38〜P40）

### 【Step 21/27】観客用トップ画面・リアルタイム速報（コート別進行・PIN不要匿名閲覧・1大会限定QRアクセス）
* **対象マニュアル**: [`packages/documentation_runtime/manuals/viewer/index.md`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/packages/documentation_runtime/manuals/viewer/index.md) ＆ [`viewer/viewer_home.md`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/packages/documentation_runtime/manuals/viewer/viewer_home.md)
* **コード根拠**:
  * 観客席専用ホーム画面: [`lib/features/viewer/presentation/viewer_home_screen.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/viewer/presentation/viewer_home_screen.dart)
  * 進行中・待機中招集バナー: [`viewer_call_banner.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/viewer/presentation/components/viewer_call_banner.dart)
  * クイックアクションボタン: [`viewer_quick_action_buttons.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/viewer/presentation/components/viewer_quick_action_buttons.dart)
  * 大会情報カード: [`viewer_tournament_info_card.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/viewer/presentation/components/viewer_tournament_info_card.dart)
  * タイムライン検索＆ソートバー: [`viewer_match_list_search_bar.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/viewer/presentation/components/viewer_match_list_search_bar.dart)
  * 部門フィルターチップスバー: [`timeline_category_filter_chips_bar.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/operate/components/home/timeline_category_filter_chips_bar.dart)
  * 本部アナウンスマネージャー: [`announce_popup_manager.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/match/presentation/components/announce_popup_manager.dart)
  * 完全匿名認証フロー: [`lib/features/auth/presentation/screens/role_select_screen.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/auth/presentation/screens/role_select_screen.dart)
  * 1大会限定観戦共有・期限検証: [`lib/security/viewer_share_models.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/security/viewer_share_models.dart) / [`lib/shared/routing/route_guards.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/shared/routing/route_guards.dart)

* **UI全要素リスト**:
  - [x] **完全ログイン不要・匿名認証アクセス ＆ 1大会限定公開ガード**:
    - QRコードをスマホのカメラで読み取るだけで1秒アクセス（アカウント登録・PIN入力一切不要）
    - **トークン付き1大会限定リンク（v1.1.0）**: 本部が設定した有効期限（24時間 / 7日間 / 無期限）内のみ閲覧可能。期限切れや本部による「停止」後は閲覧ロック画面を表示
    - 管理画面プレビュー時のみヘッダーに「管理画面に戻る（`exit_to_app`）」脱出ボタン表示
  - [x] **ヘッダーバー & ナビゲーション (`ViewerHomeHeaderActions`)**:
    - タイトル「大会ホーム (観客席)」
    - 🔔 お知らせベル（`NotificationBellButton`）、📲 共有QRアイコン（`Icons.qr_code_2`）、⋯ その他メニュー（`Icons.more_horiz_rounded`: 大会を共有する / 表示設定 / 観客FAQ）
  - [x] **下スワイプ強制同期 (Pull-to-Refresh)**:
    - 画面を下スワイプして試合進行状況を即座に再同期（通信瞬断時の手動復帰に有効）
  - [x] **招集・呼出バナー (`ViewerCallBanner`)**:
    - 🔴 **進行中 (Live)**: 現在対戦中の試合（コート名、選手名、ポジション）
    - 🟡 **待機中 (Next)**: 次、またはその次に控えている試合順
    - タップで当該コートのリアルタイムスコアボード画面へ即時ジャンプ
  - [x] **クイックアクションボタン (`ViewerQuickActionButtons`)**:
    - 2列横並びの角丸四角形ボタン（`AppSemanticTokens.buttonRadius`）
    - **📊 試合結果一覧**: 大会公式記録・全対戦結果一覧
    - **📄 大会プログラム**: 大会トーナメント表（個人メモ書き込み・拡大ズーム対応）
    - ※「順位表」ボタンは v1.1.0 現行 UI には未実装
  - [x] **大会情報カード (`ViewerTournamentInfoCard`)**:
    - 大会名、開催日、会場名、主催者、現在の進行状況
  - [x] **タイムライン検索・ソートバー (`ViewerMatchListSearchBar`)**:
    - 選手名・道場名インクリメンタル検索フィールド（キーワードの蛍光黄色ハイライト連動）
    - 試合順ソート切り替え（昇順 / 降順）、すべて展開 / 折りたたみトグル
  - [x] **部門フィルターチップスバー (`TimelineCategoryFilterChipsBar`)**:
    - 【すべて】【小学生低学年】【中学生男子】等の横スクロールチップ
  - [x] **本部一斉アナウンスポップアップ (`AnnouncePopupListener`)**:
    - 本部からの選手招集、進行遅延、審判合議などの連絡が画面上部に自動ポップアップ

* **現行マニュアル（旧PDF P38〜P40 / v1.0.0）との差分**:
  1. **【v1.1.0新機能】1大会限定観戦リンクの有効期限・停止対応**:
     * 同じQR/URLでも本部設定の有効期限（24時間 / 7日間 / 無期限 / 停止）に従い、大会終了後は自動で閲覧終了するプライバシー保護仕様を明記。
  2. **完全匿名認証（PIN不要・アカウント不要）＆ 招集・呼出バナー**:
     * QRスキャン1秒接続と、進行中Live・待機中Nextバナーのリアルタイム動態を明記。
  3. **2大クイックアクションボタン（試合結果一覧・大会プログラム）・リアルタイム検索・本部アナウンスポップアップ**:
     * 主要画面への導線と検索ハイライト機能を解説。

* **PDF・マニュアル用スクショ撮影・差し替え指示リスト（全3枚）**:
  * `[SS-21-1]` **差し替え**｜**画面**: 観客ホーム画面全体（`ViewerHomeScreen`）｜**撮影状態**: 大会名、進行中/待機中バナー、2列クイックボタン（試合結果一覧・大会プログラム）が表示された状態｜**差し替え先**: 配布用PDF 第7章「観客ホーム画面」／`viewer/viewer_home.md`
  * `[SS-21-2]` **差し替え**｜**画面**: 観客ホーム画面（部門フィルター＆対戦カード一覧）｜**撮影状態**: 部門チップが選択され、各コートの対戦カードが並んでいる状態｜**差し替え先**: 配布用PDF 第7章 P39「対戦状況の確認」／`viewer/viewer_home.md`
  * `[SS-21-3]` **差し替え**｜**画面**: 観客ホーム画面（本部アナウンスポップアップ表示時）｜**撮影状態**: 画面上部に本部からの招集連絡がポップアップしている状態｜**差し替え先**: 配布用PDF 第7章 P39「本部からの一斉連絡」／`viewer/viewer_home.md`

---

### 【Step 22/27】観客用スコアボード・リアルタイム速報・団体戦星取表・代表戦
* **対象マニュアル**: [`packages/documentation_runtime/manuals/viewer/viewer_match.md`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/packages/documentation_runtime/manuals/viewer/viewer_match.md) ＆ [`viewer/viewer_team_scoreboard.md`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/packages/documentation_runtime/manuals/viewer/viewer_team_scoreboard.md)
* **コード根拠**:
  * 観客試合画面: [`lib/features/viewer/presentation/viewer_match_screen.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/viewer/presentation/viewer_match_screen.dart)
  * 大画面観戦スコアボード: [`lib/features/viewer/components/large_viewer_scoreboard.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/viewer/components/large_viewer_scoreboard.dart)
  * 団体戦スコアボード画面（観客専用）: `ViewerTeamScoreboardScreen`（`/viewer-team/:groupName`） / 運営側 [`team_scoreboard_screen.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/operate/team_scoreboard_screen.dart)
  * 団体戦星取表ビルダー: [`team_scoreboard_table_builder.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/operate/components/team_scoreboard/team_scoreboard_table_builder.dart)
  * 代表戦自動判定ハンドラー: [`team_scoreboard_daihyo_handler.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/operate/components/team_scoreboard/team_scoreboard_daihyo_handler.dart)
  * 公式スコア表示仕様書: [`docs/domain/kendo_score_display_spec.md`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/docs/domain/kendo_score_display_spec.md)

* **UI全要素リスト**:
  - [x] **観客用リアルタイムスコアボード (`LargeViewerScoreboard`)**:
    - **縦画面（Portrait） / 横画面（Landscape）自動変形**:
      - 端末を横向きに傾けると、電光掲示板スタイルの超大型スコアボードへ自動レイアウト
    - **赤サイド（左） / 白サイド（右）の選手情報**:
      - 選手氏名（所属プレフィックス自動クレンジング）、タスキ色
    - **中央タイマー**:
      - 残り試合時間（分:秒）ミリ秒リアルタイム同期、延長戦突入時の「延長」バッジ点灯
    - **打突記号ランプ（公式仕様準拠）**:
      - 取得本数スロットに【メ】【コ】【ド】【ツ】【反】【判】【◯（不戦勝）】が点灯（3本勝負1本目の反則は `◯反`、不戦勝は通常丸 `◯`）
    - **反則警告（`△`）**:
      - 左下に最大4個まで累積表示（相手に `反` 付与後も消去せず保持）
    - **勝敗成立バッジ**:
      - 決着時に勝者サイドへ金枠ハイライト ＆ 「勝（WINNER）」マーク点灯、引き分け時は「DRAW」
    - **完全閲覧専用ガード**:
      - 画面タップによる誤打突・誤操作を完全ロック
  - [x] **ヘッダーバー & QRコード共有**:
    - 戻るボタン、タイトル「試合状況 (観戦)」
    - 📲 **観戦QR共有ボタン**: 客席の他の保護者にその場でQRコードを提示可能
  - [x] **団体戦スコアボード (`TeamScoreboardScreen` 閲覧モード)**:
    - **対戦ヘッダー**: 赤チーム名 vs 白チーム名、対戦ステージ名
    - **ポジション別星取表**: 先鋒・次鋒・中堅・副将・大将（行タップで個別試合スコアボードへ）
    - **総合合計行 (`buildTotalRow`)**: 勝者数・総取得本数の自動計算（※代表戦スコアは団体合計に非加算）
    - **代表戦自動出現バッジ (`TeamScoreboardDaihyoHandler`)**: 勝数・本数が完全同点時に最下部へ「代表戦（1本勝負）」カードが出現

* **現行マニュアル（旧PDF P38〜P40 / v1.0.0）との差分**:
  1. **【v1.1.0正本化】先取 `◯反`・不戦勝 `◯`・左下 `△` 累積表示**:
     * 公式スコア表示仕様書に基づき、観客画面・星取表の記号表記を統一。
  2. **縦横自動レイアウト変形（電光掲示板スタイル） & 観戦QR共有ボタン**:
     * 横向き大画面化と客席からのQRシェア導線を明記。
  3. **団体戦同点時の代表戦自動出現 & 完全閲覧専用（編集ブロック）の安心設計**

* **PDF・マニュアル用スクショ撮影・差し替え指示リスト（全3枚）**:
  * `[SS-22-1]` **差し替え**｜**画面**: 観客用スコアボード画面（`LargeViewerScoreboard` 縦画面）｜**撮影状態**: 赤選手に「面」ランプ（または `◯反`）と左下 `△` が点灯し、タイマーが動いている状態｜**差し替え先**: 配布用PDF 第7章 P38〜P39「リアルタイムスコア速報」／`viewer/viewer_match.md`
  * `[SS-22-2]` **差し替え**｜**画面**: 観客用スコアボード画面（横画面レイアウト）｜**撮影状態**: スマホを横向きにして電光掲示板スタイルで大きくスコアが表示された状態｜**差し替え先**: 配布用PDF 第7章 P39「横画面スコアボード」／`viewer/viewer_match.md`
  * `[SS-22-3]` **差し替え**｜**画面**: 観客用団体戦スコアボード（`TeamScoreboardScreen` 閲覧モード）｜**撮影状態**: 先鋒〜大将の星取表、合計行、代表戦カードが表示された状態｜**差し替え先**: 配布用PDF 第7章 P40「団体戦星取表・代表戦」／`viewer/viewer_team_scoreboard.md`

---

### 【Step 23/27】観客用チーム進捗・大会プログラム・個人手書きメモ
* **対象マニュアル**: [`packages/documentation_runtime/manuals/viewer/viewer_team_match_status.md`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/packages/documentation_runtime/manuals/viewer/viewer_team_match_status.md) ＆ [`viewer/viewer_program.md`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/packages/documentation_runtime/manuals/viewer/viewer_program.md)
* **コード根拠**:
  * チーム試合状況画面: [`lib/features/tournament/presentation/operate/screens/team_match_status_screen.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/operate/screens/team_match_status_screen.dart)
  * チーム進捗カード: [`team_status_card.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/operate/components/court_status/team_status_card.dart)
  * プログラムビューワー画面: [`lib/features/tournament/presentation/operate/screens/program_viewer_screen.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/operate/screens/program_viewer_screen.dart)
  * 描画ツールバー（観客権限モード）: [`program_viewer_drawing_toolbar.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/components/program_viewer/program_viewer_drawing_toolbar.dart)
  * PDFテキスト全文検索: [`program_viewer_search_app_bar_title.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/components/program_viewer/program_viewer_search_app_bar_title.dart)

* **UI全要素リスト**:
  - [x] **観客用チーム試合状況画面 (`TeamMatchStatusScreen` / `/court-status`)**:
    - サマリー進行バナー（🔴 進行中 / 🟡 待機中）、状態フィルターチップ、部門・コート切り替えタブ＆横スワイプ
    - チーム進捗カード（現在コート・対戦相手・進行中ポジション表示、タップで詳細スコア直行、BAND編集等は自動非表示）
  - [x] **観客用プログラムビューワー (`ProgramViewerScreen`)**:
    - 直交スクロール（縦：ページめくり / 横：ファイル切替）、ピンチズーム排他制御
    - **個人ペン（青・黒）**: 端末ローカル（Isar）保存で他者非公開
    - **本部共有ペン（ピンク・黄）の閲覧**: 本部の勝ち上がり線をリアルタイム表示（観客側消去は保護ガード）
    - **🔍 PDFテキスト全文検索**: 選手名・学校名のインクリメンタル検索

* **現行マニュアル（旧PDF P38〜P40）との差分**:
  1. **チーム進捗カードタップ時の詳細スコア直行遷移**
  2. **個人ペン（青・黒）の端末ローカル保存（Isar）と完全秘匿性 & 本部共有ペン保護ガード**
  3. **ピンチズーム中の誤スワイプロック制御 & PDF内テキスト全文検索機能**

* **PDF・マニュアル用スクショ撮影・差し替え指示リスト（全3枚）**:
  * `[SS-23-1]` **差し替え**｜**画面**: 観客用チーム試合状況画面（`TeamMatchStatusScreen`）｜**撮影状態**: サマリーバッジ、状態フィルター、チーム進捗カードが表示された状態｜**差し替え先**: 配布用PDF 第7章「チーム別進行状況」／`viewer/viewer_team_match_status.md`
  * `[SS-23-2]` **差し替え**｜**画面**: 観客用プログラム手書きメモ画面（`ProgramViewerScreen`）｜**撮影状態**: トーナメント表に青ペンでメモが引かれ、手書きツールバーが開いた状態｜**差し替え先**: 配布用PDF 第7章「プログラム閲覧・手書きメモ」／`viewer/viewer_program.md`
  * `[SS-23-3]` **新規追加**｜**画面**: 観客用プログラム（PDF全文検索中）｜**撮影状態**: 選手名で検索され、該当箇所が黄色ハイライトされた状態｜**差し替え先**: 配布用PDF 第7章「トーナメント表内の名前検索」／`viewer/viewer_program.md`

---

### 【Step 24/27】観客用公式戦記録・部内戦速報・勝ち抜き戦
* **対象マニュアル**:
  * [`packages/documentation_runtime/manuals/viewer/viewer_official_record.md`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/packages/documentation_runtime/manuals/viewer/viewer_official_record.md)
  * [`packages/documentation_runtime/manuals/viewer/viewer_bunaiksen.md`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/packages/documentation_runtime/manuals/viewer/viewer_bunaiksen.md)
  * [`packages/documentation_runtime/manuals/viewer/viewer_kachinuki_scoreboard.md`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/packages/documentation_runtime/manuals/viewer/viewer_kachinuki_scoreboard.md)
* **コード根拠**:
  * 観客用公式記録画面: `ViewerOfficialRecordScreen`（`/viewer-record/:tournamentId`） / 運営側 [`official_record_screen.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/operate/official_record_screen.dart)
  * 観客用部内戦ホーム画面: `ViewerBunaiksenHomeScreen`（`/bunaiksen-viewer-home/:tournamentId`） / 運営側 [`bunaiksen_home_screen.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/operate/screens/bunaiksen_home_screen.dart)
  * 勝ち抜き戦スコアボード画面: `ViewerKachinukiScoreboardScreen`（`/viewer-kachinuki/:groupName`）
  * 連勝リーダーボードカード: [`bunaiksen_leaderboard_card.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/operate/components/bunaiksen/bunaiksen_leaderboard_card.dart)
  * 勝ち抜き戦スコア計算・連勝判定: [`lib/features/match/domain/services/kendo_rule_engine.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/match/domain/services/kendo_rule_engine.dart)

* **UI全要素リスト**:
  - [x] **観客用公式戦記録 (`ViewerOfficialRecordScreen`)**:
    - ヘッダータイトル「大会 公式記録」、🔍 インクリメンタル検索バー
    - エクスポートバー（PDF出力 / LINEグリーン画像出力 / 全カテゴリ一括トグル）
    - 全対戦カード一覧（※遠征集計サマリーカードはParity保護規約により自動非表示）
  - [x] **観客用部内戦速報 (`BunaiksenHomeScreen` 観客モード)**:
    - カレンダー日付切替、🏆 無限勝ち抜きリーダーボードカード、対戦タイムラインカード
  - [x] **勝ち抜き戦スコアボード (`viewer_kachinuki_scoreboard`)**:
    - 現在対戦中選手＆技ランプ、連勝数（`〇人抜き！`バッジ）、控え選手スロットインジケータ、大将同士時間無制限一本勝負表示

* **現行マニュアル（旧PDF P38〜P40）との差分**:
  1. **観客用公式戦記録のLINE画像出力（#06C755）とPDF印刷**
  2. **部内戦リーダーボードとカレンダー過去日閲覧**
  3. **勝ち抜き戦の連勝バッジ（〇人抜き）と控えスロット点滅 & Parity規約による内部サマリー非表示**

* **PDF・マニュアル用スクショ撮影・差し替え指示リスト（全3枚）**:
  * `[SS-24-1]` **差し替え**｜**画面**: 観客用公式戦記録画面（`OfficialRecordScreen` 閲覧モード）｜**撮影状態**: 部門タブ・全対戦カード一覧・PDF/LINE画像出力ボタンが表示された状態｜**差し替え先**: 配布用PDF 第7章「公式記録・LINE結果共有」／`viewer/viewer_official_record.md`
  * `[SS-24-2]` **差し替え**｜**画面**: 観客用部内戦リーダーボード画面（`BunaiksenHomeScreen` 閲覧モード）｜**撮影状態**: カレンダー日付、本日の王座・連勝ランキングカードが表示された状態｜**差し替え先**: 配布用PDF 第7章「部内戦リアルタイム速報」／`viewer/viewer_bunaiksen.md`
  * `[SS-24-3]` **新規追加**｜**画面**: 勝ち抜き戦スコアボード画面｜**撮影状態**: 控え選手スロットの消灯、連勝バッジ（3人抜き等）、残り人数が表示された状態｜**差し替え先**: 配布用PDF 第7章「勝ち抜き戦速報」／`viewer/viewer_kachinuki_scoreboard.md`

---

## 【Phase 8: クイックガイド・FAQ・最終総点検】（PDF第8章・付録 P40等）

### 【Step 25/27】機動運用・机上クイックガイド全3本
* **対象マニュアル**:
  * 記録員向け机上ガイド: [`packages/documentation_runtime/manuals/quickstart/recorder_1pager.md`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/packages/documentation_runtime/manuals/quickstart/recorder_1pager.md) (新設)
  * 運営・審判長向け机上ガイド: [`packages/documentation_runtime/manuals/quickstart/operator_1pager.md`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/packages/documentation_runtime/manuals/quickstart/operator_1pager.md)
  * 観客・保護者用1枚ガイド: [`packages/documentation_runtime/manuals/quickstart/viewer_1pager.md`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/packages/documentation_runtime/manuals/quickstart/viewer_1pager.md)
  * ガイド目次: [`packages/documentation_runtime/manuals/quickstart/index.md`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/packages/documentation_runtime/manuals/quickstart/index.md)
* **コード根拠**:
  * マスターPIN・道場別PIN検証: [`lib/security/pin_guard.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/security/pin_guard.dart) (初期PIN Admin: 9999, Operator: 2468, Recorder: 1357, Viewer: PIN不要 / 道場別変更可)
  * 試合画面・Undoバー・確定ボタン: [`lib/features/tournament/presentation/operate/match_screen.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/operate/match_screen.dart)
  * フローティングドック: [`lib/features/tournament/presentation/components/program_management/floating_program_dock_button.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/components/program_management/floating_program_dock_button.dart)

* **UI全要素リスト**:
  - [x] **📋 記録係 机上1枚ガイド (`recorder_1pager.md`)**:
    - ログインPIN: 初期値 `1357`（道場別カスタムPIN設定時は管理者から共有されたPIN＋道場入室PIN）
    - 🥋 計時スタート/ストップ（計時中赤背景点灯、タップで開始/停止）
    - 🔴⚪ スコア入力（面・小手・胴・突、反則2回で自動1本付与、先取 `◯反`・左下 `△` 累積）
    - ↩️ 5秒スマートUndoバー ＆ 画面下部Undoボタンによる即時取り消し
    - 🏁 試合終了確定ボタンの「1.5秒長押し」（誤終了防止）
    - 💡 試合中ドックボタン活用（背面スコア操作継続・トーナメント確認）
    - 🚨 オフライン時の鉄則（画面を閉じずにそのまま入力継続）
  - [x] **🏛️ 大会本部・審判長 机上ガイド (`operator_1pager.md`)**:
    - ログインPIN: 初期値 `2468`（監督・引率責任者） / `9999`（代表・管理者）※道場別カスタムPIN・入室PIN変更可
    - 🏆 大会作成・コート割り当て・部門ルール設定
    - ⚙️ 一括ルール変更（全コート残り時間・延長設定の一括適用）
    - 📢 本部一斉アナウンス配信（選手招集・審判合議の全端末ポップアップ）
    - 🖌️ 本部共有ペン（ピンク・イエロー）による勝ち上がり赤線の一斉配信
    - 📲 1大会限定観戦QR共有（有効期限：24時間 / 7日間 / 無期限 / 停止）
    - 📊 成績出力（A4公式PDF印刷 ＆ LINEグリーン画像出力）
  - [x] **📱 観客・保護者用 1枚ガイド (`viewer_1pager.md`)**:
    - QRコードスキャン1秒入場（完全匿名・PIN不要・登録不要、大会公開期限内）
    - 🔴 進行中（Live）/ 🟡 待機中（Next）招集バナーとスコアボード移動
    - 横画面電光掲示板スタイル大迫力スコアボード
    - 👤 自分専用個人ペン（青・黒）によるトーナメント手書きメモ
    - 🖼️ 試合結果のLINEワンタップ画像共有

* **現行マニュアル（旧PDF P40 机上ガイド等 / v1.0.0）との差分**:
  1. **【v1.1.0反映】道場別カスタムPIN・入室PIN・1大会限定QR期限の追記**:
     * 初期PIN（`9999`/`2468`/`1357`）の記載に加え、道場管理者がPINを変更している場合の案内、および観戦QRの公開期限管理を明記。
  2. **記録係と大会本部ガイドの完全分離 & 最新UX手順**:
     * 計時中赤背景点灯・5秒Undoバー・1.5秒長押し・公式スコア記号（`◯反` / `◯` / `△`）を反映。

* **PDF・マニュアル用スクショ撮影・差し替え指示リスト（全3枚）**:
  * `[SS-25-1]` **差し替え**｜**画面**: 試合記録・ドック操作図解用画面｜**撮影状態**: タイマー赤点灯・5秒Undoバー・1.5秒長押し確定ボタンが視認できる状態｜**差し替え先**: 配布用PDF 第8章 P40「記録係 机上クイックガイド」／`quickstart/recorder_1pager.md`
  * `[SS-25-2]` **差し替え**｜**画面**: 大会本部操作図解用画面｜**撮影状態**: 一括ルール変更・共有ペン・観戦QR有効期限・アナウンス導線が分かる状態｜**差し替え先**: 配布用PDF 第8章「大会本部・審判長 机上ガイド」／`quickstart/operator_1pager.md`
  * `[SS-25-3]` **差し替え**｜**画面**: 観客向け操作図解用画面｜**撮影状態**: QR入場・観客スコアボード・LINE画像共有が分かる状態｜**差し替え先**: 配布用PDF 第8章「観客用 1枚ガイド」／`quickstart/viewer_1pager.md`

---

### 【Step 26/27】トラブルシューティングFAQ集（運営向け、観客向け）
* **対象マニュアル**:
  * 運営・記録向けFAQ: [`packages/documentation_runtime/manuals/faq/operator_faq.md`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/packages/documentation_runtime/manuals/faq/operator_faq.md)
  * 観客・保護者向けFAQ: [`packages/documentation_runtime/manuals/faq/viewer_faq.md`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/packages/documentation_runtime/manuals/faq/viewer_faq.md)
* **コード根拠**:
  * マスターPIN・道場別PIN検証: [`lib/security/pin_guard.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/security/pin_guard.dart) / [`lib/features/auth/presentation/widgets/dojo_pin_recovery_sheet.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/auth/presentation/widgets/dojo_pin_recovery_sheet.dart)
  * 1大会限定観戦URL有効期限: [`lib/shared/widgets/viewer_share_expiry_selector.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/shared/widgets/viewer_share_expiry_selector.dart)
  * 第502条Clock Skew補正: [`server_clock_offset_service.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/shared/time/server_clock_offset_service.dart)
  * 第503条自己修復: [`twin_match_persistence_helper.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/shared/infrastructure/persistence/twin_match_persistence_helper.dart)
  * 第504条障害隔離: [`match_corrupted_state.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/shared/domain/entities/match_corrupted_state.dart)
  * 5秒Undoバー ＆ 1.5秒長押し: `match_screen.dart`
  * 全画面Pull-to-Refresh耐障害性: 各画面 `RefreshIndicator`

* **UI全要素リスト**:
  - [x] **運営・記録係向けFAQ (`operator_faq.md`)**:
    - **PINコード一覧・PIN忘れ対応**: 初期PIN（代表・管理者 `9999`、監督・引率 `2468`、スコア・記録 `1357`）、道場別カスタムPINの確認方法（設定＞道場セキュリティ・PIN管理）、**PINを忘れた場合の代表者Google本人確認による初期化手順 (`DojoPinRecoverySheet`)** *(v1.1.0)*
    - **計時・タイマー精度**: コート主時計との運用ルール、第502条Clock Skew自動補正
    - **スコア誤入力・Undo**: 5秒カウントダウンUndoバー、下部Undoボタン、試合確定後のホームからの安全再編集
    - **通信切断（オフライン）・強制再同期（下スワイプ）・クラッシュ復元（第503条）・赤色障害警告（第504条）**
    - **部内戦ドック・ジグル / 公式記録出力（A4 PDF & LINE画像）**
  - [x] **観客・保護者向けFAQ (`viewer_faq.md`)**:
    - **接続・アクセス**: QRコードスキャン1秒入場（登録不要・PIN不要）
    - **観戦リンクが開けない・閲覧終了と出る場合 *(v1.1.0)***: 大会本部が設定した公開期限（24時間 / 7日間）の終了、または公開停止による仕様（最新のQRを再共有してもらう案内）
    - **数字が止まった？**: 画面を下スワイプして強制再同期
    - **大画面表示（横画面変形）・手書きメモ（個人ペンIsar保存）・本部共有ペン・代表戦表示・LINE共有**

* **現行マニュアル（v1.0.0）との差分**:
  1. **【v1.1.0新設Q&A】入室PIN・ロールPIN忘れ時の「代表者Google本人確認・初期化手順」**:
     * 道場別カスタムPINを導入した現場で、PIN失念・代表者交代時に安全に再設定できるQ&Aを追加。
  2. **【v1.1.0新設Q&A】観戦QR・URLの有効期限切れ・公開停止時の案内**:
     * 期限切れ画面が表示された場合の理由と対処法を観客FAQに追加。
  3. **最新ガバナンス（第502条〜第504条）・最新UI仕様（5秒Undo・1.5秒長押し・下スワイプ再同期）・初期PIN統一**

* **PDF・マニュアル用スクショ撮影・差し替え指示リスト（全3枚）**:
  * `[SS-26-1]` **差し替え**｜**画面**: 運営FAQ画面（またはPIN復旧シート連動図）｜**撮影状態**: PIN一覧・代表者Google初期化・Undo・確定手順セクションが見えている状態｜**差し替え先**: 配布用PDF 第8章「運営・記録FAQ」／`faq/operator_faq.md`
  * `[SS-26-2]` **差し替え**｜**画面**: トラブルシューティングFAQ画面｜**撮影状態**: オフライン復旧・下スワイプ再同期・サーマル冷却セクションが見えている状態｜**差し替え先**: 配布用PDF 第8章「障害・通信トラブルFAQ」／`faq/operator_faq.md`
  * `[SS-26-3]` **差し替え**｜**画面**: 観客FAQ画面｜**撮影状態**: QR接続・公開期限・個人手書きペン・LINE出力セクションが見えている状態｜**差し替え先**: 配布用PDF 第8章「観客・保護者FAQ」／`faq/viewer_faq.md`

---

### 【Step 27/27】タイムライン仕様・免責事項・最終総点検 ＆ 全改訂完了報告
* **対象マニュアル**:
  * タイムライン仕様と免責事項: [`packages/documentation_runtime/manuals/operator/timeline_specs.md`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/packages/documentation_runtime/manuals/operator/timeline_specs.md) (新設)
  * 総合マニュアル目次: [`packages/documentation_runtime/manuals/manual_index.md`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/packages/documentation_runtime/manuals/manual_index.md)
  * 運営マニュアル目次: [`packages/documentation_runtime/manuals/operator/index.md`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/packages/documentation_runtime/manuals/operator/index.md)
  * 観客マニュアル目次: [`packages/documentation_runtime/manuals/viewer/index.md`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/packages/documentation_runtime/manuals/viewer/index.md)
* **コード根拠**:
  * タイムライン集約プロバイダー: [`timeline_ui_state_provider.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/operate/providers/timeline_ui_state_provider.dart)
  * CRDT状態遷移: [`sync_crdt_merger.dart`](file:///Users/saradafumiaki/Documents/Apps/kendo_os/lib/features/tournament/presentation/operate/providers/sync_crdt_merger.dart)
  * 全日本剣道連盟 試合・審判規則第203条・第502条調停境界

* **UI全要素リスト**:
  - [x] **タイムライン表示順序決定ロジック（`timeline_ui_state_provider.dart` / 観客側 `ViewerCategorySectionList`）**:
    - 1. 🔴 進行中（In-Progress / Live）最上位ハイライト配置
    - 2. 🟡 待機中（Waiting / Next）試合順（`order` 昇順）整列
    - 3. ⚪ 終了済（Finished / Approved）対戦サマリー保持
  - [x] **試合状態の不可逆遷移ロジック (`resolveMonotonicStatus`)**:
    - `scheduled` ➔ `in_progress` ➔ `finished` ➔ `approved`
    - 遅延通信パケットによる状態巻き戻り（未開始化バグ）の数学的遮断
  - [x] **3大公式免責事項と競技原則**:
    - 1. **物理ストップウォッチ（主時計）絶対の原則**: 公式判定は机上主時計を最終基準とする
    - 2. **審判員宣告絶対の原則**: 剣連規則に基づき、主審・審判長の宣告が絶対の正
    - 3. **通信障害時の競技継続原則**: Isarローカル保存による記録保護と、電波遮断を理由とした試合中断の禁止
  - [x] **全マニュアル・総合目次（`manual_index.md`）の整合性確認**:
    - `packages/documentation_runtime/manuals/` 配下 全54マニュアルファイル（v1.1.0 照合済み）

* **現行マニュアルとの差分**:
  1. **タイムライン整列アルゴリズムの明文化**:
     * 進行中・待機中・終了カードの決定論的配置ルールを明記。
  2. **公式免責事項（物理時計・審判宣告の優先）の明確化**:
     * デジタル支援システムとしての責務境界と、競技規則の尊厳を保証する規定を整理。
  3. **全27ステップの精査完了と総合取扱説明書（方針B）再構成**:
     * Flutter v1.1.0 最新コードと照合を完了し、Stage 2 β 非表示機能（Step 18・20）を除外した総合取扱説明書（第1〜8章）の改訂台帳が完成。

* **PDF・マニュアル用スクショ撮影・差し替え指示リスト（全3枚）**:
  * `[SS-27-1]` **図解（生成/作図）**｜**画面**: タイムライン表示アルゴリズム図解｜**撮影状態**: 進行中/待機中/終了の配置と不可逆遷移フロー（Mermaidフロー紙面版）｜**差し替え先**: 配布用PDF 第8章「タイムライン仕様」／`operator/timeline_specs.md`
  * `[SS-27-2]` **差し替え**｜**画面**: 総合マニュアル目次（アプリ内 `EmbeddedManualScreen`）｜**撮影状態**: 最新インデックス体系が表示された状態｜**差し替え先**: 配布用PDF 目次・構成案内／`manual_index.md`
  * `[SS-27-3]` **図解（生成/作図）**｜**画面**: 公式免責事項・競技規則尊重規定ページ｜**撮影状態**: 3大公式免責事項と `KendoSync` 正規窓口・著作権表記の紙面レイアウトデザイン｜**差し替え先**: 配布用PDF 第8章「免責事項」／`operator/timeline_specs.md`

---

## 🏆 全27ステップ 改訂台帳（v1.1.0 準拠）総括レポート
* **対象アプリバージョン**: **v1.1.0（`1.1.0+2`）**
* **総ステップ数**: 27 / 27 ステップ（v1.1.0 実コード照合完了／総合取扱説明書対象: 25 ステップ ※Step 18 監査ログ・Step 20 監視ダッシュボードは Stage 2 β 非表示のため除外）
* **配布用PDF・総合取扱説明書向けスクリーンショット指示合計**: **全81枚**（※全27ステップ計 87 枚のうち、Stage 2 β 除外の Step 18・20 分 6 枚を取説対象外とした枚数）
  * **差し替え（既存画像の更新）**: **60枚**
  * **新規追加（v1.1.0新機能・新設ページ用）**: **18枚**（全ステップ合計 24 枚 − Stage 2 β 除外 6 枚）
  * **図解（フローチャート・紙面デザイン作図）**: **3枚**
* **備考**: 本台帳の更新に基づき、`Kendo_Sync 総合取扱説明書`（Google スライド：方針B・第1〜8章再構成）および `packages/documentation_runtime/manuals/` 本体の原稿改訂・スクリーンショット差し替え作業を順次実施する。







