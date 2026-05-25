# Kendo Sync 操作マニュアル (Knowledge Base)

本ディレクトリは、Kendo Syncのすべての運用知識・取扱説明書を統合管理する Single Source of Truth（唯一の情報源）である。

## ディレクトリ構成
- `quickstart/`: 現場で3分で読めるクイックガイド（体育館向け）
- `operator/`: 大会管理者・記録係向けの詳細操作マニュアル
- `viewer/`: 観客・保護者向けの閲覧マニュアル
- `recovery/`: 通信断・トラブル時の緊急復旧マニュアル
- `governance/`: 運用規約・ガバナンスルールの解説
- `images/`: 監査済みのスクリーンショット群（`screenshot_registry.yaml`で管理）

## 構造の凍結宣言 (Structural Freeze)
本ディレクトリ構造、および以下の原則はこの時点で凍結される。

* **1 Screen = 1 Manual 原則**
  - アプリケーション上の1つの画面（Screen）に対して、必ず1つのMarkdownマニュアルファイルが1:1で対応して存在しなければならない。これを破るドキュメント構成は許可されない。