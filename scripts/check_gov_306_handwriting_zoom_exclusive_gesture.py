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

import subprocess
import sys

def main():
    print("=" * 68)
    print(" 📊 【第306条 ガバナンス監査】🖌️ 手書きズーム・InteractiveViewerジェスチャー排他 ＆ Transform座標不変性保証規約")
    print("=" * 68)

    cmd = ["python3", "scripts/gov_test_helper.py",
        "test/governance/drawing_zoom_and_gesture_governance_test.dart",
        "test/unit/quick_memo_transformation_math_test.dart",
        "--reporter=expanded",
    ]

    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    is_ok = (res.returncode == 0)

    rules = [
        ("① [ジェスチャー排他] 1本指描画と2本指ズームの厳格なジェスチャー排他保証規約", is_ok),
        ("② [等倍リセット] 拡大中のズームリセットボタン表示 ＆ タップによる等倍（100%）復帰保証規約", is_ok),
        ("③ [座標不変性] Transform逆変換による基準キャンバス論理サイズ（800x1000）空間座標不変性保証規約", is_ok),
        ("④ [倍率クランプ＆計算精度] ズーム倍率クランプ（1.0x〜4.0x）＆ 幾何学逆行列計算精度保証規約", is_ok),
    ]

    for label, ok in rules:
        status = "🟢 適合 (Passed)" if ok else "🔴 違反 (Failed)"
        print(f" {label}: {status}")

    print("-" * 68)
    if is_ok:
        print(" 🟢 監査結果: 合格 (手書きズーム・InteractiveViewerジェスチャー排他 ＆ Transform座標不変性保証規約に完全適合！)")
        print("=" * 68)
        sys.exit(0)
    else:
        print(" 🔴 監査結果: 違反 (第306条 手書きズーム・InteractiveViewerジェスチャー排他 ＆ Transform座標不変性保証規約に違反があります)")
        print("=" * 68)
        print(res.stdout + res.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
