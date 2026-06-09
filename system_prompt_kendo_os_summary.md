# 🥋 kendo_os プロジェクト完全要約・アーキテクチャ仕様書

## 1. プロジェクト概要 (Project Overview)
**kendo_os** は、剣道の大会・錬成会・部内戦・道場稽古における試合進行、スコア記録、タイマー管理、そして観客や保護者へのリアルタイムな試合状況共有（Viewer機能）を統合したクロスプラットフォーム・アプリケーションです。
特に「体育館の劣悪な電波環境」を想定した**強固なオフラインファースト設計**と、「高齢の記録員でも間違えない」**直感的なUI/UX**、保護者がQRコードから即座にアクセスできる**PWA（Web）ビューア機能**を特徴としています。

## 2. 技術スタック (Tech Stack)
- **フレームワーク**: Flutter (^3.11.4 / Dart 3)
- **状態管理**: Riverpod (`flutter_riverpod: ^2.5.1`)
- **ルーティング**: GoRouter (`go_router: ^17.1.0`)
- **ローカルデータベース**: Isar (`isar_community: ^3.3.2`) ※モバイル・デスクトップ専用
- **バックエンド/クラウド**: Firebase (Firestore, Auth, Storage, Crashlytics)
- **UI/コンポーネント**: Material 3 & Cupertinoハイブリッド、`flutter_slidable`、各種カスタムGlass UI
- **PDF出力**: `pdf`, `printing`, `syncfusion_flutter_pdfviewer`
- **その他**: `audioplayers`, `flutter_tts` (音声フィードバック), `share_plus`, `qr_flutter`

## 3. コアアーキテクチャと設計思想 (Architecture)
本プロジェクトは、**ドメイン駆動設計 (DDD)** と **CQRS / Event Sourcing** のハイブリッドアーキテクチャを採用しています。

1. **Event Sourcing (歴史の不変性)**
   試合のスコア（メ、コ、反則など）は上書き可能な状態値ではなく、`ScoreEvent`（事実の履歴）として配列に追加されます。`KendoRuleEngine`（Reducer）が履歴を解析し、現在の正しいスコアと勝敗（MatchContext）を再構築します。これにより「1つ前に戻る(Undo)」や「タイムトラベル」を完璧に実現しています。
2. **Offline-First & CRDT (同期エンジン)**
   体育館は電波が遮断されやすいため、ネイティブアプリは全て**ローカルDB (Isar)** に対してミリ秒単位で読み書き（ライトスルー）を行います。通信状態が復帰した瞬間に、バックグラウンドの `SyncEngine` がFirestoreへバッチ送信を行います。複数端末の競合は `logicalClock` と `timestamp` を用いた **CRDT（Conflict-free Replicated Data Type）マージ** によって自動解決されます。
3. **Zero Trust Router (セキュリティ)**
   `RoleInjector` と `AuthGuard` により、URL直叩きやセッション偽装を物理的にブロックします。`viewer`（一般観客）権限のユーザーには、書き込みUIが一切レンダリングされません。

## 4. コアドメインモデル (Core Domain Models)
- `TournamentModel`: 大会の基本情報（ID, 名称, 日付, 会場, セキュリティレベル）。
- `MatchModel`: 1つの試合のエンティティ。
  - 状態: `status` (waiting, in_progress, finished, approved)。
  - タイマー: `timerStartedAt`, `accumulatedPauseDurationMs` を用いた絶対時間計算。
  - ペイロード: `events` (確定済みのScoreEvent履歴), `pendingEvents` (未送信の差分履歴)。
- `ScoreEvent`: 打突・反則イベント。`StrikeType`, `PointType`, `Side` (red/white) を保持。
- `MatchRule`: 試合時間、勝敗条件（3本/1本勝負）、延長（回数/無制限）、判定の有無、リーグ戦設定などを包括する設定モデル。
- `TeamModel` / `PlayerModel`: チーム編成や選手マスタ。

## 5. 主要機能モジュール (Key Features)

### 📊 スコア記録・試合進行 (`MatchScreen` / `MatchApplicationService`)
- **対応フォーマット**: 個人戦、団体戦 (3〜任意の人数制)、勝ち抜き戦、リーグ戦（総当たり）。
- **タイマー管理**: 独立したタイマーTickerが絶対時間ベースで稼働。
- **入力インターフェース**: 長押し/ダブルタップによる誤操作防止ボタン (`HoldConfirmButton`)。
- **判定処理**: 同点時の「代表戦」「判定」「延長戦」「引き分け」の自動/手動ルーティング。
- **他コートの簡易入力**: メインコート以外で行われた試合結果を数字（勝者数・取得本数）だけで一括流し込み可能。

### 🌐 観客用Viewer (`ViewerHomeScreen` / `ViewerMatchListTileCard`)
- Web（ブラウザ/PWA）環境に特化。QRやURLリンクからログイン不要でアクセス可能。
- `kIsWeb` 時はローカルのIsarを使用せず、Firestoreの `matchListByTournamentProvider` に直結し、ポーリングなしで最新のスコアをStream描画。
- データのネスト肥大化を防ぐためのスナップショットパージなど、Firestoreの制約を回避するパッチが多数組み込まれている。

### ⚔️ 部内戦・錬成会特化エンジン (`bunaiksen_setup_screen.dart` / `bunaiksen_infinite_engine_provider`)
- **錬成会モード**: 「時間制」を選択すると、制限時間が来るまでエンドレスで次の選手をセットアップ可能。
- **無限勝ち抜きモード**: 待機列キューを管理し、勝者が居座り続け、敗者が列の最後尾に回る自動マッチメイクエンジンを搭載。連勝記録（Streak）のリーダーボード機能あり。

### 🖨️ 公式記録・PDF出力 (`PdfService` / `OfficialRecordScreen`)
- `MatchProjection` という軽量化されたビューモデルを用いて、複雑なトーナメントやリーグの星取表を構築。
- リーグ戦の順位は、勝数・勝者数・取得本数から `KendoRuleEngine` が全剣連基準で自動計算。
- PDF出力および、SNS共有用の画像化機能を完備。

## 6. プラットフォーム固有の制約と特記事項 (Platform Specifics)

1. **Web環境 (`kIsWeb`) の制約**
   - Webでは Isar (ローカルDB) が使用できない（クラッシュする）ため、`main.dart` のブートストラップで `isar = null` とし、Provider層でFirestoreとメモリキャッシュにフォールバックさせる分岐（Strangler Figパターン）が多用されています。
2. **Firestoreのネスト制限**
   - オプティミスティック更新やUndoのために `snapshots` 配列に状態を丸ごとバックアップしていましたが、Firestoreの「入れ子の深さ制限 (invalid nested entity)」に抵触したため、過去のSnapshotはクリアして保存するよう修正済みです。
3. **タイマーのバックグラウンド停止問題**
   - 省電力モード等で端末がスリープするとタイマーが狂う（またはNaNになる）問題を防ぐため、ストップウォッチ式ではなく、`now - timerStartedAt` の「絶対時間差分」で計算する強固なロジックが組まれています。
4. **エントリーポイントの分離**
   - `main_operator.dart` (運営用フル機能)
   - `main_viewer.dart` (保護者向け機能制限版)
   - `main_tablet.dart` (本部・横画面特化版)
   - `main_pwa.dart` (Webインストール版)

---
以上が `kendo_os` の完全なコンテキストとなります。アーキテクチャの変更やバグ修正を行う際は、**「Event Sourcingの不変性」**と**「kIsWebの環境分岐（Isarの有無）」**に特に注意して設計してください。