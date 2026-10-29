# 🥋 KendoOS Golden & Pixel レイアウト整合性テスト資産仕様書

## 1. 概要
本ディレクトリ（`test/golden/`）は、KendoOS の最重要UIコンポーネント（スコアボード、星取表、トーナメントツリー等）における**マルチデバイス解像度・視覚的境界・レイアウト破綻防止**を保証するテスト群を格納しています。

ガバナンス第610条（`scripts/check_gov_610_test_pyramid_golden_ratio.py`）に基づき、**最大10件以下の厳選中核UI**として厳格に管理・保護されています。

---

## 2. なぜ画像バイナリ比較（`matchesGoldenFile`）を行わないのか？
一般的な Flutter の Golden テスト（PNG 画像比較）は、以下の理由により CI 環境や開発者環境間で**激しいフレーキー（不安定化・偽陽性エラー）**を引き起こします：
1. **OS 間のフォントレンダリング差異**（macOS, Linux, Windows でのアンチエイリアスや字形の微小な差）
2. **Flutter エンジンのマイナーバージョン差異**（Skia / Impeller のラスタライズ微差）
3. **高解像度ディスプレイ（Retina / 4K）の論理ピクセル補正差**

KendoOS では、「**ゼロ・フレーキー（Flaky-Free CI）**」と「**超高速なローカル検証**」を最優先するため、**画像バイナリ比較を行わず、論理レンダリング整合性検証を採用**しています：
* `tester.view.physicalSize` と `devicePixelRatio` を特定解像度に固定
* UI ツリーの構築とレイアウト計算（`tester.pump()`）を実行
* **オーバーフロー例外の検知**（`expect(tester.takeException(), isNull)`）
* **必須打突記号・要素配置の完全性**（`expect(find.text(...), findsOneWidget)`）

これにより、画像アセットによるリポジトリ肥大化（Git LFS 不要）を防ぎつつ、画面破綻を 100% 確実に防止しています。

---

## 3. テストピラミッド上の位置づけと追加ルール
* **中核 8〜10 画面**:
  * 本ディレクトリ（`test/golden/`）に配置（`scripts/run_quality_gate.sh` にて常時実行）。
* **その他の詳細画面・ダイアログ・コンポーネント**:
  * `test/widget/**` 配下に配置します。
  * `matchesGoldenFile` を使わないレイアウト検証は、本質的に Widget テスト層に属するため、`test/widget/features/...` 内で保守します。

