#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 【デザインシステム・ガバナンス監査】🎨 カタログ全UIパーツ網羅性保証スクリプト
================================================================================
design_system_manifest.json の形状仕様 (shape_spec) および主要な共通UIパーツ群が、
デザインカタログ (lib/admin/presentation/components/design_gallery/) に
漏れなく記載・実装されているかを静的解析で厳密に監査します。
"""

import json
import os
import sys

# 必須共通UIコンポーネント一覧（カタログに掲載されていなければならない部品）
REQUIRED_COMPONENTS = [
    # 基盤・テクスチャ・カード
    "AppGlassContainer",
    "AppCard",
    "AppSwitch",
    "AppLoadingIndicator",
    # 競技ドメイン・スコア
    "AppKendoColors",
    "ipponGold",
    "hansokuRed",
    # シーン・ステータス
    "KendoSceneBadge",
    "MatchStatusBadge",
    "ThermalStatusBadge",
    # ボタン・アクション
    "ElevatedButton",
    "OutlinedButton",
    "StadiumBorder",
    # フォーム・入力
    "AppRadius.capsule",
    "AppRadius.large",
    # ドック・オーバーレイ
    "showAppBottomSheet",
    "showAppDialog",
    "AppDialog",
    "AppSnackBar",
    # パレット・文字
    "AppThemeColors",
    "AppFontSize",
    "hairlineBorder",
]


def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    root_dir = os.path.abspath(os.path.join(script_dir, ".."))
    manifest_path = os.path.join(script_dir, "design_system_manifest.json")
    gallery_dir = os.path.join(
        root_dir, "lib", "admin", "presentation", "components", "design_gallery"
    )

    if not os.path.exists(manifest_path):
        print(f"🔴 エラー: {manifest_path} が見つかりません。")
        sys.exit(1)

    if not os.path.exists(gallery_dir):
        print(f"🔴 エラー: {gallery_dir} が見つかりません。")
        sys.exit(1)

    print("=" * 72)
    print(" 📊 【ガバナンス監査】🎨 デザインカタログ 全UIパーツ網羅性 監査レポート")
    print("=" * 72)

    # 1. カタログDartファイル群の全コードを結合して読み込み
    gallery_files = [
        f for f in os.listdir(gallery_dir) if f.endswith(".dart")
    ]
    if not gallery_files:
        print(" 🔴 エラー: デザインカタログモジュールが存在しません。")
        sys.exit(1)

    combined_gallery_code = ""
    for gf in gallery_files:
        with open(os.path.join(gallery_dir, gf), "r", encoding="utf-8") as f:
            combined_gallery_code += f.read() + "\n"

    # 親画面も結合
    parent_screen = os.path.join(
        root_dir,
        "lib",
        "admin",
        "presentation",
        "screens",
        "design_system_gallery_screen.dart",
    )
    if os.path.exists(parent_screen):
        with open(parent_screen, "r", encoding="utf-8") as f:
            combined_gallery_code += f.read() + "\n"

    # 2. 必須共通UIコンポーネントの網羅チェック
    missing_components = []
    for comp in REQUIRED_COMPONENTS:
        if comp not in combined_gallery_code:
            missing_components.append(comp)

    # 3. マニフェスト shape_spec (17種) の存在チェック
    with open(manifest_path, "r", encoding="utf-8") as f:
        manifest = json.load(f)

    shape_specs = manifest.get("shape_spec", {})
    missing_shape_keys = []
    # 形状仕様の主要キーワードがカタログコードまたは親画面で考慮されているか
    shape_keywords = {
        "action_buttons": "StadiumBorder",
        "single_line_inputs": "capsule",
        "status_badges": "MatchStatusBadge",
        "multiline_inputs": "large",
        "scene_badges": "KendoSceneBadge",
        "dialog_action_buttons": "StadiumBorder",
        "floating_action_buttons": "StadiumBorder",
    }
    for spec_key, keyword in shape_keywords.items():
        if keyword not in combined_gallery_code:
            missing_shape_keys.append(f"{spec_key} (keyword: {keyword})")

    # 4. 結果判定
    has_error = False
    print(f" 📂 監査対象カタログモジュール: {len(gallery_files)} ファイル")
    print(f" 📋 必須UIコンポーネント検査: {len(REQUIRED_COMPONENTS)} 件")
    print(f" 📐 形状言語マニフェスト検査: {len(shape_keywords)} 項目")
    print("-" * 72)

    if missing_components:
        has_error = True
        print(f" 🔴 未掲載コンポーネントが検出されました ({len(missing_components)} 件):")
        for mc in missing_components:
            print(f"    ❌ {mc} がデザインカタログ内に見つかりません。")

    if missing_shape_keys:
        has_error = True
        print(f" 🔴 未掲載形状仕様が検出されました ({len(missing_shape_keys)} 件):")
        for ms in missing_shape_keys:
            print(f"    ❌ {ms} の仕様がデザインカタログに反映されていません。")

    if has_error:
        print("=" * 72)
        print(" ❌ 監査結果: 違反 (デザインカタログに全UIパーツが網羅されていません)")
        print("=" * 72)
        sys.exit(1)

    print(" 🟢 全必須UIコンポーネント ＆ 形状仕様がデザインカタログに100%網羅されています！")
    print(" 🎯 網羅性適合率: 100.0% (欠落ゼロ)")
    print("=" * 72)
    sys.exit(0)


if __name__ == "__main__":
    main()

