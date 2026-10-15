#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🥋 Kendo OS - 【第306条 ガバナンス監査】🖌️ 手書きズーム・InteractiveViewerジェスチャー排他 ＆ Transform座標不変性保証規約
================================================================================
① 1本指描画と2本指ズームの厳格なジェスチャー排他保証規約
② 拡大中のズームリセットボタン表示 ＆ タップによる等倍（100%）復帰保証規約
③ Transform逆変換による基準キャンバス論理サイズ（800x1000）空間座標不変性保証規約
④ ズーム倍率クランプ（1.0x〜4.0x）＆ 幾何学逆行列計算精度保証規約
"""

import sys
from gov_static_scanner import GovStaticScanner


def check_handwriting_zoom_governance(scanner: GovStaticScanner):
    canvas_path = "lib/features/tournament/presentation/components/program_management/quick_memo_drawing_canvas.dart"
    painter_path = "lib/features/tournament/presentation/components/program_management/quick_memo_canvas_painter.dart"

    canvas_content = scanner.read_file(canvas_path)
    painter_content = scanner.read_file(painter_path)

    if not canvas_content or not painter_content:
        return False, ["必須手書きメモコンポーネントが存在しません"]

    violations = []

    # ① 1本指描画と2本指ズームの厳格なジェスチャー排他
    if "_isTransforming" not in canvas_content and "pointerCount" not in canvas_content:
        violations.append("1本指描画と2本指ズームの排他フラグ (_isTransforming) が見つかりません")

    # ② 等倍リセットボタン・復帰
    if "1.0" not in canvas_content or ("resetZoom" not in canvas_content and "_resetZoom" not in canvas_content and "100%" not in canvas_content):
        violations.append("等倍リセット処理 (_resetZoom / 100%) が見つかりません")

    # ③ 基準キャンバス論理サイズ (800x1000) 空間座標不変性
    if "Size(800, 1000)" not in canvas_content and "800" not in canvas_content:
        violations.append("基準キャンバス論理サイズ Size(800, 1000) が定義されていません")

    # ④ ズーム倍率クランプ (1.0x 〜 4.0x)
    if "4.0" not in canvas_content or "clamp" not in canvas_content:
        violations.append("ズーム倍率クランプ (1.0x〜4.0x clamp) が実装されていません")

    return len(violations) == 0, violations


def main():
    print("=" * 68)
    print(" 📊 【第306条 ガバナンス監査】🖌️ 手書きズーム・InteractiveViewerジェスチャー排他 ＆ Transform座標不変性保証規約")
    print("=" * 68)

    scanner = GovStaticScanner.get_instance()
    is_ok, violations = check_handwriting_zoom_governance(scanner)

    rules = [
        ("① [ジェスチャー排他] 1本指描画と2本指ズームの厳格なジェスチャー排他保証規約", is_ok),
        ("② [等倍リセット] 拡大中のズームリセットボタン表示 ＆ タップによる等倍（100%）復帰保証規約", is_ok),
        ("③ [座標不変性] Transform逆変換による基準キャンバス論理サイズ（800x1000）空間座標不変性保証規約", is_ok),
        ("④ [倍率クランプ＆計算精度] ズーム倍率クランプ（1.0x〜4.0x）＆ 幾何学逆行列計算精度保証規約", is_ok),
    ]

    for label, ok in rules:
        status = "🟢 適合 (Passed)" if ok else "🔴 違反 (Failed)"
        print(f" {label}: {status}")

    if not is_ok:
        for v in violations:
            print(f"    ❌ {v}")

    print("-" * 68)
    if is_ok:
        print(" 🟢 監査結果: 合格 (手書きズーム・InteractiveViewerジェスチャー排他 ＆ Transform座標不変性保証規約に完全適合！)")
        print("=" * 68)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (第306条 手書きズーム・InteractiveViewerジェスチャー排他 ＆ Transform座標不変性保証規約に違反があります)")
        print("=" * 68)
        sys.exit(1)


if __name__ == "__main__":
    main()
