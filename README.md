# KendoOS (剣道OS)

> **剣道 イベントソーシング 大会運営・電子スコアボード統合プラットフォーム**  
> 体育館の現場運用に特化した、完全オフライン対応・高信頼性の競技運営OS

---

## 🥋 主な機能 (Key Features)

* **多彩な試合形式の完全サポート**
  * 個人戦トーナメント（3位決定戦対応）
  * 団体戦（勝数・取得本数・代表戦判定対応）
  * 総当たりリーグ戦（勝点・勝者数・総本数順位決定）
  * 部内戦（無限ループ方式・連続対戦制御）
  * 道場モード（稽古・練習試合の即時スコア記録）
* **電子スコアボード & 公式タイマー**
  * 全日本剣道連盟ルールに完全準拠した一本（メ・ド・コ・ツ）、反則、延長、判定、合議のリアルタイム管理
  * 大型モニター・プロジェクター向け全画面表示モード
* **完全オフライン動作 ＆ ハイブリッド同期 (Offline-First)**
  * 電波の届かない体育館でも [Isar](https://isar.dev/) ローカルDBにより完全動作
  * ネットワーク復帰時に Cloud Firestore へ自動・安全に同期（CRDT調停・競合回避）
* **公式記録・対戦表 PDF出力**
  * 大会公式記録表、トーナメント勝敗表、リーグ戦星取表をワンクリックでA4組版PDF生成・印刷
* **マルチデバイス連携・リアルタイム観戦**
  * 操作卓（係員・審判）、大型表示盤（モニター）、観客・選手用ビューア（Web/PWA・QRコード即時共有）

---

## 🏛 アーキテクチャ ＆ 設計思想 (Architecture & Governance)

本プロジェクトは「未来の設計崩壊を防ぐ統治構造」と「歴史的再現性を保証するイベントソーシング」の下で開発・運用されています。

* **[Architecture Guide](./docs/architecture/index.md)** - システム構造、Provider単方向依存階層、データ同期ポリシーの地図
* **[ADR Index](./docs/adr/index.md)** - 過去の重要なアーキテクチャ決定記録（ADR-001, ADR-010, ADR-011等）
* **[Operational Runbook](./docs/operations/index.md)** - 現場での運用ルール、トラブルシューティング、データ救済手順
* **[Testing Standard](./docs/testing/rule_testing_standard.md)** - リプレイ完全性、C1カバレッジ、カオステスト等の品質保証要件
* **[KendoOS ガバナンス規約 (GEMINI.md)](./GEMINI.md)** - アーキテクチャ不変条件（単一ファイル500行上限、23大デザイントークン、開発行動規範）
* **[公式マニュアル・取扱説明書](./mkdocs.yml)** - MkDocs による操作マニュアルおよび現場用クイックガイド

---

## 🚀 開発環境のセットアップ (Getting Started)

### 前提条件
* Flutter SDK (3.x 以上)
* Dart SDK
* Python 3.9 以上（ガバナンス監査スクリプト実行用）
* Xcode / CocoaPods（macOS デスクトップ実行時）

### インストール手順

```bash
# 1. リポジトリのクローン
git clone https://github.com/Smooth213/kendo_os.git
cd kendo_os

# 2. 依存パッケージの取得
flutter pub get

# 3. コード生成（Isar, Riverpod 等）
dart run build_runner build --delete-conflicting-outputs
```

### アプリの起動

```bash
# macOS デスクトップ版で起動
flutter run -d macos

# Web ブラウザ版で起動
flutter run -d chrome
```

---

## 🛡 テスト ＆ ガバナンス自動監査 (Testing & Governance)

KendoOS では、コードの整合性と現場の安定性を担保するため、コミット前に以下の厳格な検証を行います。

### 1. ガバナンス全自動監査（全40条項）
リポジトリ内の全ガバナンス条項（アーキテクチャ境界、ファイル行数制限、低負荷・省電力規約等）を一括検証します。

```bash
python3 scripts/run_all_governance.py
```

### 2. 単体・画面回帰テスト
変更対象に関連する局所テストを実行します。

```bash
flutter test test/path/to/target_test.dart
```

### 3. 静的解析 ＆ コードフォーマット

```bash
flutter analyze
dart format --output=none --set-exit-if-changed <変更したファイルパス>
```
